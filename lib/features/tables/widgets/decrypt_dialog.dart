// lib/features/tables/widgets/decrypt_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/encryption/endecaprio_engine.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/encrypted_entry.dart';
import '../../encrypt_decrypt/providers/encrypt_decrypt_provider.dart';

class DecryptDialog extends ConsumerStatefulWidget {
  final EncryptedEntry entry;

  const DecryptDialog({super.key, required this.entry});

  @override
  ConsumerState<DecryptDialog> createState() => _DecryptDialogState();
}

class _DecryptDialogState extends ConsumerState<DecryptDialog> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isDecrypting = false;
  String? _decryptedText;
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleDecrypt() async {
    final key = _keyController.text;
    if (key.isEmpty) {
      setState(() => _error = 'Please enter the security key');
      return;
    }

    setState(() {
      _isDecrypting = true;
      _error = null;
      _decryptedText = null;
    });

    try {
      final engine = ref.read(engineProvider);
      final result = await engine.decrypt(widget.entry.encryptedText, key);

      setState(() {
        _isDecrypting = false;
        _decryptedText = result.output;
      });
    } on DecryptionException catch (e) {
      setState(() {
        _isDecrypting = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isDecrypting = false;
        _error = 'Decryption failed. Wrong key or corrupted data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.lock_open, color: AppColors.teal, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Decrypt Entry',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.entry.note.isNotEmpty)
                          Text(
                            widget.entry.note,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Security key input
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: (_) => _handleDecrypt(),
                decoration: InputDecoration(
                  hintText: 'Enter security key...',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Decrypt button
              ElevatedButton(
                onPressed: _isDecrypting ? null : _handleDecrypt,
                child: _isDecrypting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 18),
                          SizedBox(width: 6),
                          Text('Decrypt'),
                        ],
                      ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Decrypted result
              if (_decryptedText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Decrypted Text',
                            style: TextStyle(
                              color: AppColors.tealLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _decryptedText!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Helpers.copyToClipboard(context, _decryptedText!),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}