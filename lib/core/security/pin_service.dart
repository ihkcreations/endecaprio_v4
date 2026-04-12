// lib/core/security/pin_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../constants/app_constants.dart';
import 'secure_storage_service.dart';
import '../secrets/secrets_config.dart';

class PinService {
  static PinService? _instance;
  final SecureStorageService _storage;

  PinService._() : _storage = SecureStorageService.instance;

  static PinService get instance {
    _instance ??= PinService._();
    return _instance!;
  }

  // ─── PIN Operations ─────────────────────────────

  /// Hash a PIN using SHA-256 with salt
  Future<String> _hashPin(String pin) async {
    final salted = '${SecretsConfig.pinSalt}_${pin}_PIN';
    final algorithm = Sha256();
    final hash = await algorithm.hash(utf8.encode(salted));
    return base64Encode(hash.bytes);
  }

  /// Set a new PIN
  Future<void> setPin(String pin) async {
    if (pin.length != AppConstants.pinLength) {
      throw PinException('PIN must be ${AppConstants.pinLength} digits');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw PinException('PIN must contain only digits');
    }

    final hash = await _hashPin(pin);
    await _storage.savePinHash(hash);
    await _storage.setPinEnabled(true);
    await _storage.setPinAttempts(0);
    await _storage.setLockoutUntil(null);
  }

  /// Verify a PIN
  Future<PinVerifyResult> verifyPin(String pin) async {
    // Check lockout first
    final lockoutUntil = await _storage.getLockoutUntil();
    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      return PinVerifyResult(
        success: false,
        isLockedOut: true,
        lockoutRemainingSeconds: remaining,
      );
    }

    final storedHash = await _storage.getPinHash();
    if (storedHash == null) {
      return PinVerifyResult(success: false, error: 'No PIN set');
    }

    final inputHash = await _hashPin(pin);
    final isCorrect = inputHash == storedHash;

    if (isCorrect) {
      await _storage.setPinAttempts(0);
      await _storage.setLockoutUntil(null);
      return PinVerifyResult(success: true);
    } else {
      int attempts = await _storage.getPinAttempts();
      attempts++;
      await _storage.setPinAttempts(attempts);

      if (attempts >= AppConstants.maxPinAttempts) {
        final lockout = DateTime.now().add(
          const Duration(seconds: AppConstants.lockoutDurationSeconds),
        );
        await _storage.setLockoutUntil(lockout);
        await _storage.setPinAttempts(0);
        return PinVerifyResult(
          success: false,
          isLockedOut: true,
          lockoutRemainingSeconds: AppConstants.lockoutDurationSeconds,
        );
      }

      return PinVerifyResult(
        success: false,
        attemptsRemaining: AppConstants.maxPinAttempts - attempts,
      );
    }
  }

  /// Change PIN (requires old PIN verification first)
  Future<bool> changePin(String oldPin, String newPin) async {
    final verifyResult = await verifyPin(oldPin);
    if (!verifyResult.success) return false;

    await setPin(newPin);
    return true;
  }

  /// Remove PIN but keep recovery hash intact
  /// Recovery hash is only cleared on full app reset
  Future<void> removePin() async {
    await _storage.setPinEnabled(false);
    await _storage.delete(AppConstants.keyPinHash);
    await _storage.setPinAttempts(0);
    await _storage.setLockoutUntil(null);
  }

  /// Check if PIN is enabled
  Future<bool> isPinEnabled() async {
    return await _storage.isPinEnabled();
  }

  /// Check if currently locked out
  Future<bool> isLockedOut() async {
    final lockoutUntil = await _storage.getLockoutUntil();
    if (lockoutUntil == null) return false;
    if (DateTime.now().isAfter(lockoutUntil)) {
      await _storage.setLockoutUntil(null);
      return false;
    }
    return true;
  }

  /// Get remaining lockout seconds
  Future<int> getLockoutRemaining() async {
    final lockoutUntil = await _storage.getLockoutUntil();
    if (lockoutUntil == null) return 0;
    final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

class PinVerifyResult {
  final bool success;
  final bool isLockedOut;
  final int lockoutRemainingSeconds;
  final int attemptsRemaining;
  final String? error;

  PinVerifyResult({
    required this.success,
    this.isLockedOut = false,
    this.lockoutRemainingSeconds = 0,
    this.attemptsRemaining = 3,
    this.error,
  });
}

class PinException implements Exception {
  final String message;
  PinException(this.message);

  @override
  String toString() => message;
}