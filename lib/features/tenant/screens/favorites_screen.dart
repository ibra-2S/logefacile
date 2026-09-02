import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/property_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

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
          'Mes favoris',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<String>>(
                stream: firestoreService.favorisLocataire(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTileSkeleton();
                  }

                  final bienIds = snapshot.data ?? [];

                  if (bienIds.isEmpty) {
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
                              icone: Icons.favorite_border,
                              titre: 'Aucun favori',
                              message:
                                  'Appuyez sur le cœur d\'une annonce pour la '
                                  'retrouver ici et la comparer plus tard.',
                              couleur: AppColors.erreur,
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
                      itemCount: bienIds.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder<PropertyModel?>(
                          stream: firestoreService.getBienParId(
                            bienIds[index],
                          ),
                          builder: (context, bienSnapshot) {
                            final bien = bienSnapshot.data;
                            if (bien == null) return const SizedBox.shrink();
                            return _CarteFavori(
                              bien: bien,
                              locataireId: utilisateur.uid,
                              firestoreService: firestoreService,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}

class _CarteFavori extends StatelessWidget {
  final PropertyModel bien;
  final String locataireId;
  final FirestoreService firestoreService;

  const _CarteFavori({
    required this.bien,
    required this.locataireId,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => context.push(AppRoutes.detailBien.replaceAll(':id', bien.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // image
            PropertyPhoto(
              photos: bien.photos,
              height: 110,
              width: 110,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),

            // infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bien.titre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bien.quartier ?? ''} — ${bien.ville}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaire,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${bien.prix.toStringAsFixed(0)} GNF/mois',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vertProprietaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // bouton retirer favori
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed:
                  () => firestoreService.retirerFavori(locataireId, bien.id),
            ),
          ],
        ),
      ),
    );
  }
}
