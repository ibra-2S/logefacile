import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class VisitRequestsScreen extends ConsumerWidget {
  const VisitRequestsScreen({super.key});

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
          'Demandes de visite',
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
                stream: firestoreService.demandesRecues(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // filtre : cacher les demandes annulées qui n'étaient pas acceptées
                  final demandes =
                      (snapshot.data ?? [])
                          .where(
                            (d) =>
                                d.statut != StatutDemande.annulee ||
                                d.etaitAcceptee,
                          )
                          .toList();

                  if (demandes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📅', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 16),
                          Text(
                            'Aucune demande reçue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Les demandes de visite apparaîtront ici',
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
          // en-tête avec statut
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

          // nom du locataire
          if (demande.nomLocataire.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.bleuFonce,
                ),
                const SizedBox(width: 8),
                Text(
                  'Locataire : ${demande.nomLocataire}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // titre du bien
          if (demande.titreBien.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 16,
                  color: AppColors.bleuFonce,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bien : ${demande.titreBien}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaire,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

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
                'Date : ${_formaterDate(demande.dateProposee)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // date de la demande
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 16,
                color: AppColors.bleuFonce,
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

          // message du locataire
          if (demande.message != null && demande.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                demande.message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaire,
                ),
              ),
            ),
          ],

          // boutons d'action si en attente
          if (demande.estEnAttente) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _refuser(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.erreur),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(color: AppColors.erreur),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _accepter(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.succes,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _accepter() async {
    await firestoreService.mettreAJourStatutDemande(
      demande.id,
      StatutDemande.acceptee,
    );
  }

  Future<void> _refuser(BuildContext context) async {
    await firestoreService.mettreAJourStatutDemande(
      demande.id,
      StatutDemande.refusee,
    );
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à ${date.hour.toString().padLeft(2, '0')}h'
        '${date.minute.toString().padLeft(2, '0')}';
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
        label = demande.etaitAcceptee ? '🚫 Visite annulée' : '🚫 Annulée';
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
