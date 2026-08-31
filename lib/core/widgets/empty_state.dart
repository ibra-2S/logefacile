import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// État vide illustré et réutilisable.
class EmptyState extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String message;
  final Widget? action;
  final Color couleur;

  const EmptyState({
    super.key,
    required this.icone,
    required this.titre,
    required this.message,
    this.action,
    this.couleur = AppColors.bleuFonce,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Illustration(icone: icone, couleur: couleur),
            const SizedBox(height: 28),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondaire,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  const _Illustration({required this.icone, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // halo
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  couleur.withValues(alpha: 0.12),
                  couleur.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          // pastilles décoratives
          Positioned(
            top: 6,
            right: 18,
            child: _pastille(couleur.withValues(alpha: 0.35), 10),
          ),
          Positioned(
            bottom: 14,
            left: 12,
            child: _pastille(couleur.withValues(alpha: 0.2), 16),
          ),
          Positioned(
            bottom: 30,
            right: 6,
            child: _pastille(couleur.withValues(alpha: 0.15), 7),
          ),
          // cercle central + icône
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icone, size: 38, color: couleur),
          ),
        ],
      ),
    );
  }

  Widget _pastille(Color c, double taille) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
