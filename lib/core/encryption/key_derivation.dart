// lib/core/encryption/key_derivation.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../secrets/vault_assembler.dart';

class KeyDerivation {
  /// Derives a 256-bit key from user's passphrase using PBKDF2
  /// (Using PBKDF2 as it's well-supported; Argon2 via separate implementation)
  /// Combined with app's internal master seed for uniqueness
  static Future<SecretKey> deriveKey(String passphrase) async {
    final vault = VaultAssembler.instance;

    // Combine passphrase with master seed to make it app-specific
    final passphraseBytes = utf8.encode(passphrase);
    final combined = Uint8List.fromList([
      ...passphraseBytes,
      ...vault.masterSeed,
    ]);

    // Use PBKDF2 with HMAC-SHA256
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    // Salt derived from passphrase + app secret (deterministic)
    final saltInput = [...vault.masterSeed, ...passphraseBytes];
    final saltHash = await Sha256().hash(saltInput);
    final salt = saltHash.bytes.sublist(0, 16);

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(combined),
      nonce: salt,
    );

    return secretKey;
  }

  /// Derives variant keys for multi-pass encryption
  /// Each pass gets a different key derived from the same passphrase
  static Future<SecretKey> derivePassKey(String passphrase, int passNumber) async {
    final vault = VaultAssembler.instance;

    final passphraseBytes = utf8.encode(passphrase);
    final passSalt = vault.getSaltForPass(passNumber);

    final combined = Uint8List.fromList([
      ...passphraseBytes,
      ...passSalt,
      ...vault.masterSeed,
      passNumber, // include pass number in derivation
    ]);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 80000 + (passNumber * 10000), // Different iterations per pass
      bits: 256,
    );

    // Unique salt per pass
    final saltInput = [...passSalt, ...passphraseBytes, passNumber];
    final saltHash = await Sha256().hash(saltInput);
    final salt = saltHash.bytes.sublist(0, 16);

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(combined),
      nonce: salt,
    );

    return secretKey;
  }

  /// Get raw key bytes from SecretKey
  static Future<List<int>> getKeyBytes(SecretKey key) async {
    return await key.extractBytes();
  }
}