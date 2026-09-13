// lib/core/widgets/guest_locked_view.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_strings.dart';

/// Écran affiché dans un onglet réservé aux comptes connectés, quand
/// l'application est utilisée en mode invité (sans compte).
class GuestLockedView extends StatelessWidget {
  final String message;

  const GuestLockedView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.bleuFonce.withValues(alpha: 0.16),
                              AppColors.bleuFonce.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 26,
                        child: _pastille(AppColors.bleuFonce.withValues(alpha: 0.35), 14),
                      ),
                      Positioned(
                        bottom: 22,
                        left: 16,
                        child: _pastille(AppColors.bleuFonce.withValues(alpha: 0.2), 22),
                      ),
                      Positioned(
                        bottom: 46,
                        right: 10,
                        child: _pastille(AppColors.bleuFonce.withValues(alpha: 0.15), 10),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 190,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Connectez-vous ci-dessous',
                  style: TextStyle(fontSize: 13, color: AppColors.texteLeger),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.connexion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bleuFonce,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      AppStrings.seConnecter,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pastille(Color couleur, double taille) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
  );
}
