import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/admin/web/admin_web_app.dart';
import 'firebase_options.dart';

/// Point d'entrée dédié à la console d'administration (navigateur / PC).
///
/// Build   : flutter build web -t lib/main_admin.dart
/// Debug   : flutter run -d chrome -t lib/main_admin.dart
///
/// Volontairement minimal : pas de Firebase Messaging, pas de Google Maps,
/// pas de notifications locales — l'admin n'en a pas besoin et ces plugins
/// compliquent le build web.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: AdminWebApp()));
}
