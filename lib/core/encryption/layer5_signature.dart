// lib/core/encryption/layer5_signature.dart

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../secrets/vault_assembler.dart';

/// Layer 5: App Signature Embedding
/// Prepends a signature block to the encrypted data that
/// identifies it as EnDecaprioV4 encrypted content
///
/// Format:
/// [1-byte version][16-byte encrypted signature][4-byte data checksum][...data...]

class Layer5Signature {
  static const int _signatureBlockSize = 21; // 1 + 16 + 4

  /// Embed signature before the encrypted data
  static Future<Uint8List> embed(Uint8List data) async {
    final vault = VaultAssembler.instance;

    // Version byte
    final version = vault.versionByte;

    // Create signature: encrypt the marker with signature key
    final signatureMarker = vault.signatureMarker;
    final sigKey = vault.signatureKey;

    // Simple XOR encryption for signature (fast, deterministic)
    final encryptedSig = _xorEncrypt(
      Uint8List.fromList(signatureMarker),
      Uint8List.fromList(sigKey),
    );

    // Pad or trim signature to exactly 16 bytes
    final sigBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      sigBytes[i] = i < encryptedSig.length ? encryptedSig[i] : 0x00;
    }

    // Calculate checksum of the data
    final checksum = _calculateChecksum(data);

    // Build result: [version][signature][checksum][data]
    final result = Uint8List(1 + 16 + 4 + data.length);
    result[0] = version;
    result.setRange(1, 17, sigBytes);
    result[17] = (checksum >> 24) & 0xFF;
    result[18] = (checksum >> 16) & 0xFF;
    result[19] = (checksum >> 8) & 0xFF;
    result[20] = checksum & 0xFF;
    result.setRange(21, 21 + data.length, data);

    return result;
  }

  /// Verify and extract data from signed content
  /// Returns null if signature is invalid
  static Future<Uint8List?> extract(Uint8List signedData) async {
    if (signedData.length < _signatureBlockSize + 1) {
      return null; // Too short to contain signature + any data
    }

    final vault = VaultAssembler.instance;

    // Extract version
    final version = signedData[0];
    if (version != vault.versionByte) {
      return null; // Wrong version
    }

    // Extract and verify signature
    final encryptedSig = signedData.sublist(1, 17);
    final sigKey = vault.signatureKey;
    final decryptedSig = _xorEncrypt(
      Uint8List.fromList(encryptedSig),
      Uint8List.fromList(sigKey),
    );

    // Verify marker
    final expectedMarker = vault.signatureMarker;
    bool sigValid = true;
    for (int i = 0; i < expectedMarker.length && i < decryptedSig.length; i++) {
      if (decryptedSig[i] != expectedMarker[i]) {
        sigValid = false;
        break;
      }
    }

    if (!sigValid) {
      return null; // Invalid signature - not EnDecaprioV4 data
    }

    // Extract checksum
    final storedChecksum = (signedData[17] << 24) |
        (signedData[18] << 16) |
        (signedData[19] << 8) |
        signedData[20];

    // Extract data
    final data = signedData.sublist(_signatureBlockSize);

    // Verify checksum
    final calculatedChecksum = _calculateChecksum(data);
    if (storedChecksum != calculatedChecksum) {
      return null; // Data corrupted
    }

    return Uint8List.fromList(data);
  }

  /// Check if data has a valid EnDecaprioV4 signature (quick check)
  static bool hasValidSignature(Uint8List data) {
    if (data.length < _signatureBlockSize) return false;

    final vault = VaultAssembler.instance;
    return data[0] == vault.versionByte;
  }

  /// Simple XOR encryption for the signature
  static Uint8List _xorEncrypt(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  /// Calculate CRC32-like checksum
  static int _calculateChecksum(Uint8List data) {
    int checksum = 0xFFFFFFFF;
    for (int i = 0; i < data.length; i++) {
      checksum ^= data[i];
      for (int j = 0; j < 8; j++) {
        if (checksum & 1 == 1) {
          checksum = (checksum >> 1) ^ 0xEDB88320;
        } else {
          checksum >>= 1;
        }
      }
    }
    return checksum ^ 0xFFFFFFFF;
  }
}