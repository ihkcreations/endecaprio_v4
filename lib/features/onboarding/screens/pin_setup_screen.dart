// lib/features/onboarding/screens/pin_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const PinSetupScreen({super.key, this.isFromSettings = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  bool _isConfirmStep = false;
  String _firstPin = '';
  String? _error;
  bool _isProcessing = false;

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

  String get _currentPin => _controllers.map((c) => c.text).join();

  bool get _isPinComplete => _currentPin.length == 5;

  void _clearPin() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _error = null);
    _focusNodes[0].requestFocus();
  }

  Future<void> _handlePinComplete() async {
    if (!_isPinComplete) return;

    final pin = _currentPin;

    if (!_isConfirmStep) {
      // First entry - save and ask to confirm
      _firstPin = pin;
      setState(() {
        _isConfirmStep = true;
        _error = null;
      });
      _clearPin();
      return;
    }

    // Confirm step - verify match
    if (pin != _firstPin) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _isConfirmStep = false;
        _firstPin = '';
      });
      _clearPin();
      return;
    }

    // PINs match - save
    setState(() => _isProcessing = true);

    final success = await ref.read(pinProvider.notifier).setupPin(pin);

    if (success) {
      if (widget.isFromSettings) {
        // From settings: just pop with true
        // Settings screen handles recovery key display
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // From onboarding: generate recovery key and navigate
        final words = await ref.read(pinProvider.notifier).generateRecoveryKey();
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/recovery-key-setup',
            arguments: words,
          );
        }
      }
    } else {
      setState(() {
        _isProcessing = false;
        _error = 'Failed to set PIN';
      });
      _clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFromSettings
          ? AppBar(title: const Text('Set PIN'))
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isConfirmStep ? Icons.verified_user : Icons.lock,
                    color: AppColors.tealLight,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  _isConfirmStep ? 'Confirm Your PIN' : 'Set Your PIN',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isConfirmStep
                      ? 'Enter the same PIN again to confirm'
                      : 'Enter a 5-digit passcode to secure your tables',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // PIN Input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Container(
                      width: 52,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        obscureText: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _controllers[index].text.isNotEmpty
                              ? AppColors.teal.withOpacity(0.15)
                              : AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _controllers[index].text.isNotEmpty
                                  ? AppColors.teal
                                  : AppColors.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _controllers[index].text.isNotEmpty
                                  ? AppColors.teal
                                  : AppColors.divider,
                            ),
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
                        onChanged: (value) {
                          setState(() {});
                          if (value.isNotEmpty && index < 4) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_isPinComplete) {
                            _handlePinComplete();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                // Processing indicator
                if (_isProcessing) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.teal),
                ],

                const SizedBox(height: 40),

                // Skip button (only during onboarding)
                if (!widget.isFromSettings)
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: AppColors.textSecondary),
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