// lib/core/secrets/vault_assembler.dart

// Assembles all vault fragments at runtime
// This is the ONLY file that knows how to combine everything

import 'dart:typed_data';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'vault_fragment_1.dart';
import 'vault_fragment_2.dart';
import 'vault_fragment_3.dart';
import 'vault_fragment_4.dart';
import 'vault_fragment_5.dart';

class VaultAssembler {
  static VaultAssembler? _instance;
  
  // Cached assembled values
  List<int>? _masterSeed;
  List<int>? _shuffleSeeds;
  List<int>? _poisonSeeds;
  List<int>? _signatureMarker;
  List<int>? _signatureKey;
  String? _customAlphabet;
  List<int>? _watermarkChars;

  VaultAssembler._();

  static VaultAssembler get instance {
    _instance ??= VaultAssembler._();
    return _instance!;
  }

  /// Master seed derived from combining fragment 1 + fragment 2
  List<int> get masterSeed {
    _masterSeed ??= _buildMasterSeed();
    return _masterSeed!;
  }

  List<int> _buildMasterSeed() {
    final part1 = VaultFragment1.getPart();
    final part2 = VaultFragment2.getShuffleSeeds();
    final combined = <int>[];
    for (int i = 0; i < part1.length; i++) {
      combined.add((part1[i] ^ part2[i % part2.length]) & 0xFF);
    }
    return combined;
  }

  /// Shuffle pattern seeds
  List<int> get shuffleSeeds {
    _shuffleSeeds ??= VaultFragment2.getShuffleSeeds();
    return _shuffleSeeds!;
  }

  /// Poison byte seeds
  List<int> get poisonSeeds {
    _poisonSeeds ??= VaultFragment3.getPoisonSeeds();
    return _poisonSeeds!;
  }

  /// App signature marker bytes
  List<int> get signatureMarker {
    _signatureMarker ??= VaultFragment4.getSignatureMarker();
    return _signatureMarker!;
  }

  /// Signature encryption key
  List<int> get signatureKey {
    if (_signatureKey == null) {
      final sigPart = VaultFragment4.sigKeyPart;
      final masterPart = masterSeed;
      _signatureKey = List.generate(
        sigPart.length,
        (i) => (sigPart[i] ^ masterPart[i % masterPart.length]) & 0xFF,
      );
    }
    return _signatureKey!;
  }

  /// Custom encoding alphabet
  String get customAlphabet {
    _customAlphabet ??= VaultFragment5.getFullAlphabet();
    return _customAlphabet!;
  }

  /// Padding character for custom encoding
  String get paddingChar => VaultFragment5.paddingChar;

  /// Delimiter
  String get delimiter => VaultFragment5.delimiter;

  /// Watermark characters
  List<int> get watermarkChars {
    _watermarkChars ??= VaultFragment1.watermarkPartA;
    return _watermarkChars!;
  }

  /// Caesar shift base value
  int get caesarShiftBase => VaultFragment2.shiftBase;

  /// Version byte
  int get versionByte => VaultFragment4.versionByte;

  /// Get salt suffix for each encryption pass
  List<int> getSaltForPass(int passNumber) {
    switch (passNumber) {
      case 1:
        return VaultFragment5.saltSuffixPass1;
      case 2:
        return VaultFragment5.saltSuffixPass2;
      case 3:
        return VaultFragment5.saltSuffixPass3;
      default:
        return VaultFragment5.saltSuffixPass1;
    }
  }

  /// Generate a poison byte for a given position and key byte
  int generatePoisonByte(int position, int keyByte) {
    return VaultFragment3.generatePoisonByte(position, keyByte);
  }

  /// Derive a sub-key for a specific pass from the user's key bytes
  Future<List<int>> derivePassKey(List<int> userKeyBytes, int passNumber) async {
    final saltSuffix = getSaltForPass(passNumber);
    final combined = [...userKeyBytes, ...saltSuffix, ...masterSeed];
    
    final algorithm = Sha256();
    final hash = await algorithm.hash(combined);
    return hash.bytes;
  }
}