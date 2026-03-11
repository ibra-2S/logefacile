import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Je suis...',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez votre profil pour continuer',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // carte propriétaire
              _CarteRole(
                emoji: '🏠',
                titre: 'Propriétaire',
                description: 'Je publie et gère mes biens immobiliers',
                couleur: const Color(0xFF2E7D32),
                onTap:
                    () => context.push(
                      AppRoutes.inscription,
                      extra: UserRole.proprietaire,
                    ),
              ),
              const SizedBox(height: 16),

              // carte agent
              _CarteRole(
                emoji: '🤝',
                titre: 'Agent immobilier',
                description:
                    'Je gère des biens pour le compte de propriétaires',
                couleur: const Color(0xFF1565C0),
                onTap:
                    () => context.push(
                      AppRoutes.inscription,
                      extra: UserRole.agent,
                    ),
              ),
              const SizedBox(height: 16),

              // carte locataire
              _CarteRole(
                emoji: '🔍',
                titre: 'Locataire',
                description: 'Je recherche un logement à louer',
                couleur: const Color(0xFF00695C),
                onTap:
                    () => context.push(
                      AppRoutes.inscription,
                      extra: UserRole.locataire,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteRole extends StatelessWidget {
  final String emoji;
  final String titre;
  final String description;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteRole({
    required this.emoji,
    required this.titre,
    required this.description,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // icône colorée
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),

            // texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: couleur,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // flèche
            Icon(Icons.arrow_forward_ios, size: 16, color: couleur),
          ],
        ),
      ),
    );
  }
}
