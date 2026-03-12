import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

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
          'Mes demandes de visite',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<VisitRequestModel>>(
                stream: firestoreService.demandesEnvoyees(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final demandes = snapshot.data ?? [];

                  if (demandes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📅', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 16),
                          Text(
                            'Aucune demande envoyée',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Vos demandes de visite apparaîtront ici',
                            style: TextStyle(color: AppColors.textSecondaire),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: demandes.length,
                    itemBuilder: (context, index) {
                      final demande = demandes[index];
                      return _CarteDemande(
                        demande: demande,
                        firestoreService: firestoreService,
                      );
                    },
                  );
                },
              ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final VisitRequestModel demande;
  final FirestoreService firestoreService;

  const _CarteDemande({required this.demande, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Demande de visite',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texte,
                ),
              ),
              _badgeStatut(demande.statut),
            ],
          ),
          const SizedBox(height: 12),

          // date proposée
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.bleuFonce,
              ),
              const SizedBox(width: 8),
              Text(
                'Visite le : ${_formaterDate(demande.dateProposee)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // date envoi
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 16,
                color: AppColors.texteLeger,
              ),
              const SizedBox(width: 8),
              Text(
                'Envoyée le : ${_formaterDate(demande.dateCreation)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.texteLeger,
                ),
              ),
            ],
          ),

          // bouton annuler si en attente
          if (demande.estEnAttente) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _annuler(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.erreur),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Annuler la demande',
                  style: TextStyle(color: AppColors.erreur),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _annuler() async {
    await firestoreService.mettreAJourStatutDemande(
      demande.id,
      StatutDemande.annulee,
    );
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _badgeStatut(StatutDemande statut) {
    Color couleur;
    String label;
    switch (statut) {
      case StatutDemande.enAttente:
        couleur = AppColors.avertissement;
        label = '⏳ En attente';
        break;
      case StatutDemande.acceptee:
        couleur = AppColors.succes;
        label = '✅ Acceptée';
        break;
      case StatutDemande.refusee:
        couleur = AppColors.erreur;
        label = '❌ Refusée';
        break;
      case StatutDemande.annulee:
        couleur = AppColors.grisMoyen;
        label = '🚫 Annulée';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}
