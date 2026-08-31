import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _afficherTraites = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Signalements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          // toggle afficher traités
          Row(
            children: [
              const Text(
                'Traités',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Switch(
                value: _afficherTraites,
                onChanged: (val) => setState(() => _afficherTraites = val),
                activeColor: Colors.white,
                activeTrackColor: Colors.white30,
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.tousLesSignalements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTileSkeleton();
          }

          var signalements = snapshot.data ?? [];

          // filtrer selon le toggle
          if (!_afficherTraites) {
            signalements =
                signalements.where((s) => s['traite'] != true).toList();
          }

          if (signalements.isEmpty) {
            return EmptyState(
              icone: Icons.verified_user_outlined,
              titre:
                  _afficherTraites
                      ? 'Aucun signalement'
                      : 'Aucun signalement en attente',
              message: 'Tout est tranquille, rien à modérer pour le moment.',
              couleur: AppColors.succes,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: signalements.length,
            itemBuilder: (context, index) {
              final s = signalements[index];
              return _CarteSignalement(
                signalement: s,
                firestoreService: firestoreService,
              );
            },
          );
        },
      ),
    );
  }
}

class _CarteSignalement extends StatelessWidget {
  final Map<String, dynamic> signalement;
  final FirestoreService firestoreService;

  const _CarteSignalement({
    required this.signalement,
    required this.firestoreService,
  });

  String _formaterDate(dynamic date) {
    if (date == null) return 'Date inconnue';
    if (date is Timestamp) {
      final d = date.toDate();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} à ${d.hour.toString().padLeft(2, '0')}h'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    final estTraite = signalement['traite'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              estTraite
                  ? AppColors.grisClair
                  : AppColors.erreur.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // en-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    signalement['type'] ?? 'Signalement',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      estTraite
                          ? AppColors.succes.withValues(alpha: 0.1)
                          : AppColors.erreur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estTraite ? '✅ Traité' : '⏳ En attente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: estTraite ? AppColors.succes : AppColors.erreur,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // description
          if (signalement['description'] != null &&
              signalement['description'].toString().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fond,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                signalement['description'],
                style: const TextStyle(fontSize: 13, color: AppColors.texte),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // infos supplémentaires
          if (signalement['bienId'] != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 14,
                  color: AppColors.textSecondaire,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bien : ${signalement['bienId'].toString().substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          if (signalement['signalePar'] != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textSecondaire,
                ),
                const SizedBox(width: 6),
                Text(
                  'Signalé par : ${signalement['signalePar'].toString().substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: AppColors.texteLeger,
              ),
              const SizedBox(width: 6),
              Text(
                _formaterDate(signalement['dateCreation']),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.texteLeger,
                ),
              ),
            ],
          ),

          // bouton marquer traité
          if (!estTraite) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    () => firestoreService.marquerSignalementTraite(
                      signalement['id'],
                    ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Marquer comme traité',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bleuFonce,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
