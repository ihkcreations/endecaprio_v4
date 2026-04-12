// lib/core/encryption/endecaprio_engine.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'key_derivation.dart';
import 'layer1_preprocessor.dart';
import 'layer2_multi_pass.dart';
import 'layer3_shuffler.dart';
import 'layer4_poison.dart';
import 'layer5_signature.dart';
import 'layer6_encoding.dart';
import '../secrets/vault_assembler.dart';

/// The EnDecaprio Encryption Engine
/// Orchestrates all 6 layers of the proprietary pipeline
///
/// ENCRYPTION FLOW:
/// Raw Text → Pre-Process → Multi-Pass Encrypt → Shuffle → Poison → Sign → Encode
///
/// DECRYPTION FLOW:
/// Encoded Text → Decode → Verify Signature → Remove Poison → Unshuffle → Multi-Pass Decrypt → Reverse Pre-Process

class EnDecaprioEngine {
  static final EnDecaprioEngine _instance = EnDecaprioEngine._();
  factory EnDecaprioEngine() => _instance;
  EnDecaprioEngine._();

  /// Encrypt raw text using the full 6-layer pipeline
  ///
  /// Returns the encrypted string in EnDecaprio custom encoding
  /// Throws [EncryptionException] if any layer fails
  Future<EncryptionResult> encrypt(String rawText, String securityKey) async {
    try {
      if (rawText.isEmpty) {
        throw EncryptionException('Text cannot be empty');
      }
      if (securityKey.isEmpty) {
        throw EncryptionException('Security key cannot be empty');
      }
      if (securityKey.length < 3) {
        throw EncryptionException('Security key must be at least 3 characters');
      }

      final stopwatch = Stopwatch()..start();

      // Get key bytes for layers that need them directly
      final keyBytes = utf8.encode(securityKey);
      final derivedKey = await KeyDerivation.deriveKey(securityKey);
      final derivedKeyBytes = await KeyDerivation.getKeyBytes(derivedKey);

      // ═══════════════════════════════════════════
      // LAYER 1: Text Pre-Processing
      // ═══════════════════════════════════════════
      final preprocessed = Layer1Preprocessor.process(rawText, derivedKeyBytes);

      // ═══════════════════════════════════════════
      // LAYER 2: Multi-Pass Encryption
      // AES-256-GCM → ChaCha20-Poly1305 → AES-256-GCM
      // ═══════════════════════════════════════════
      final textBytes = Uint8List.fromList(utf8.encode(preprocessed));
      final encrypted = await Layer2MultiPass.encrypt(textBytes, securityKey);

      // ═══════════════════════════════════════════
      // LAYER 3: Byte Shuffling
      // ═══════════════════════════════════════════
      final shuffled = Layer3Shuffler.shuffle(encrypted, derivedKeyBytes);

      // ═══════════════════════════════════════════
      // LAYER 4: Poison Byte Injection
      // ═══════════════════════════════════════════
      final poisoned = Layer4Poison.inject(shuffled, derivedKeyBytes);

      // ═══════════════════════════════════════════
      // LAYER 5: App Signature Embedding
      // ═══════════════════════════════════════════
      final signed = await Layer5Signature.embed(poisoned);

      // ═══════════════════════════════════════════
      // LAYER 6: Custom Encoding
      // ═══════════════════════════════════════════
      final encoded = Layer6Encoding.encode(signed);

      stopwatch.stop();

      return EncryptionResult(
        success: true,
        output: encoded,
        processingTime: stopwatch.elapsed,
        originalLength: rawText.length,
        encryptedLength: encoded.length,
      );
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Encryption failed: ${e.toString()}');
    }
  }

  /// Decrypt EnDecaprio encoded text using the full 6-layer pipeline (reversed)
  ///
  /// Returns the original plain text
  /// Throws [DecryptionException] if any layer fails
  Future<DecryptionResult> decrypt(String encodedText, String securityKey) async {
    try {
      if (encodedText.isEmpty) {
        throw DecryptionException('Encrypted text cannot be empty');
      }
      if (securityKey.isEmpty) {
        throw DecryptionException('Security key cannot be empty');
      }

      final stopwatch = Stopwatch()..start();

      // Get key bytes
      final derivedKey = await KeyDerivation.deriveKey(securityKey);
      final derivedKeyBytes = await KeyDerivation.getKeyBytes(derivedKey);

      // ═══════════════════════════════════════════
      // LAYER 6 REVERSE: Custom Decoding
      // ═══════════════════════════════════════════
      final decoded = Layer6Encoding.decode(encodedText);

      if (decoded.isEmpty) {
        throw DecryptionException('Invalid encoded text');
      }

      // ═══════════════════════════════════════════
      // LAYER 5 REVERSE: Verify & Extract Signature
      // ═══════════════════════════════════════════
      final extractedData = await Layer5Signature.extract(decoded);

      if (extractedData == null) {
        throw DecryptionException(
          'Invalid EnDecaprioV4 data. This text was not encrypted with this app '
          'or has been tampered with.',
        );
      }

      // ═══════════════════════════════════════════
      // LAYER 4 REVERSE: Remove Poison Bytes
      // ═══════════════════════════════════════════
      final unpoisoned = Layer4Poison.remove(extractedData, derivedKeyBytes);

      // ═══════════════════════════════════════════
      // LAYER 3 REVERSE: Unshuffle Bytes
      // ═══════════════════════════════════════════
      final unshuffled = Layer3Shuffler.unshuffle(unpoisoned, derivedKeyBytes);

      // ═══════════════════════════════════════════
      // LAYER 2 REVERSE: Multi-Pass Decryption
      // ═══════════════════════════════════════════
      final decryptedBytes = await Layer2MultiPass.decrypt(unshuffled, securityKey);

      // ═══════════════════════════════════════════
      // LAYER 1 REVERSE: Reverse Pre-Processing
      // ═══════════════════════════════════════════
      final preprocessedText = utf8.decode(decryptedBytes);
      final originalText = Layer1Preprocessor.reverseProcess(preprocessedText, derivedKeyBytes);

      stopwatch.stop();

      return DecryptionResult(
        success: true,
        output: originalText,
        processingTime: stopwatch.elapsed,
      );
    } on DecryptionException {
      rethrow;
    } catch (e) {
      throw DecryptionException(
        'Decryption failed. Wrong security key or corrupted data.',
      );
    }
  }

  /// Quick validation: check if a string looks like EnDecaprio encoded text
  bool isEnDecaprioEncoded(String text) {
    if (text.isEmpty) return false;

    // Check if it uses our custom alphabet
    if (!Layer6Encoding.isValidEncoded(text)) return false;

    // Try to decode and check signature
    try {
      final decoded = Layer6Encoding.decode(text);
      return Layer5Signature.hasValidSignature(decoded);
    } catch (_) {
      return false;
    }
  }

  /// Get pipeline version info
  String get pipelineVersion => 'EnDecaprio Pipeline v${VaultAssembler.instance.versionByte}';
}

/// Result of encryption operation
class EncryptionResult {
  final bool success;
  final String output;
  final Duration processingTime;
  final int originalLength;
  final int encryptedLength;
  final String? error;

  EncryptionResult({
    required this.success,
    this.output = '',
    this.processingTime = Duration.zero,
    this.originalLength = 0,
    this.encryptedLength = 0,
    this.error,
  });

  double get expansionRatio =>
      originalLength > 0 ? encryptedLength / originalLength : 0;

  String get processingTimeFormatted =>
      '${processingTime.inMilliseconds}ms';
}

/// Result of decryption operation
class DecryptionResult {
  final bool success;
  final String output;
  final Duration processingTime;
  final String? error;

  DecryptionResult({
    required this.success,
    this.output = '',
    this.processingTime = Duration.zero,
    this.error,
  });

  String get processingTimeFormatted =>
      '${processingTime.inMilliseconds}ms';
}

/// Custom exceptions
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => message;
}

class DecryptionException implements Exception {
  final String message;
  DecryptionException(this.message);

  @override
  String toString() => message;
}