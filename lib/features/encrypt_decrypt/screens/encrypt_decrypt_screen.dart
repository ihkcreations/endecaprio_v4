// lib/features/encrypt_decrypt/screens/encrypt_decrypt_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../providers/encrypt_decrypt_provider.dart';
import '../widgets/save_dialog.dart';

class EncryptDecryptScreen extends ConsumerStatefulWidget {
  const EncryptDecryptScreen({super.key});

  @override
  ConsumerState<EncryptDecryptScreen> createState() =>
      _EncryptDecryptScreenState();
}

class _EncryptDecryptScreenState extends ConsumerState<EncryptDecryptScreen> {
  final _inputController = TextEditingController();
  final _keyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _handleProcess() {
    final text = _inputController.text.trim();
    final key = _keyController.text;

    if (text.isEmpty) {
      Helpers.showError(context, 'Please enter text to process');
      return;
    }
    if (key.isEmpty) {
      Helpers.showError(context, 'Please enter a security key');
      return;
    }
    if (key.length < 3) {
      Helpers.showError(context, 'Security key must be at least 3 characters');
      return;
    }

    ref.read(encryptDecryptProvider.notifier).process(text, key);
  }

  void _handleNew() {
    _inputController.clear();
    _keyController.clear();
    ref.read(encryptDecryptProvider.notifier).clearOutput();
  }

  void _handleCopy(String text) {
    Helpers.copyToClipboard(context, text);
  }

  void _showSaveDialog(String encryptedText) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SaveDialog(encryptedText: encryptedText),
    );

    if (result == true && mounted) {
      Helpers.showSuccess(context, 'Entry saved successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(encryptDecryptProvider);

    ref.listen<EncryptDecryptState>(encryptDecryptProvider, (prev, next) {
      if (next.hasError && (prev == null || !prev.hasError)) {
        Helpers.showError(context, next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('EnDecaprioV4'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Toggle
                _buildModeToggle(state),
                const SizedBox(height: 20),

                // Combined Input Card (Text + Key + Result + Button all in one)
                _buildMainCard(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(EncryptDecryptState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(encryptDecryptProvider.notifier).toggleMode(true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient:
                        state.isEncryptMode ? AppColors.tealGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 20,
                        color: state.isEncryptMode
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ENCRYPT',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: state.isEncryptMode
                              ? Colors.white
                              : AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(encryptDecryptProvider.notifier).toggleMode(false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient:
                        !state.isEncryptMode ? AppColors.tealGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 20,
                        color: !state.isEncryptMode
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DECRYPT',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: !state.isEncryptMode
                              ? Colors.white
                              : AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(EncryptDecryptState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Text Input ──────────────────────────
            Row(
              children: [
                Icon(
                  state.isEncryptMode ? Icons.edit_note : Icons.input,
                  color: AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isEncryptMode
                      ? 'Enter your text'
                      : 'Paste encrypted text',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.paste, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Paste',
                  onPressed: () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _inputController.text = data!.text!;
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Clear',
                  onPressed: () => _inputController.clear(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inputController,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: state.isEncryptMode
                    ? 'Type or paste the text you want to encrypt...'
                    : 'Paste the EnDecaprioV4 encrypted text here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // ── Security Key ────────────────────────
            const Row(
              children: [
                Icon(Icons.key, color: AppColors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Security Key',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Min 3 characters. Use the same key to decrypt.',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your security passphrase...',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),

            // ── Result (shown BEFORE the button) ────
            if (state.isProcessing) ...[
              const SizedBox(height: 20),
              _buildLoadingSection(state),
            ],

            if (state.hasOutput) ...[
              const SizedBox(height: 20),
              _buildResultSection(state),
            ],

            const SizedBox(height: 20),

            // ── Action Button ───────────────────────
            _buildProcessButton(state),

            // ── New / Save buttons (only when output exists) ──
            if (state.hasOutput) ...[
              const SizedBox(height: 12),
              _buildOutputActions(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection(EncryptDecryptState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            state.isEncryptMode
                ? 'Encrypting through 6 layers...'
                : 'Decrypting through 6 layers...',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(EncryptDecryptState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                state.isEncryptMode ? Icons.shield : Icons.text_snippet,
                color: AppColors.tealLight,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                state.isEncryptMode ? 'Encrypted Result' : 'Decrypted Result',
                style: const TextStyle(
                  color: AppColors.tealLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (state.processingTime != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${state.processingTime!.inMilliseconds}ms',
                    style: const TextStyle(
                      color: AppColors.tealLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Output text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: SelectableText(
              state.outputText ?? '',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: state.isEncryptMode ? 'monospace' : null,
                height: 1.6,
              ),
            ),
          ),

          // Stats
          if (state.isEncryptMode && state.originalLength != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStat('Original', '${state.originalLength} chars'),
                const SizedBox(width: 16),
                _buildStat('Encrypted', '${state.encryptedLength} chars'),
                const SizedBox(width: 16),
                _buildStat('Pipeline', 'v4 • 6 layers'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessButton(EncryptDecryptState state) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: state.isProcessing ? null : AppColors.tealGradient,
        color: state.isProcessing ? AppColors.surfaceLight : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: state.isProcessing
            ? null
            : [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: state.isProcessing ? null : _handleProcess,
          child: Center(
            child: state.isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.teal,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        state.isEncryptMode ? 'ENCRYPT' : 'DECRYPT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputActions(EncryptDecryptState state) {
    return Row(
      children: [
        // Copy
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleCopy(state.outputText!),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ),
        const SizedBox(width: 8),
        // New
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleNew,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('New'),
          ),
        ),
        // Save (encrypt mode only)
        if (state.isEncryptMode) ...[
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showSaveDialog(state.outputText!),
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}