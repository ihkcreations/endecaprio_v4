// lib/core/secrets/vault_fragment_3.dart

import 'secrets_config.dart';

class VaultFragment3 {
  static List<int> get _poisonSeedA => SecretsConfig.poisonSeedA;
  static List<int> get _poisonSeedB => SecretsConfig.poisonSeedB;

  static List<int> getPoisonSeeds() {
    return List.generate(
      _poisonSeedA.length,
      (i) => (_poisonSeedA[i] ^ _poisonSeedB[i]) & 0xFF,
    );
  }

  static int generatePoisonByte(int position, int keyByte) {
    return ((position * 7 + keyByte * 13 + 0xAB) ^ 0x5C) & 0xFF;
  }
}