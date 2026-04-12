// lib/core/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class Helpers {
  /// Determine device type based on width
  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= AppConstants.desktopBreakpoint) return DeviceType.desktop;
    if (width >= AppConstants.tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Check if running on desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Copy text to clipboard with feedback
  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Copied to clipboard'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar (context-safe)
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Format date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Truncate text for display
  static String truncateText(String text, {int maxLength = 40}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

enum DeviceType { mobile, tablet, desktop }