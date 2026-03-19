import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    // ProviderScope nécessaire pour Riverpod
    const ProviderScope(child: LogeFacile()),
  );
}

class LogeFacile extends ConsumerWidget {
  const LogeFacile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeur = ref.watch(routeurApp);
    return MaterialApp.router(
      title: 'LogeFacile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6F80FA),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      routerConfig: routeur,
    );
  }
}
