// lib/navigation/app_router.dart

import 'package:flutter/material.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/encrypt_decrypt/screens/encrypt_decrypt_screen.dart';
import '../features/tables/screens/tables_list_screen.dart';
import '../features/tables/screens/table_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/recovery/screens/forgot_pin_screen.dart';
import '../features/recovery/screens/recovery_key_entry_screen.dart';
import '../features/onboarding/screens/pin_setup_screen.dart';
import '../features/onboarding/screens/recovery_key_screen.dart';

class AppRouter {
  static const String welcome = '/welcome';
  static const String pinSetup = '/pin-setup';
  static const String recoveryKeySetup = '/recovery-key-setup';
  static const String home = '/home';
  static const String tablesList = '/tables';
  static const String tableDetail = '/table-detail';
  static const String settings = '/settings';
  static const String forgotPin = '/forgot-pin';
  static const String recoveryKeyEntry = '/recovery-key-entry';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case welcome:
        return _buildRoute(const WelcomeScreen());

      case pinSetup:
        final isFromSettings = routeSettings.arguments as bool? ?? false;
        return _buildRoute(PinSetupScreen(isFromSettings: isFromSettings));

      case recoveryKeySetup:
        final args = routeSettings.arguments;
        if (args is RecoveryKeyArgs) {
          return _buildRoute(RecoveryKeyScreen(
            recoveryWords: args.words,
            isFromSettings: args.isFromSettings,
          ));
        }
        // Fallback for old-style List<String> argument
        final words = args as List<String>;
        return _buildRoute(RecoveryKeyScreen(recoveryWords: words));

      case home:
        return _buildRoute(const EncryptDecryptScreen());

      case tablesList:
        return _buildRoute(const TablesListScreen());

      case tableDetail:
        final tableName = routeSettings.arguments as String;
        return _buildRoute(TableDetailScreen(tableName: tableName));

      case settings:
        return _buildRoute(const SettingsScreen());

      case forgotPin:
        return _buildRoute(const ForgotPinScreen());

      case recoveryKeyEntry:
        return _buildRoute(const RecoveryKeyEntryScreen());

      default:
        return _buildRoute(const EncryptDecryptScreen());
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}

/// Arguments class for recovery key screen
class RecoveryKeyArgs {
  final List<String> words;
  final bool isFromSettings;

  RecoveryKeyArgs({required this.words, this.isFromSettings = false});
}