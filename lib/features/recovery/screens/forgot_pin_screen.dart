// lib/features/recovery/screens/forgot_pin_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../data/repositories/entry_repository.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../tables/providers/tables_provider.dart';
import '../../onboarding/screens/pin_setup_screen.dart';
import '../../onboarding/screens/recovery_key_screen.dart';
import '../../../app.dart';
import 'package:flutter/services.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover PIN')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  'Recover Your PIN',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a recovery method',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Recovery Key option
                _buildOptionCard(
                  icon: Icons.vpn_key,
                  title: 'Enter 12-word Recovery Key',
                  subtitle: 'Use the recovery key you saved during setup',
                  onTap: () {
                    Navigator.pushNamed(context, '/recovery-key-entry');
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Nuclear option
                _buildOptionCard(
                  icon: Icons.delete_forever,
                  title: 'Reset App',
                  subtitle: 'Delete ALL data and start fresh',
                  isDestructive: true,
                  onTap: () => _showResetConfirmation(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.tealLight,
                          ),
                        )
                      : Icon(
                          icon,
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.tealLight,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  Icon(
                    Icons.chevron_right,
                    color: isDestructive
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Full Reset ─────────────────────────────────

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await ref.read(pinProvider.notifier).removePinAfterRecovery();
                final repo = ref.read(entryRepositoryProvider);
                await repo.resetAll();

                await SecureStorageService.instance.deleteAll();

                ref.invalidate(pinProvider);
                ref.invalidate(tablesProvider);
                ref.invalidate(onboardingCompleteProvider);

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AppEntry()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                Helpers.showError(context, 'Reset failed: $e');
              }
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

/// Set new PIN screen after recovery
class _SetNewPinAfterRecovery extends ConsumerStatefulWidget {
  const _SetNewPinAfterRecovery();

  @override
  ConsumerState<_SetNewPinAfterRecovery> createState() =>
      _SetNewPinAfterRecoveryState();
}

class _SetNewPinAfterRecoveryState
    extends ConsumerState<_SetNewPinAfterRecovery> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  bool _isConfirm = false;
  String _firstPin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _pin => _controllers.map((c) => c.text).join();

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _onComplete() async {
    if (_pin.length != 5) return;

    if (!_isConfirm) {
      _firstPin = _pin;
      setState(() {
        _isConfirm = true;
        _error = null;
      });
      _clearAll();
      return;
    }

    if (_pin != _firstPin) {
      setState(() {
        _error = 'PINs do not match';
        _isConfirm = false;
        _firstPin = '';
      });
      _clearAll();
      return;
    }

    final success = await ref.read(pinProvider.notifier).setupPin(_pin);
    if (success) {
      final words = await ref.read(pinProvider.notifier).generateRecoveryKey();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => RecoveryKeyScreen(
              recoveryWords: words,
              isFromSettings: true,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set New PIN')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isConfirm ? Icons.verified_user : Icons.lock,
                  color: AppColors.tealLight,
                  size: 48,
                ),
                const SizedBox(height: 24),
                Text(
                  _isConfirm ? 'Confirm New PIN' : 'Set New PIN',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Container(
                      width: 50,
                      height: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        obscureText: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.tealLight,
                              width: 2,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 4) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (v.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_pin.length == 5) _onComplete();
                        },
                      ),
                    );
                  }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}