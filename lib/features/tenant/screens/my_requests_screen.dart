import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
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
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<VisitRequestModel>>(
                stream: firestoreService.demandesEnvoyees(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTileSkeleton();
                  }

                  final demandes = snapshot.data ?? [];

                  if (demandes.isEmpty) {
                    return RefreshIndicator(
                      onRefresh:
                          () => Future<void>.delayed(
                            const Duration(milliseconds: 600),
                          ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: const EmptyState(
                              icone: Icons.event_available,
                              titre: 'Aucune demande de visite',
                              message:
                                  'Trouvez un logement qui vous plaît et '
                                  'demandez une visite : elle apparaîtra ici '
                                  'avec son statut.',
                              couleur: AppColors.bleuFonce,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh:
                        () => Future<void>.delayed(
                          const Duration(milliseconds: 600),
                        ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: demandes.length,
                      itemBuilder: (context, index) {
                        final demande = demandes[index];
                        return _CarteDemande(
                          demande: demande,
                          firestoreService: firestoreService,
                        );
                      },
                    ),
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // nom du propriétaire
          if (demande.nomProprietaire.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.bleuFonce,
                ),
                const SizedBox(width: 8),
                Text(
                  'Propriétaire : ${demande.nomProprietaire}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaire,
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
                'Visite le : ${_formaterDateHeure(demande.dateProposee)}',
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

          // raison du refus
          if (demande.estRefusee &&
              demande.raisonRefus != null &&
              demande.raisonRefus!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.erreur.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.erreur.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.erreur,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motif : ${demande.raisonRefus}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.erreur,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // bouton annuler si en attente ou acceptée
          if (demande.estEnAttente || demande.estAcceptee) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _annuler(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.erreur),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  demande.estAcceptee
                      ? 'Annuler le rendez-vous'
                      : 'Annuler la demande',
                  style: const TextStyle(color: AppColors.erreur),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _annuler(BuildContext context) async {
    // confirmation avant annulation
    final confirme = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              demande.estAcceptee
                  ? 'Annuler le rendez-vous ?'
                  : 'Annuler la demande ?',
            ),
            content: Text(
              demande.estAcceptee
                  ? 'Le propriétaire sera informé de l\'annulation du rendez-vous.'
                  : 'Cette demande sera supprimée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Non'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Oui, annuler',
                  style: TextStyle(color: AppColors.erreur),
                ),
              ),
            ],
          ),
    );

    if (confirme != true) return;

    if (demande.estAcceptee) {
      // rendez-vous accepté → marquer comme annulé avec etaitAcceptee=true
      // le propriétaire verra la demande comme annulée
      await firestoreService.mettreAJourStatutDemande(
        demande.id,
        StatutDemande.annulee,
        etaitAcceptee: true,
      );
    } else {
      // demande en attente → supprimer complètement
      // le propriétaire ne verra plus rien
      await firestoreService.supprimerDemande(demande.id);
    }
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formaterDateHeure(DateTime date) {
    return '${_formaterDate(date)} à '
        '${date.hour.toString().padLeft(2, '0')}h'
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
