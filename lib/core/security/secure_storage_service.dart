// lib/core/security/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import '../constants/app_constants.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  final FlutterSecureStorage _storage;

  SecureStorageService._()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  // ─── Generic Operations ─────────────────────────

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ─── DB Encryption Key ──────────────────────────

  Future<String> getOrCreateDbKey() async {
    String? dbKey = await read(AppConstants.keyDbEncryptionKey);
    if (dbKey == null) {
      dbKey = _generateRandomKey(32);
      await write(AppConstants.keyDbEncryptionKey, dbKey);
    }
    return dbKey;
  }

  // ─── Onboarding ─────────────────────────────────

  Future<bool> isOnboardingComplete() async {
    final value = await read(AppConstants.keyOnboardingComplete);
    return value == 'true';
  }

  Future<void> setOnboardingComplete() async {
    await write(AppConstants.keyOnboardingComplete, 'true');
  }

  // ─── PIN Management ─────────────────────────────

  Future<bool> isPinEnabled() async {
    final value = await read(AppConstants.keyPinEnabled);
    return value == 'true';
  }

  Future<void> setPinEnabled(bool enabled) async {
    await write(AppConstants.keyPinEnabled, enabled.toString());
  }

  Future<void> savePinHash(String hash) async {
    await write(AppConstants.keyPinHash, hash);
  }

  Future<String?> getPinHash() async {
    return await read(AppConstants.keyPinHash);
  }

  Future<void> saveRecoveryHash(String hash) async {
    await write(AppConstants.keyRecoveryHash, hash);
  }

  Future<String?> getRecoveryHash() async {
    return await read(AppConstants.keyRecoveryHash);
  }

  // ─── PIN Attempts ───────────────────────────────

  Future<int> getPinAttempts() async {
    final value = await read(AppConstants.keyPinAttempts);
    return int.tryParse(value ?? '0') ?? 0;
  }

  Future<void> setPinAttempts(int attempts) async {
    await write(AppConstants.keyPinAttempts, attempts.toString());
  }

  Future<DateTime?> getLockoutUntil() async {
    final value = await read(AppConstants.keyLockoutUntil);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLockoutUntil(DateTime? time) async {
    if (time == null) {
      await delete(AppConstants.keyLockoutUntil);
    } else {
      await write(AppConstants.keyLockoutUntil, time.toIso8601String());
    }
  }


  // ─── Helpers ────────────────────────────────────

  String _generateRandomKey(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}