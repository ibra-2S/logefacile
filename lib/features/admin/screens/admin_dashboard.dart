import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Administration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).deconnecter();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // en-tête admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.bleuFonce, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👑 Panneau Admin',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bienvenue, ${utilisateur?.nomComplet.split(' ').first ?? 'Admin'}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // statistiques globales
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                _CarteStatAdmin(
                  emoji: '👤',
                  label: 'Utilisateurs',
                  valeur: '—',
                  couleur: AppColors.bleuFonce,
                ),
                _CarteStatAdmin(
                  emoji: '🏠',
                  label: 'Biens publiés',
                  valeur: '—',
                  couleur: AppColors.vertProprietaire,
                ),
                _CarteStatAdmin(
                  emoji: '📅',
                  label: 'Visites',
                  valeur: '—',
                  couleur: AppColors.avertissement,
                ),
                _CarteStatAdmin(
                  emoji: '🚨',
                  label: 'Signalements',
                  valeur: '—',
                  couleur: AppColors.erreur,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // actions admin
            const Text(
              'Gestion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 12),
            _ActionAdmin(
              icon: Icons.people_outline,
              label: 'Gérer les utilisateurs',
              description: 'Voir, suspendre ou supprimer des comptes',
              onTap: () => context.push(AppRoutes.gestionUtilisateurs),
            ),
            const SizedBox(height: 12),
            _ActionAdmin(
              icon: Icons.flag_outlined,
              label: 'Signalements',
              description: 'Traiter les contenus signalés',
              onTap: () => context.push(AppRoutes.signalements),
            ),
            const SizedBox(height: 12),
            _ActionAdmin(
              icon: Icons.home_work_outlined,
              label: 'Tous les biens',
              description: 'Modérer les annonces publiées',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteStatAdmin extends StatelessWidget {
  final String emoji;
  final String label;
  final String valeur;
  final Color couleur;

  const _CarteStatAdmin({
    required this.emoji,
    required this.label,
    required this.valeur,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valeur,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: couleur,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaire,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionAdmin extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ActionAdmin({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bleuClair,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.bleuFonce, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaire,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grisMoyen),
          ],
        ),
      ),
    );
  }
}
