import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.tousLesSignalements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final signalements = snapshot.data ?? [];

          if (signalements.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚨', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'Aucun signalement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tout est tranquille !',
                    style: TextStyle(color: AppColors.textSecondaire),
                  ),
                ],
              ),
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

          if (signalement['description'] != null) ...[
            Text(
              signalement['description'],
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaire,
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (!estTraite)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => firestoreService.marquerSignalementTraite(
                      signalement['id'],
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bleuFonce,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Marquer comme traité',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
