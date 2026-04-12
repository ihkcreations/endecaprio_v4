// lib/features/onboarding/providers/onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/security/recovery_service.dart';
import '../../../core/security/secure_storage_service.dart';

// ─── PIN State ────────────────────────────────────

class PinState {
  final bool isPinEnabled;
  final bool isLoading;
  final bool isVerified;
  final bool isLockedOut;
  final int lockoutSeconds;
  final int attemptsRemaining;
  final String? error;

  const PinState({
    this.isPinEnabled = false,
    this.isLoading = true,
    this.isVerified = false,
    this.isLockedOut = false,
    this.lockoutSeconds = 0,
    this.attemptsRemaining = 3,
    this.error,
  });

  PinState copyWith({
    bool? isPinEnabled,
    bool? isLoading,
    bool? isVerified,
    bool? isLockedOut,
    int? lockoutSeconds,
    int? attemptsRemaining,
    String? error,
    bool clearError = false,
  }) {
    return PinState(
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      lockoutSeconds: lockoutSeconds ?? this.lockoutSeconds,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PinNotifier extends StateNotifier<PinState> {
  final PinService _pinService;
  final RecoveryService _recoveryService;
  final SecureStorageService _storageService;

  PinNotifier(this._pinService, this._recoveryService, this._storageService)
      : super(const PinState()) {
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final isEnabled = await _pinService.isPinEnabled();
    final isLockedOut = await _pinService.isLockedOut();
    int lockoutRemaining = 0;
    if (isLockedOut) {
      lockoutRemaining = await _pinService.getLockoutRemaining();
    }

    state = state.copyWith(
      isPinEnabled: isEnabled,
      isLoading: false,
      isLockedOut: isLockedOut,
      lockoutSeconds: lockoutRemaining,
    );
  }

  /// Set a new PIN during onboarding
  Future<bool> setupPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _pinService.setPin(pin);
      state = state.copyWith(
        isPinEnabled: true,
        isLoading: false,
      );
      return true;
    } on PinException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Generate and save recovery words
  Future<List<String>> generateRecoveryKey() async {
    final words = _recoveryService.generateRecoveryWords();
    await _recoveryService.saveRecoveryKey(words);
    return words;
  }

  /// Verify PIN for table access
  Future<bool> verifyPin(String pin) async {
    state = state.copyWith(clearError: true);

    final result = await _pinService.verifyPin(pin);

    if (result.success) {
      state = state.copyWith(
        isVerified: true,
        isLockedOut: false,
        attemptsRemaining: 3,
      );
      return true;
    }

    if (result.isLockedOut) {
      state = state.copyWith(
        isLockedOut: true,
        lockoutSeconds: result.lockoutRemainingSeconds,
        error: 'Too many attempts. Try again in ${result.lockoutRemainingSeconds}s',
      );
    } else {
      state = state.copyWith(
        attemptsRemaining: result.attemptsRemaining,
        error: 'Wrong PIN. ${result.attemptsRemaining} attempts remaining',
      );
    }

    return false;
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final success = await _pinService.changePin(oldPin, newPin);
      state = state.copyWith(isLoading: false);
      if (!success) {
        state = state.copyWith(error: 'Current PIN is incorrect');
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Toggle PIN on/off
  Future<void> togglePin(bool enable, {String? pin}) async {
    if (enable && pin != null) {
      await setupPin(pin);
      // Recovery key MUST be generated after this
      // The caller is responsible for calling generateRecoveryKey()
    } else if (!enable) {
      await _pinService.removePin();
      state = state.copyWith(
        isPinEnabled: false,
        isVerified: false,
      );
    }
  }

  /// Verify recovery words and reset PIN
  Future<bool> recoverWithWords(List<String> words) async {
    final isValid = await _recoveryService.verifyRecoveryWords(words);
    if (isValid) {
      // Reset lockout
      await _storageService.setPinAttempts(0);
      await _storageService.setLockoutUntil(null);
      state = state.copyWith(
        isLockedOut: false,
        lockoutSeconds: 0,
        attemptsRemaining: 3,
        clearError: true,
      );
    }
    return isValid;
  }

  /// Remove PIN after recovery
  Future<void> removePinAfterRecovery() async {
    await _pinService.removePin();
    state = state.copyWith(
      isPinEnabled: false,
      isVerified: false,
      isLockedOut: false,
    );
  }

  /// Reset verification state (when leaving a table)
  void resetVerification() {
    state = state.copyWith(isVerified: false);
  }

  /// Update lockout timer
  void updateLockoutTimer(int seconds) {
    if (seconds <= 0) {
      state = state.copyWith(isLockedOut: false, lockoutSeconds: 0, clearError: true);
    } else {
      state = state.copyWith(lockoutSeconds: seconds);
    }
  }

  /// Refresh status
  Future<void> refresh() async {
    await _loadPinStatus();
  }
}

// ─── Providers ────────────────────────────────────

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService.instance;
});

final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  return RecoveryService.instance;
});

final pinProvider = StateNotifierProvider<PinNotifier, PinState>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  final recoveryService = ref.watch(recoveryServiceProvider);
  final storageService = SecureStorageService.instance;
  return PinNotifier(pinService, recoveryService, storageService);
});