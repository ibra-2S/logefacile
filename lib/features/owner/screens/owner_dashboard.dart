import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'LogeFacile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.profil),
          ),
        ],
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<PropertyModel>>(
                stream: firestoreService.biensDuProprietaire(utilisateur.uid),
                builder: (context, snapshotBiens) {
                  return StreamBuilder<List<VisitRequestModel>>(
                    stream: firestoreService.demandesRecues(utilisateur.uid),
                    builder: (context, snapshotDemandes) {
                      final biens = snapshotBiens.data ?? [];
                      final demandes = snapshotDemandes.data ?? [];

                      // calcul des vues totales
                      final vuesTotales = biens.fold<int>(
                        0,
                        (total, b) => total + b.nombreVues,
                      );

                      // demandes
                      final demandesTotales = demandes.length;
                      final demandesNonTraitees =
                          demandes.where((d) => d.estEnAttente).length;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // carte bonjour
                            _carteBonjour(
                              utilisateur.nomComplet.split(' ').first,
                            ),
                            const SizedBox(height: 24),

                            // statistiques réelles
                            const Text(
                              'Vue d\'ensemble',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.texte,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _carteStatistique(
                                    '${biens.length}',
                                    'Biens publiés',
                                    Icons.home_outlined,
                                    AppColors.vertProprietaire,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _carteStatistique(
                                    '$demandesTotales',
                                    'Demandes reçues',
                                    Icons.calendar_today_outlined,
                                    AppColors.bleuMoyen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _carteStatistique(
                                    '${biens.where((b) => b.statut == StatutBien.loue).length}',
                                    'Biens loués',
                                    Icons.check_circle_outline,
                                    AppColors.tealLocataire,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _carteStatistique(
                                    '$vuesTotales',
                                    'Vues totales',
                                    Icons.visibility_outlined,
                                    AppColors.violetAdmin,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _carteStatistique(
                                    '$demandesNonTraitees',
                                    'Demandes en attente',
                                    Icons.hourglass_empty_outlined,
                                    AppColors.avertissement,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // actions rapides
                            const Text(
                              'Actions rapides',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.texte,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _carteAction(
                              context,
                              emoji: '➕',
                              titre: 'Publier un bien',
                              description:
                                  'Ajouter un nouveau logement à louer',
                              couleur: AppColors.vertProprietaire,
                              onTap: () => context.push(AppRoutes.ajouterBien),
                            ),
                            const SizedBox(height: 10),
                            _carteAction(
                              context,
                              emoji: '🏠',
                              titre: 'Mes biens',
                              description: 'Gérer vos logements publiés',
                              couleur: AppColors.bleuMoyen,
                              onTap: () => context.push(AppRoutes.mesBiens),
                            ),
                            const SizedBox(height: 10),
                            _carteAction(
                              context,
                              emoji: '📅',
                              titre: 'Demandes de visite',
                              description: 'Voir et gérer les demandes reçues',
                              couleur: AppColors.tealLocataire,
                              onTap:
                                  () => context.push(AppRoutes.demandesVisite),
                            ),
                            const SizedBox(height: 10),
                            _carteAction(
                              context,
                              emoji: '💬',
                              titre: 'Messages',
                              description:
                                  'Vos conversations avec les locataires',
                              couleur: AppColors.violetAdmin,
                              onTap:
                                  () => context.push(AppRoutes.conversations),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _carteBonjour(String prenom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.bleuFonce, AppColors.bleuMoyen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, $prenom 👋',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gérez vos biens immobiliers',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _carteStatistique(
    String valeur,
    String label,
    IconData icone,
    Color couleur,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Icon(icone, color: couleur, size: 28),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
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
    );
  }

  Widget _carteAction(
    BuildContext context, {
    required String emoji,
    required String titre,
    required String description,
    required Color couleur,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.erreur,
                  shape: BoxShape.circle,
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
              Icon(Icons.arrow_forward_ios, size: 14, color: couleur),
          ],
        ),
      ),
    );
  }
}
