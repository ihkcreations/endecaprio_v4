// lib/features/onboarding/screens/recovery_key_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../app.dart';

class RecoveryKeyScreen extends ConsumerStatefulWidget {
  final List<String> recoveryWords;
  final bool isFromSettings;

  const RecoveryKeyScreen({
    super.key,
    required this.recoveryWords,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends ConsumerState<RecoveryKeyScreen> {
  bool _hasSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFromSettings ? AppBar(title: const Text('New Recovery Key')) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.key,
                    color: AppColors.warning,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Save Your Recovery Key',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you ever forget your PIN, you\'ll need these 12 words to recover access.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Recovery words grid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: widget.recoveryWords.asMap().entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.key + 1}.',
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Write this down somewhere safe. This will NOT be shown again.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Copy button
                OutlinedButton.icon(
                  onPressed: () {
                    final wordsText = widget.recoveryWords
                        .asMap()
                        .entries
                        .map((e) => '${e.key + 1}. ${e.value}')
                        .join('\n');
                    Helpers.copyToClipboard(context, wordsText);
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy to Clipboard'),
                ),
                const SizedBox(height: 32),

                // Checkbox
                CheckboxListTile(
                  value: _hasSaved,
                  onChanged: (val) => setState(() => _hasSaved = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.teal,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: const Text(
                    'I have saved my recovery key',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasSaved ? () => _completeSetup() : null,
                    child: Text(widget.isFromSettings ? 'Done' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    if (widget.isFromSettings) {
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSuccess(context, 'Recovery key has been updated');
      }
    } else {
      // Mark onboarding complete
      await SecureStorageService.instance.setOnboardingComplete();
      
      if (mounted) {
        // Go directly to AppShell, skip the provider check entirely
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      }
    }
  }
}