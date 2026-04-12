// lib/core/secrets/vault_fragment_4.dart

import 'secrets_config.dart';

class VaultFragment4 {
  static List<int> getSignatureMarker() {
    return [...SecretsConfig.signaturePartA, ...SecretsConfig.signaturePartB];
  }

  static List<int> get sigKeyPart => SecretsConfig.signatureKeyPart;
  static int get versionByte => SecretsConfig.versionByte;
}