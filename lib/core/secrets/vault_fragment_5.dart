// lib/core/secrets/vault_fragment_5.dart

import 'secrets_config.dart';

class VaultFragment5 {
  static String getFullAlphabet() {
    return SecretsConfig.alphabetPart1 +
        SecretsConfig.alphabetPart2 +
        SecretsConfig.alphabetPart3 +
        SecretsConfig.alphabetPart4;
  }

  static String get paddingChar => SecretsConfig.paddingChar;
  static String get delimiter => SecretsConfig.delimiter;

  static List<int> get saltSuffixPass1 => SecretsConfig.saltSuffixPass1;
  static List<int> get saltSuffixPass2 => SecretsConfig.saltSuffixPass2;
  static List<int> get saltSuffixPass3 => SecretsConfig.saltSuffixPass3;
}