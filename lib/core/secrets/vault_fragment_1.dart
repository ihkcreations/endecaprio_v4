// lib/core/secrets/vault_fragment_1.dart

import 'secrets_config.dart';

class VaultFragment1 {
  static List<int> get _seedA => SecretsConfig.vaultSeedA;
  static List<int> get _seedB => SecretsConfig.vaultSeedB;

  static List<int> getPart() {
    return List.generate(_seedA.length, (i) => _seedA[i] ^ _seedB[i]);
  }

  static List<int> get watermarkPartA => SecretsConfig.watermarkBytes;
}