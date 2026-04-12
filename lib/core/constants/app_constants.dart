// lib/core/constants/app_constants.dart

class AppConstants {
  static const String appName = 'EnDecaprioV4';
  static const String appVersion = '4.0.0';
  static const String appTagline = 'Your texts. Your encryption. Your rules.';

  // Database
  static const String dbName = 'endecaprio_v4.db';
  static const int dbVersion = 1;

  // Secure Storage Keys
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyPinHash = 'pin_hash';
  static const String keyRecoveryHash = 'recovery_key_hash';
  static const String keyRecoveryWords = 'recovery_words_encrypted';
  static const String keyPinAttempts = 'pin_attempts';
  static const String keyLockoutUntil = 'lockout_until';
  static const String keyDbEncryptionKey = 'db_encryption_key';
  static const String keyOnboardingComplete = 'onboarding_complete';

  // PIN
  static const int pinLength = 5;
  static const int maxPinAttempts = 3;
  static const int lockoutDurationSeconds = 30;

  // Encryption Pipeline
  static const String pipelineVersion = 'EDCV4';
  static const int signatureLength = 16;

  // UI
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Default table
  static const String defaultTableName = 'Default';
}