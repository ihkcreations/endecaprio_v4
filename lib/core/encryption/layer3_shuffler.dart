// lib/core/encryption/layer3_shuffler.dart

import 'dart:typed_data';
import '../secrets/vault_assembler.dart';

/// Layer 3: Proprietary byte shuffling
/// Rearranges bytes using a deterministic pattern derived from
/// the app's internal seeds + user's key characteristics
///
/// NOTE: In production, this could be moved to C via dart:ffi
/// for additional obfuscation. For now, implemented in Dart
/// with the same algorithm that the C version would use.

class Layer3Shuffler {
  /// Shuffle bytes after encryption
  static Uint8List shuffle(Uint8List data, List<int> keyBytes) {
    if (data.length <= 1) return data;

    final vault = VaultAssembler.instance;
    final pattern = _generateShufflePattern(data.length, keyBytes, vault.shuffleSeeds);

    // Apply the shuffle: move each byte to its new position
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[pattern[i]] = data[i];
    }

    return result;
  }

  /// Unshuffle bytes for decryption (reverse the shuffle)
  static Uint8List unshuffle(Uint8List data, List<int> keyBytes) {
    if (data.length <= 1) return data;

    final vault = VaultAssembler.instance;
    final pattern = _generateShufflePattern(data.length, keyBytes, vault.shuffleSeeds);

    // Reverse the shuffle: read from shuffled positions
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[pattern[i]];
    }

    return result;
  }

  /// Generate a deterministic shuffle pattern (permutation)
  /// Uses Fisher-Yates shuffle with a seeded PRNG
  static List<int> _generateShufflePattern(
    int length,
    List<int> keyBytes,
    List<int> shuffleSeeds,
  ) {
    // Create initial ordered list
    final pattern = List<int>.generate(length, (i) => i);

    // Create a deterministic seed from key bytes + shuffle seeds
    int seed = _combineSeed(keyBytes, shuffleSeeds, length);

    // Fisher-Yates shuffle with deterministic random
    final rng = _SeededRNG(seed);

    for (int i = length - 1; i > 0; i--) {
      int j = rng.nextInt(i + 1);
      // Swap
      int temp = pattern[i];
      pattern[i] = pattern[j];
      pattern[j] = temp;
    }

    return pattern;
  }

  /// Combine multiple seed sources into one integer
  static int _combineSeed(List<int> keyBytes, List<int> shuffleSeeds, int dataLength) {
    int seed = dataLength * 31;

    for (int i = 0; i < keyBytes.length; i++) {
      seed = (seed * 37 + keyBytes[i] * (i + 1)) & 0x7FFFFFFF;
    }

    for (int i = 0; i < shuffleSeeds.length; i++) {
      seed = (seed * 41 + shuffleSeeds[i] * (i + 3)) & 0x7FFFFFFF;
    }

    // Mix in data length influence
    seed = (seed ^ (dataLength * 0x5BD1E995)) & 0x7FFFFFFF;

    return seed == 0 ? 1 : seed;
  }
}

/// Simple seeded pseudo-random number generator
/// Ensures shuffle pattern is deterministic and reproducible
class _SeededRNG {
  int _state;

  _SeededRNG(this._state) {
    if (_state == 0) _state = 1;
  }

  /// Linear congruential generator
  int nextInt(int max) {
    // Parameters from Numerical Recipes
    _state = (_state * 1664525 + 1013904223) & 0x7FFFFFFF;
    return _state % max;
  }
}