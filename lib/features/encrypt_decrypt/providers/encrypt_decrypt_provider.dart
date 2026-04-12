// lib/features/encrypt_decrypt/providers/encrypt_decrypt_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/encryption/endecaprio_engine.dart';

/// State for the encrypt/decrypt feature
class EncryptDecryptState {
  final bool isEncryptMode;
  final bool isProcessing;
  final String? outputText;
  final String? errorMessage;
  final Duration? processingTime;
  final int? originalLength;
  final int? encryptedLength;

  const EncryptDecryptState({
    this.isEncryptMode = true,
    this.isProcessing = false,
    this.outputText,
    this.errorMessage,
    this.processingTime,
    this.originalLength,
    this.encryptedLength,
  });

  EncryptDecryptState copyWith({
    bool? isEncryptMode,
    bool? isProcessing,
    String? outputText,
    String? errorMessage,
    Duration? processingTime,
    int? originalLength,
    int? encryptedLength,
    bool clearOutput = false,
    bool clearError = false,
  }) {
    return EncryptDecryptState(
      isEncryptMode: isEncryptMode ?? this.isEncryptMode,
      isProcessing: isProcessing ?? this.isProcessing,
      outputText: clearOutput ? null : (outputText ?? this.outputText),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      processingTime: clearOutput ? null : (processingTime ?? this.processingTime),
      originalLength: clearOutput ? null : (originalLength ?? this.originalLength),
      encryptedLength: clearOutput ? null : (encryptedLength ?? this.encryptedLength),
    );
  }

  bool get hasOutput => outputText != null && outputText!.isNotEmpty;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

/// Provider for encrypt/decrypt operations
class EncryptDecryptNotifier extends StateNotifier<EncryptDecryptState> {
  final EnDecaprioEngine _engine;

  EncryptDecryptNotifier(this._engine) : super(const EncryptDecryptState());

  void toggleMode(bool isEncrypt) {
    state = state.copyWith(
      isEncryptMode: isEncrypt,
      clearOutput: true,
      clearError: true,
    );
  }

  void clearOutput() {
    state = state.copyWith(clearOutput: true, clearError: true);
  }

  Future<void> process(String inputText, String securityKey) async {
    // Clear previous results
    state = state.copyWith(
      isProcessing: true,
      clearOutput: true,
      clearError: true,
    );

    try {
      if (state.isEncryptMode) {
        final result = await _engine.encrypt(inputText, securityKey);
        state = state.copyWith(
          isProcessing: false,
          outputText: result.output,
          processingTime: result.processingTime,
          originalLength: result.originalLength,
          encryptedLength: result.encryptedLength,
          clearError: true,
        );
      } else {
        final result = await _engine.decrypt(inputText, securityKey);
        state = state.copyWith(
          isProcessing: false,
          outputText: result.output,
          processingTime: result.processingTime,
          clearError: true,
        );
      }
    } on EncryptionException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.message,
        clearOutput: true,
      );
    } on DecryptionException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.message,
        clearOutput: true,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
        clearOutput: true,
      );
    }
  }
}

// Providers
final engineProvider = Provider<EnDecaprioEngine>((ref) {
  return EnDecaprioEngine();
});

final encryptDecryptProvider =
    StateNotifierProvider<EncryptDecryptNotifier, EncryptDecryptState>((ref) {
  final engine = ref.watch(engineProvider);
  return EncryptDecryptNotifier(engine);
});