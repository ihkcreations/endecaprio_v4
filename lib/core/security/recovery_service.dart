// lib/core/security/recovery_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'secure_storage_service.dart';
import '../secrets/secrets_config.dart';

class RecoveryService {
  static RecoveryService? _instance;
  final SecureStorageService _storage;

  RecoveryService._() : _storage = SecureStorageService.instance;

  static RecoveryService get instance {
    _instance ??= RecoveryService._();
    return _instance!;
  }

  /// BIP39-inspired word list (simplified - 256 words)
  static const List<String> _wordList = [
    'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract',
    'acid', 'acoustic', 'acquire', 'across', 'action', 'actor', 'adapt', 'address',
    'adjust', 'admit', 'adult', 'advance', 'affair', 'afford', 'agent', 'agree',
    'ahead', 'aim', 'air', 'airport', 'aisle', 'alarm', 'album', 'alert',
    'alien', 'alley', 'alpha', 'already', 'alter', 'always', 'amateur', 'anchor',
    'ancient', 'angel', 'animal', 'ankle', 'announce', 'annual', 'antique', 'anxiety',
    'apple', 'april', 'arctic', 'arena', 'army', 'arrow', 'artist', 'assault',
    'atom', 'auction', 'audit', 'autumn', 'avocado', 'average', 'axis', 'badge',
    'balance', 'bamboo', 'banana', 'banner', 'barrel', 'basic', 'basket', 'battle',
    'beach', 'bean', 'beauty', 'become', 'beyond', 'bicycle', 'bird', 'blanket',
    'blast', 'blaze', 'bless', 'blind', 'blood', 'blossom', 'board', 'boat',
    'bomb', 'bonus', 'border', 'bounce', 'brain', 'brave', 'bread', 'bridge',
    'bright', 'broken', 'bronze', 'brush', 'bubble', 'buddy', 'buffalo', 'bullet',
    'burden', 'butter', 'cabin', 'cable', 'cactus', 'cage', 'camera', 'camp',
    'canal', 'candy', 'canoe', 'canvas', 'canyon', 'carbon', 'cargo', 'carpet',
    'casino', 'castle', 'catalog', 'catch', 'cattle', 'cave', 'cedar', 'cement',
    'cherry', 'chief', 'chimney', 'choice', 'chunk', 'cinema', 'circle', 'citizen',
    'claim', 'clap', 'clarify', 'clay', 'clever', 'cliff', 'climb', 'clock',
    'cloud', 'cluster', 'coach', 'coast', 'coconut', 'coffee', 'coil', 'colony',
    'combat', 'comic', 'common', 'company', 'concert', 'conduct', 'connect', 'consider',
    'control', 'coral', 'core', 'corner', 'cotton', 'couch', 'country', 'couple',
    'cover', 'craft', 'crane', 'crash', 'crater', 'crawl', 'crazy', 'cream',
    'creek', 'crew', 'cricket', 'crime', 'crisp', 'cross', 'crowd', 'cruise',
    'crush', 'crystal', 'cube', 'culture', 'curtain', 'curve', 'custom', 'cycle',
    'dagger', 'damage', 'dance', 'danger', 'daring', 'dawn', 'debate', 'decade',
    'decimal', 'decline', 'deer', 'define', 'delay', 'delta', 'demand', 'demon',
    'denial', 'dentist', 'depend', 'deploy', 'depth', 'desert', 'design', 'detail',
    'device', 'devote', 'diamond', 'diary', 'diesel', 'diet', 'digital', 'dilemma',
    'dinner', 'dinosaur', 'direct', 'dirt', 'disease', 'dismiss', 'display', 'distance',
    'divert', 'doctor', 'dolphin', 'domain', 'donate', 'donkey', 'donor', 'door',
    'double', 'dove', 'dragon', 'drama', 'dream', 'drift', 'drink', 'drip',
    'drive', 'drum', 'duck', 'dumb', 'dune', 'dust', 'dwarf', 'dynamic',
  ];

  /// Generate 12 random recovery words
  List<String> generateRecoveryWords() {
    final random = Random.secure();
    final words = <String>[];
    final usedIndices = <int>{};

    while (words.length < 12) {
      final index = random.nextInt(_wordList.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        words.add(_wordList[index]);
      }
    }

    return words;
  }

  /// Hash recovery words for storage
  Future<String> _hashRecoveryWords(List<String> words) async {
    final combined = '${SecretsConfig.recoverySalt}_${words.join('_')}_RECOVERY';
    final algorithm = Sha256();
    final hash = await algorithm.hash(utf8.encode(combined));
    return base64Encode(hash.bytes);
  }

  /// Save recovery key hash
  Future<void> saveRecoveryKey(List<String> words) async {
    final hash = await _hashRecoveryWords(words);
    await _storage.saveRecoveryHash(hash);
  }

  /// Verify recovery words
  Future<bool> verifyRecoveryWords(List<String> words) async {
    final storedHash = await _storage.getRecoveryHash();
    if (storedHash == null) return false;

    final inputHash = await _hashRecoveryWords(words);
    return inputHash == storedHash;
  }

  /// Check if recovery key has been set
  Future<bool> hasRecoveryKey() async {
    final hash = await _storage.getRecoveryHash();
    return hash != null && hash.isNotEmpty;
  }

  /// Get the word list (for validation)
  static bool isValidWord(String word) {
    return _wordList.contains(word.toLowerCase().trim());
  }

  /// Get suggestions for partial word input
  static List<String> getSuggestions(String partial) {
    if (partial.isEmpty) return [];
    final lower = partial.toLowerCase();
    return _wordList
        .where((w) => w.startsWith(lower))
        .take(5)
        .toList();
  }
}