// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../data/repositories/entry_repository.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/screens/pin_setup_screen.dart';
import '../../onboarding/screens/recovery_key_screen.dart';
import '../../tables/providers/tables_provider.dart';
import '../../../app.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── SECURITY ────────────────────────────
              _buildSectionHeader('SECURITY'),
              Card(
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.lock,
                      title: 'Table PIN Lock',
                      subtitle: pinState.isPinEnabled
                          ? 'Enabled - PIN required to view tables'
                          : 'Disabled - tables are unlocked',
                      trailing: Switch(
                        value: pinState.isPinEnabled,
                        onChanged: (val) {
                          if (val) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PinSetupScreen(isFromSettings: true),
                              ),
                            ).then((result) async {
                              if (result == true) {
                                final words = await ref
                                    .read(pinProvider.notifier)
                                    .generateRecoveryKey();
                                ref.read(pinProvider.notifier).refresh();
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecoveryKeyScreen(
                                        recoveryWords: words,
                                        isFromSettings: true,
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          } else {
                            _showRemovePinDialog(context, ref);
                          }
                        },
                      ),
                    ),
                    if (pinState.isPinEnabled) ...[
                      const Divider(height: 1, indent: 56),
                      _buildSettingTile(
                        icon: Icons.sync_lock,
                        title: 'Change PIN',
                        subtitle: 'Update your 5-digit passcode',
                        onTap: () => _showChangePinDialog(context, ref),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingTile(
                        icon: Icons.key,
                        title: 'Regenerate Recovery Key',
                        subtitle: 'Generate a new 12-word recovery key',
                        onTap: () =>
                            _showRegenerateRecoveryDialog(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── ABOUT ──────────────────────────────
              _buildSectionHeader('ABOUT'),
              Card(
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: AppConstants.appVersion,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingTile(
                      icon: Icons.enhanced_encryption,
                      title: 'Encryption',
                      subtitle: 'EnDecaprio Pipeline v4 • 6 Layers',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSettingTile(
                      icon: Icons.delete_forever,
                      title: 'Reset All Data',
                      subtitle: 'Delete everything and start fresh',
                      titleColor: AppColors.error,
                      onTap: () => _showResetDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.teal.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.teal, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ── PIN Dialogs ─────────────────────────────────

  void _showRemovePinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Remove PIN'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your current PIN to confirm removal.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 5,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text;
                if (pin.length != 5) {
                  setDialogState(() => error = 'Enter your 5-digit PIN');
                  return;
                }
                final result =
                    await ref.read(pinProvider.notifier).verifyPin(pin);
                if (result) {
                  await ref.read(pinProvider.notifier).togglePin(false);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    Helpers.showSuccess(context, 'PIN removed');
                  }
                } else {
                  setDialogState(() => error = 'Incorrect PIN');
                }
              },
              child: const Text('Remove PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.sync_lock, color: AppColors.teal),
              SizedBox(width: 8),
              Text('Change PIN'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 5,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPin = oldPinController.text;
                final newPin = newPinController.text;
                final confirmPin = confirmPinController.text;

                if (oldPin.length != 5) {
                  setDialogState(
                      () => error = 'Enter your current 5-digit PIN');
                  return;
                }
                if (newPin.length != 5) {
                  setDialogState(() => error = 'New PIN must be 5 digits');
                  return;
                }
                if (newPin != confirmPin) {
                  setDialogState(() => error = 'New PINs do not match');
                  return;
                }
                if (oldPin == newPin) {
                  setDialogState(
                      () => error = 'New PIN must be different from current');
                  return;
                }

                final success = await ref
                    .read(pinProvider.notifier)
                    .changePin(oldPin, newPin);
                if (success) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    Helpers.showSuccess(context, 'PIN changed successfully');
                  }
                } else {
                  setDialogState(() => error = 'Current PIN is incorrect');
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerateRecoveryDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Regenerate Recovery Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your current PIN to proceed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 5,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text;
                if (pin.length != 5) {
                  setDialogState(() => error = 'Enter your 5-digit PIN');
                  return;
                }
                final result =
                    await ref.read(pinProvider.notifier).verifyPin(pin);
                if (result) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  final words = await ref
                      .read(pinProvider.notifier)
                      .generateRecoveryKey();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecoveryKeyScreen(
                          recoveryWords: words,
                          isFromSettings: true,
                        ),
                      ),
                    );
                  }
                } else {
                  setDialogState(() => error = 'Incorrect PIN');
                }
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset ───────────────────────────────────────

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reset Everything?'),
          ],
        ),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All encrypted entries\n'
          '• All tables\n'
          '• Your PIN & recovery key\n'
          '• All app settings\n\n'
          'The app will restart as if freshly installed.\n\n'
          'This CANNOT be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _performFullReset(context, ref);
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullReset(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pinProvider.notifier).removePinAfterRecovery();
      final repo = ref.read(entryRepositoryProvider);
      await repo.resetAll();

      await SecureStorageService.instance.deleteAll();

      ref.invalidate(pinProvider);
      ref.invalidate(tablesProvider);
      ref.invalidate(onboardingCompleteProvider);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppEntry()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showError(context, 'Reset failed: $e');
      }
    }
  }
}