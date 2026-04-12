// lib/core/secrets/vault_fragment_2.dart

import 'secrets_config.dart';

class VaultFragment2 {
  static List<int> get _patternCore => SecretsConfig.shufflePatternCore;
  static List<int> get _patternMask => SecretsConfig.shufflePatternMask;

  static List<int> getShuffleSeeds() {
    return List.generate(
      _patternCore.length,
      (i) => (_patternCore[i] + _patternMask[i]) & 0xFF,
    );
  }

  static int get shiftBase => SecretsConfig.shiftBase;
}