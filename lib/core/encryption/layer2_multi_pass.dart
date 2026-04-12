// lib/core/encryption/layer2_multi_pass.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'key_derivation.dart';

class Layer2MultiPass {
  /// Triple encryption: AES-256-GCM → ChaCha20-Poly1305 → AES-256-GCM
  /// Each pass uses a different derived key

  static Future<Uint8List> encrypt(Uint8List plainData, String passphrase) async {
    // Pass 1: AES-256-GCM
    final key1 = await KeyDerivation.derivePassKey(passphrase, 1);
    Uint8List current = await _aesEncrypt(plainData, key1);

    // Pass 2: ChaCha20-Poly1305
    final key2 = await KeyDerivation.derivePassKey(passphrase, 2);
    current = await _chachaEncrypt(current, key2);

    // Pass 3: AES-256-GCM (again with different key)
    final key3 = await KeyDerivation.derivePassKey(passphrase, 3);
    current = await _aesEncrypt(current, key3);

    return current;
  }

  /// Triple decryption: reverse order
  /// AES-256-GCM → ChaCha20-Poly1305 → AES-256-GCM
  static Future<Uint8List> decrypt(Uint8List encryptedData, String passphrase) async {
    // Pass 3 reverse: AES-256-GCM decrypt
    final key3 = await KeyDerivation.derivePassKey(passphrase, 3);
    Uint8List current = await _aesDecrypt(encryptedData, key3);

    // Pass 2 reverse: ChaCha20-Poly1305 decrypt
    final key2 = await KeyDerivation.derivePassKey(passphrase, 2);
    current = await _chachaDecrypt(current, key2);

    // Pass 1 reverse: AES-256-GCM decrypt
    final key1 = await KeyDerivation.derivePassKey(passphrase, 1);
    current = await _aesDecrypt(current, key1);

    return current;
  }

  /// AES-256-GCM encryption
  /// Output format: [12-byte nonce][ciphertext + 16-byte auth tag]
  static Future<Uint8List> _aesEncrypt(Uint8List data, SecretKey key) async {
    final algorithm = AesGcm.with256bits();

    final secretBox = await algorithm.encrypt(
      data,
      secretKey: key,
    );

    // Combine: nonce + ciphertext + mac
    final result = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return result;
  }

  /// AES-256-GCM decryption
  static Future<Uint8List> _aesDecrypt(Uint8List data, SecretKey key) async {
    final algorithm = AesGcm.with256bits();

    // Extract components
    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(12, data.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(decrypted);
  }

  /// ChaCha20-Poly1305 encryption
  /// Output format: [12-byte nonce][ciphertext + 16-byte auth tag]
  static Future<Uint8List> _chachaEncrypt(Uint8List data, SecretKey key) async {
    final algorithm = Chacha20.poly1305Aead();

    final secretBox = await algorithm.encrypt(
      data,
      secretKey: key,
    );

    final result = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return result;
  }

  /// ChaCha20-Poly1305 decryption
  static Future<Uint8List> _chachaDecrypt(Uint8List data, SecretKey key) async {
    final algorithm = Chacha20.poly1305Aead();

    final nonce = data.sublist(0, 12);
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(12, data.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decrypted = await algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(decrypted);
  }
}