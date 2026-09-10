import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'admin_web_router.dart';

/// Racine de la console d'administration web.
class AdminWebApp extends ConsumerWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeur = ref.watch(adminRouteurProvider);

    return MaterialApp.router(
      title: 'LogeFacile — Administration',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _WebScrollBehavior(),
      theme: ThemeData(
        colorSchemeSeed: AppColors.bleuFonce,
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.fond,
      ),
      routerConfig: routeur,
    );
  }
}

/// Permet le défilement à la souris / au trackpad (par défaut Flutter web
/// n'accepte pas le drag souris sur les listes).
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
