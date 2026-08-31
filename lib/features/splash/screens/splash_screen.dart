import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _dejaRedirige = false;

  void _rediriger(UserModel? utilisateur) {
    if (!mounted || _dejaRedirige) return;
    _dejaRedirige = true;

    if (utilisateur == null) {
      context.go(AppRoutes.connexion);
      return;
    }

    switch (utilisateur.role) {
      case UserRole.proprietaire:
      case UserRole.agent:
        context.go(AppRoutes.tableauBordProprietaire);
      case UserRole.locataire:
        context.go(AppRoutes.rechercheLocataire);
      case UserRole.admin:
        context.go(AppRoutes.tableauBordAdmin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    authState.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          Future.microtask(() async {
            final vu = await PrefsService.onboardingVu();
            if (!mounted || _dejaRedirige) return;
            _dejaRedirige = true;
            context.go(vu ? AppRoutes.connexion : AppRoutes.onboarding);
          });
        } else {
          Future.microtask(() async {
            if (!mounted || _dejaRedirige) return;
            final utilisateur = await ref.read(
              utilisateurActuelProvider.future,
            );
            _rediriger(utilisateur);
          });
        }
      },
      loading: () {},
      error: (_, __) {
        Future.microtask(() {
          if (mounted && !_dejaRedirige) {
            _dejaRedirige = true;
            context.go(AppRoutes.connexion);
          }
        });
      },
    );

    // squelette pendant que Firebase récupère la session et le profil
    return const ScreenSkeleton();
  }
}
