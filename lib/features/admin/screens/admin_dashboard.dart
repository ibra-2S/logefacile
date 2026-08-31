import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bleuFonce, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/icone.png', height: 32, width: 32),
            const SizedBox(width: 8),
            const Text(
              'Administration',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.profil),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).deconnecter();
              if (context.mounted) context.go(AppRoutes.connexion);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.tousLesUtilisateurs(),
        builder: (context, snapshotUsers) {
          return StreamBuilder<List<PropertyModel>>(
            stream: firestoreService.rechercherBiens(),
            builder: (context, snapshotBiens) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestoreService.tousLesSignalements(),
                builder: (context, snapshotSignalements) {
                  final users = snapshotUsers.data ?? [];
                  final biens = snapshotBiens.data ?? [];
                  final signalements = snapshotSignalements.data ?? [];
                  final signalementsEnAttente =
                      signalements.where((s) => s['traite'] != true).length;

                  return SingleChildScrollView(
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // statistiques réelles
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
                          children: [
                            _CarteStatAdmin(
                              emoji: '👤',
                              label: 'Utilisateurs',
                              valeur: '${users.length}',
                              couleur: AppColors.bleuFonce,
                            ),
                            _CarteStatAdmin(
                              emoji: '🏠',
                              label: 'Biens publiés',
                              valeur: '${biens.length}',
                              couleur: AppColors.vertProprietaire,
                            ),
                            _CarteStatAdmin(
                              emoji: '✅',
                              label: 'Biens disponibles',
                              valeur:
                                  '${biens.where((b) => b.estDisponible).length}',
                              couleur: AppColors.tealLocataire,
                            ),
                            _CarteStatAdmin(
                              emoji: '🚨',
                              label: 'Signalements',
                              valeur: '$signalementsEnAttente',
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
                          description:
                              'Voir, suspendre ou supprimer des comptes',
                          badge: users.length,
                          onTap:
                              () => context.push(AppRoutes.gestionUtilisateurs),
                        ),
                        const SizedBox(height: 12),
                        _ActionAdmin(
                          icon: Icons.flag_outlined,
                          label: 'Signalements',
                          description: 'Traiter les contenus signalés',
                          badge: signalementsEnAttente,
                          onTap: () => context.push(AppRoutes.signalements),
                        ),
                        const SizedBox(height: 12),
                        _ActionAdmin(
                          icon: Icons.home_work_outlined,
                          label: 'Tous les biens',
                          description: 'Modérer les annonces publiées',
                          badge: biens.length,
                          onTap: () => context.push('/admin/biens'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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
  final int badge;

  const _ActionAdmin({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.badge = 0,
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
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bleuFonce,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.grisMoyen),
          ],
        ),
      ),
    );
  }
}
