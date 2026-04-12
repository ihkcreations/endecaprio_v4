// lib/core/secrets/secrets_config.template.dart
class SecretsConfig {
  static const String pinSalt = 'REPLACE_WITH_RANDOM_STRING';
  static const String recoverySalt = 'REPLACE_WITH_RANDOM_STRING';

  // Generate your own random bytes for all arrays below
  // Use: List.generate(16, (_) => Random.secure().nextInt(256))
  
  static const List<int> vaultSeedA = [];
  static const List<int> vaultSeedB = [];
  static const List<int> shufflePatternCore = [];
  static const List<int> shufflePatternMask = [];
  static const int shiftBase = 0x00;
  static const List<int> watermarkBytes = [];
  static const List<int> poisonSeedA = [];
  static const List<int> poisonSeedB = [];
  static const List<int> signaturePartA = [];
  static const List<int> signaturePartB = [];
  static const int versionByte = 0x04;
  static const List<int> signatureKeyPart = [];
  static const String alphabetPart1 = '';
  static const String alphabetPart2 = '';
  static const String alphabetPart3 = '';
  static const String alphabetPart4 = '';
  static const String paddingChar = '';
  static const String delimiter = '';
  static const List<int> saltSuffixPass1 = [];
  static const List<int> saltSuffixPass2 = [];
  static const List<int> saltSuffixPass3 = [];
}