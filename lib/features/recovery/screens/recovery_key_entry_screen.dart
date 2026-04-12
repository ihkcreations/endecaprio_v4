// lib/features/recovery/screens/recovery_key_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/security/recovery_service.dart';
import '../../../core/utils/helpers.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'package:flutter/services.dart';
import '../../onboarding/screens/recovery_key_screen.dart';

class RecoveryKeyEntryScreen extends ConsumerStatefulWidget {
  const RecoveryKeyEntryScreen({super.key});

  @override
  ConsumerState<RecoveryKeyEntryScreen> createState() => _RecoveryKeyEntryScreenState();
}

class _RecoveryKeyEntryScreenState extends ConsumerState<RecoveryKeyEntryScreen> {
  final List<TextEditingController> _wordControllers = List.generate(
    12,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());

  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _wordControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get _enteredWords =>
      _wordControllers.map((c) => c.text.trim().toLowerCase()).toList();

  bool get _allFilled => _enteredWords.every((w) => w.isNotEmpty);

  Future<void> _handleVerify() async {
    if (!_allFilled) {
      setState(() => _error = 'Please fill in all 12 words');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final words = _enteredWords;
    final isValid = await ref.read(pinProvider.notifier).recoverWithWords(words);

    if (isValid) {
      if (mounted) {
        // Show new PIN setup dialog
        _showSetNewPinDialog();
      }
    } else {
      setState(() {
        _isVerifying = false;
        _error = 'Recovery key does not match. Please check your words.';
      });
    }
  }

  void _showSetNewPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Recovery Successful'),
          ],
        ),
        content: const Text(
          'Your identity has been verified.\n\nWhat would you like to do?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () async {
              // Remove PIN entirely
              await ref.read(pinProvider.notifier).removePinAfterRecovery();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Helpers.showSuccess(context, 'PIN has been removed');
              }
            },
            child: const Text('Remove PIN'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Remove old PIN first
              ref.read(pinProvider.notifier).removePinAfterRecovery();
              // Navigate to set new PIN
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const _SetNewPinScreen(),
                ),
              );
            },
            child: const Text('Set New PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Recovery Key')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 16),

                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.vpn_key, color: AppColors.tealLight, size: 30),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Enter your 12-word recovery key',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the words in the exact order you saved them',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Word input grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    return TextField(
                      controller: _wordControllers[index],
                      focusNode: _focusNodes[index],
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      textInputAction:
                          index < 11 ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) {
                        if (index < 11) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          _handleVerify();
                        }
                      },
                      decoration: InputDecoration(
                        prefixText: '${index + 1}. ',
                        prefixStyle: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'word',
                        hintStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
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

                const SizedBox(height: 32),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerify,
                    child: _isVerifying
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
                              Icon(Icons.verified, size: 18),
                              SizedBox(width: 8),
                              Text('Verify & Reset PIN'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple screen for setting a new PIN after recovery
class _SetNewPinScreen extends ConsumerStatefulWidget {
  const _SetNewPinScreen();

  @override
  ConsumerState<_SetNewPinScreen> createState() => _SetNewPinScreenState();
}

class _SetNewPinScreenState extends ConsumerState<_SetNewPinScreen> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecoveryKeyScreen(recoveryWords: words),
          ),
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
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
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