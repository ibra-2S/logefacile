import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // attendre 2.5 secondes puis rediriger
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _rediriger();
    });
  }

  void _rediriger() {
    final authState = ref.read(authStateProvider);
    final user = authState.asData?.value;

    if (user == null) {
      context.go(AppRoutes.connexion);
      return;
    }

    // récupérer le rôle et rediriger
    ref.read(utilisateurActuelProvider.future).then((utilisateur) {
      if (!mounted) return;
      if (utilisateur == null) {
        context.go(AppRoutes.connexion);
        return;
      }
      switch (utilisateur.role) {
        case UserRole.proprietaire:
        case UserRole.agent:
          context.go(AppRoutes.tableauBordProprietaire);
          break;
        case UserRole.locataire:
          context.go(AppRoutes.rechercheLocataire);
          break;
        case UserRole.admin:
          context.go(AppRoutes.tableauBordAdmin);
          break;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      // indicateur de chargement
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
