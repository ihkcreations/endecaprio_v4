// lib/core/encryption/layer1_preprocessor.dart

import 'dart:convert';
import '../secrets/vault_assembler.dart';

class Layer1Preprocessor {
  /// Pre-process text before encryption:
  /// 1. Reverse the text
  /// 2. Apply Caesar shift derived from key
  /// 3. Inject watermark characters at intervals

  static String process(String rawText, List<int> keyBytes) {
    final vault = VaultAssembler.instance;

    // Step 1: Reverse the text
    String processed = _reverseString(rawText);

    // Step 2: Apply Caesar shift
    int shiftAmount = _calculateShift(keyBytes, vault.caesarShiftBase);
    processed = _caesarShift(processed, shiftAmount);

    // Step 3: Inject watermark characters
    processed = _injectWatermarks(processed, keyBytes, vault.watermarkChars);

    return processed;
  }

  /// Reverse the pre-processing (for decryption)
  static String reverseProcess(String processedText, List<int> keyBytes) {
    final vault = VaultAssembler.instance;

    // Step 3: Remove watermark characters (reverse order)
    String result = _removeWatermarks(processedText, keyBytes, vault.watermarkChars);

    // Step 2: Reverse Caesar shift
    int shiftAmount = _calculateShift(keyBytes, vault.caesarShiftBase);
    result = _caesarShift(result, -shiftAmount);

    // Step 1: Reverse the text back
    result = _reverseString(result);

    return result;
  }

  static String _reverseString(String input) {
    // Handle Unicode properly by using runes
    return String.fromCharCodes(input.runes.toList().reversed);
  }

  static int _calculateShift(List<int> keyBytes, int shiftBase) {
    int keySum = 0;
    for (int i = 0; i < keyBytes.length; i++) {
      keySum += keyBytes[i] * (i + 1);
    }
    // Shift between 1-95 (printable ASCII range)
    return ((keySum % 94) + shiftBase) % 94 + 1;
  }

  static String _caesarShift(String text, int shift) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 32 && rune <= 126) {
        // Printable ASCII - shift within range
        int shifted = ((rune - 32 + shift) % 95) + 32;
        if (shifted < 32) shifted += 95;
        buffer.writeCharCode(shifted);
      } else {
        // Non-ASCII - shift by a different amount
        int shifted = rune + (shift % 256);
        buffer.writeCharCode(shifted);
      }
    }
    return buffer.toString();
  }

  static String _injectWatermarks(
    String text,
    List<int> keyBytes,
    List<int> watermarkChars,
  ) {
    if (text.isEmpty) return text;

    // Calculate injection interval based on key
    int interval = _calculateInterval(keyBytes, text.length);
    if (interval < 2) interval = 2;

    final runes = text.runes.toList();
    final result = <int>[];
    int watermarkIndex = 0;

    for (int i = 0; i < runes.length; i++) {
      result.add(runes[i]);

      // Inject watermark at calculated intervals
      if ((i + 1) % interval == 0 && i < runes.length - 1) {
        // XOR watermark char with position for variety
        int wmChar = watermarkChars[watermarkIndex % watermarkChars.length];
        wmChar = (wmChar ^ (i & 0xFF)) | 0x100; // Ensure it's in extended Unicode range
        result.add(wmChar);
        watermarkIndex++;
      }
    }

    return String.fromCharCodes(result);
  }

  static String _removeWatermarks(
    String text,
    List<int> keyBytes,
    List<int> watermarkChars,
  ) {
    if (text.isEmpty) return text;

    final runes = text.runes.toList();
    final result = <int>[];

    // We need to identify and remove watermark characters
    // Rebuild the original text by tracking intervals
    int interval = _calculateIntervalForRemoval(keyBytes, runes.length);
    if (interval < 2) interval = 2;

    int originalIndex = 0;
    int wmExpectedIndex = 0;
    int charsSinceLastWm = 0;

    for (int i = 0; i < runes.length; i++) {
      bool isWatermark = false;

      // Check if this position should be a watermark
      if (charsSinceLastWm == interval && originalIndex > 0) {
        int expectedWm = watermarkChars[wmExpectedIndex % watermarkChars.length];
        expectedWm = (expectedWm ^ ((originalIndex - 1) & 0xFF)) | 0x100;

        if (runes[i] == expectedWm) {
          isWatermark = true;
          wmExpectedIndex++;
          charsSinceLastWm = 0;
        }
      }

      if (!isWatermark) {
        result.add(runes[i]);
        originalIndex++;
        charsSinceLastWm++;
      }
    }

    return String.fromCharCodes(result);
  }

  static int _calculateInterval(List<int> keyBytes, int textLength) {
    int sum = 0;
    for (int i = 0; i < keyBytes.length && i < 8; i++) {
      sum += keyBytes[i];
    }
    // Interval between 3-8 characters
    return (sum % 6) + 3;
  }

  static int _calculateIntervalForRemoval(List<int> keyBytes, int totalLength) {
    // Same calculation as injection to ensure consistency
    int sum = 0;
    for (int i = 0; i < keyBytes.length && i < 8; i++) {
      sum += keyBytes[i];
    }
    return (sum % 6) + 3;
  }
}