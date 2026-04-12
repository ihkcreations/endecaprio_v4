// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app.dart';
import 'core/utils/desktop_window.dart';
import 'data/database/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup desktop window if running on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await setupDesktopWindow();
  }

  // Initialize database
  await LocalDatabase.instance.database;

  runApp(
    const ProviderScope(
      child: EnDecaprioApp(),
    ),
  );
}