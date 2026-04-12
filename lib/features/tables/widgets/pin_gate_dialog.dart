// lib/features/tables/widgets/pin_gate_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class PinGateDialog extends ConsumerStatefulWidget {
  const PinGateDialog({super.key});

  @override
  ConsumerState<PinGateDialog> createState() => _PinGateDialogState();
}

class _PinGateDialogState extends ConsumerState<PinGateDialog>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _lockoutTimer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      _startLockoutTimerIfNeeded();
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
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  String get _currentPin => _controllers.map((c) => c.text).join();
  bool get _isPinComplete => _currentPin.length == 5;

  void _clearPin() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _startLockoutTimerIfNeeded() {
    final pinState = ref.read(pinProvider);
    if (pinState.isLockedOut && pinState.lockoutSeconds > 0) {
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final current = ref.read(pinProvider);
        if (current.lockoutSeconds <= 1) {
          timer.cancel();
          ref.read(pinProvider.notifier).updateLockoutTimer(0);
        } else {
          ref.read(pinProvider.notifier).updateLockoutTimer(
                current.lockoutSeconds - 1,
              );
        }
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (!_isPinComplete || _isVerifying) return;

    setState(() => _isVerifying = true);

    final pin = _currentPin;
    final success = await ref.read(pinProvider.notifier).verifyPin(pin);

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // Shake animation
      _shakeController.forward(from: 0);
      _clearPin();
      setState(() => _isVerifying = false);

      // Start lockout timer if locked out
      _startLockoutTimerIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: pinState.isLockedOut
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                pinState.isLockedOut ? Icons.lock_clock : Icons.lock,
                color: pinState.isLockedOut ? AppColors.error : AppColors.tealLight,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              pinState.isLockedOut ? 'Locked Out' : 'Enter PIN',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (pinState.isLockedOut)
              Text(
                'Try again in ${pinState.lockoutSeconds}s',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              )
            else
              const Text(
                'Enter your 5-digit PIN to access this table',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 28),

            // PIN Input boxes with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeController.isAnimating
                        ? _shakeAnimation.value *
                            ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1)
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      obscureText: true,
                      enabled: !pinState.isLockedOut && !_isVerifying,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: pinState.isLockedOut
                            ? AppColors.surfaceLight.withOpacity(0.5)
                            : AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.divider),
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.divider.withOpacity(0.5),
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
            ),

            // Error message
            if (pinState.error != null && !pinState.isLockedOut) ...[
              const SizedBox(height: 16),
              Text(
                pinState.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Forgot PIN link
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pushNamed(context, '/forgot-pin');
              },
              child: const Text(
                'Forgot PIN?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}