// lib/core/encryption/layer6_encoding.dart

import 'dart:typed_data';
import '../secrets/vault_assembler.dart';

/// Layer 6: Custom Encoding
/// Converts binary data to a custom alphabet instead of Base64
/// Makes the output look unique and unrecognizable

class Layer6Encoding {
  /// Encode bytes to EnDecaprio custom alphabet string
  static String encode(Uint8List data) {
    final vault = VaultAssembler.instance;
    final alphabet = vault.customAlphabet;
    final padding = vault.paddingChar;

    if (data.isEmpty) return '';

    final buffer = StringBuffer();
    final alphabetRunes = alphabet.runes.toList();

    if (alphabetRunes.length < 64) {
      // Fallback to base64 if alphabet is too short
      return _fallbackEncode(data);
    }

    // Process 3 bytes at a time (like Base64)
    int i = 0;
    while (i < data.length) {
      int b0 = data[i];
      int b1 = (i + 1 < data.length) ? data[i + 1] : 0;
      int b2 = (i + 2 < data.length) ? data[i + 2] : 0;

      // Split 24 bits into 4 groups of 6 bits
      int c0 = (b0 >> 2) & 0x3F;
      int c1 = ((b0 & 0x03) << 4) | ((b1 >> 4) & 0x0F);
      int c2 = ((b1 & 0x0F) << 2) | ((b2 >> 6) & 0x03);
      int c3 = b2 & 0x3F;

      buffer.writeCharCode(alphabetRunes[c0]);
      buffer.writeCharCode(alphabetRunes[c1]);

      if (i + 1 < data.length) {
        buffer.writeCharCode(alphabetRunes[c2]);
      } else {
        buffer.write(padding);
      }

      if (i + 2 < data.length) {
        buffer.writeCharCode(alphabetRunes[c3]);
      } else {
        buffer.write(padding);
      }

      i += 3;
    }

    return buffer.toString();
  }

  /// Decode EnDecaprio custom alphabet string back to bytes
  static Uint8List decode(String encoded) {
    final vault = VaultAssembler.instance;
    final alphabet = vault.customAlphabet;
    final padding = vault.paddingChar;

    if (encoded.isEmpty) return Uint8List(0);

    final alphabetRunes = alphabet.runes.toList();
    final paddingRune = padding.runes.first;

    if (alphabetRunes.length < 64) {
      return _fallbackDecode(encoded);
    }

    // Build reverse lookup map
    final reverseMap = <int, int>{};
    for (int i = 0; i < alphabetRunes.length; i++) {
      reverseMap[alphabetRunes[i]] = i;
    }

    final encodedRunes = encoded.runes.toList();
    final result = <int>[];

    int i = 0;
    while (i < encodedRunes.length) {
      if (i + 1 >= encodedRunes.length) break;

      int c0 = reverseMap[encodedRunes[i]] ?? 0;
      int c1 = reverseMap[encodedRunes[i + 1]] ?? 0;
      int c2 = (i + 2 < encodedRunes.length && encodedRunes[i + 2] != paddingRune)
          ? (reverseMap[encodedRunes[i + 2]] ?? 0)
          : -1;
      int c3 = (i + 3 < encodedRunes.length && encodedRunes[i + 3] != paddingRune)
          ? (reverseMap[encodedRunes[i + 3]] ?? 0)
          : -1;

      // Reconstruct bytes
      int b0 = ((c0 << 2) | (c1 >> 4)) & 0xFF;
      result.add(b0);

      if (c2 != -1) {
        int b1 = (((c1 & 0x0F) << 4) | (c2 >> 2)) & 0xFF;
        result.add(b1);
      }

      if (c3 != -1) {
        int b2 = (((c2 & 0x03) << 6) | c3) & 0xFF;
        result.add(b2);
      }

      i += 4;
    }

    return Uint8List.fromList(result);
  }

  /// Verify if a string is valid EnDecaprio encoded text
  static bool isValidEncoded(String text) {
    if (text.isEmpty) return false;

    final vault = VaultAssembler.instance;
    final alphabet = vault.customAlphabet;
    final padding = vault.paddingChar;

    final validRunes = <int>{
      ...alphabet.runes,
      ...padding.runes,
    };

    for (final rune in text.runes) {
      if (!validRunes.contains(rune)) {
        return false;
      }
    }

    return true;
  }

  /// Fallback base64-like encoding if custom alphabet is insufficient
  static String _fallbackEncode(Uint8List data) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-';
    final buffer = StringBuffer();

    int i = 0;
    while (i < data.length) {
      int b0 = data[i];
      int b1 = (i + 1 < data.length) ? data[i + 1] : 0;
      int b2 = (i + 2 < data.length) ? data[i + 2] : 0;

      buffer.write(chars[(b0 >> 2) & 0x3F]);
      buffer.write(chars[((b0 & 0x03) << 4) | ((b1 >> 4) & 0x0F)]);
      buffer.write(i + 1 < data.length ? chars[((b1 & 0x0F) << 2) | ((b2 >> 6) & 0x03)] : '=');
      buffer.write(i + 2 < data.length ? chars[b2 & 0x3F] : '=');

      i += 3;
    }

    return buffer.toString();
  }

  static Uint8List _fallbackDecode(String encoded) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-';
    final result = <int>[];

    int i = 0;
    while (i < encoded.length) {
      int c0 = chars.indexOf(encoded[i]);
      int c1 = i + 1 < encoded.length ? chars.indexOf(encoded[i + 1]) : 0;
      int c2 = i + 2 < encoded.length && encoded[i + 2] != '=' ? chars.indexOf(encoded[i + 2]) : -1;
      int c3 = i + 3 < encoded.length && encoded[i + 3] != '=' ? chars.indexOf(encoded[i + 3]) : -1;

      if (c0 < 0) c0 = 0;
      if (c1 < 0) c1 = 0;

      result.add(((c0 << 2) | (c1 >> 4)) & 0xFF);
      if (c2 != -1) result.add((((c1 & 0x0F) << 4) | (c2 >> 2)) & 0xFF);
      if (c3 != -1) result.add((((c2 & 0x03) << 6) | c3) & 0xFF);

      i += 4;
    }

    return Uint8List.fromList(result);
  }
}