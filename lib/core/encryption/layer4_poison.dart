// lib/core/encryption/layer4_poison.dart

import 'dart:typed_data';
import '../secrets/vault_assembler.dart';

/// Layer 4: Poison Byte Injection
/// Inserts fake bytes at calculated positions to corrupt
/// the data for anyone trying to decrypt without this app

class Layer4Poison {
  /// Inject poison bytes after shuffling
  static Uint8List inject(Uint8List data, List<int> keyBytes) {
    final vault = VaultAssembler.instance;
    final poisonSeeds = vault.poisonSeeds;

    // Calculate how many poison bytes to inject
    final poisonCount = _calculatePoisonCount(data.length, keyBytes);

    // Calculate positions to inject at
    final positions = _calculatePositions(data.length, poisonCount, keyBytes, poisonSeeds);

    // Build result with poison bytes inserted
    final result = <int>[];
    int dataIndex = 0;
    int poisonIndex = 0;

    for (int i = 0; i < data.length + poisonCount; i++) {
      if (poisonIndex < positions.length && i == positions[poisonIndex]) {
        // Insert a poison byte
        int poisonByte = vault.generatePoisonByte(
          i,
          keyBytes[poisonIndex % keyBytes.length],
        );
        result.add(poisonByte);
        poisonIndex++;
      } else {
        // Insert real data
        if (dataIndex < data.length) {
          result.add(data[dataIndex]);
          dataIndex++;
        }
      }
    }

    // Append remaining real data if any
    while (dataIndex < data.length) {
      result.add(data[dataIndex]);
      dataIndex++;
    }

    return Uint8List.fromList(result);
  }

  /// Remove poison bytes for decryption
  static Uint8List remove(Uint8List data, List<int> keyBytes) {
    final vault = VaultAssembler.instance;
    final poisonSeeds = vault.poisonSeeds;

    // We need to figure out the original data length
    // poisonCount depends on original length, so we need to solve this
    final originalLength = _findOriginalLength(data.length, keyBytes);
    final poisonCount = data.length - originalLength;

    // Calculate the same positions used during injection
    final positions = _calculatePositions(originalLength, poisonCount, keyBytes, poisonSeeds);

    // Extract real data by skipping poison positions
    final result = <int>[];
    int poisonIndex = 0;

    for (int i = 0; i < data.length; i++) {
      if (poisonIndex < positions.length && i == positions[poisonIndex]) {
        // Skip this - it's a poison byte
        poisonIndex++;
      } else {
        result.add(data[i]);
      }
    }

    return Uint8List.fromList(result);
  }

  /// Calculate how many poison bytes to inject
  /// Based on data length and key properties
  static int _calculatePoisonCount(int dataLength, List<int> keyBytes) {
    // Inject between 3-12 poison bytes depending on data size
    int keyFactor = 0;
    for (int i = 0; i < keyBytes.length && i < 4; i++) {
      keyFactor += keyBytes[i];
    }

    int count = (keyFactor % 10) + 3; // 3-12

    // Don't inject more than 10% of data length
    int maxPoison = (dataLength * 0.1).ceil();
    if (maxPoison < 3) maxPoison = 3;

    return count > maxPoison ? maxPoison : count;
  }

  /// Calculate injection positions
  /// Must be deterministic and reproducible
  static List<int> _calculatePositions(
    int dataLength,
    int poisonCount,
    List<int> keyBytes,
    List<int> poisonSeeds,
  ) {
    final totalLength = dataLength + poisonCount;
    final positions = <int>[];

    // Generate positions using key and poison seeds
    int seed = 0;
    for (int i = 0; i < keyBytes.length; i++) {
      seed = (seed * 31 + keyBytes[i]) & 0x7FFFFFFF;
    }
    for (int i = 0; i < poisonSeeds.length; i++) {
      seed = (seed * 37 + poisonSeeds[i]) & 0x7FFFFFFF;
    }

    final rng = _PoisonRNG(seed);
    final usedPositions = <int>{};

    for (int i = 0; i < poisonCount; i++) {
      int pos;
      int attempts = 0;
      do {
        pos = rng.nextInt(totalLength);
        attempts++;
        if (attempts > 100) {
          // Fallback: find any unused position
          for (int p = 0; p < totalLength; p++) {
            if (!usedPositions.contains(p)) {
              pos = p;
              break;
            }
          }
          break;
        }
      } while (usedPositions.contains(pos));

      usedPositions.add(pos);
      positions.add(pos);
    }

    positions.sort();
    return positions;
  }

  /// Find original data length from total length (with poison)
  static int _findOriginalLength(int totalLength, List<int> keyBytes) {
    // Try different original lengths until we find the right one
    // where originalLength + poisonCount == totalLength
    for (int origLen = totalLength; origLen >= totalLength - 15; origLen--) {
      if (origLen <= 0) continue;
      int poisonCount = _calculatePoisonCount(origLen, keyBytes);
      if (origLen + poisonCount == totalLength) {
        return origLen;
      }
    }
    // Fallback: try broader range
    for (int origLen = totalLength - 1; origLen >= 1; origLen--) {
      int poisonCount = _calculatePoisonCount(origLen, keyBytes);
      if (origLen + poisonCount == totalLength) {
        return origLen;
      }
    }
    return totalLength; // No poison if we can't determine
  }
}

/// Seeded RNG for poison position generation
class _PoisonRNG {
  int _state;

  _PoisonRNG(this._state) {
    if (_state == 0) _state = 42;
  }

  int nextInt(int max) {
    if (max <= 0) return 0;
    _state = (_state * 48271 + 12345) & 0x7FFFFFFF;
    return _state % max;
  }
}