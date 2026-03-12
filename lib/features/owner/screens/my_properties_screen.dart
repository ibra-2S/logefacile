import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class MyPropertiesScreen extends ConsumerWidget {
  const MyPropertiesScreen({super.key});

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
          'Mes biens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push(AppRoutes.ajouterBien),
          ),
        ],
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<PropertyModel>>(
                stream: firestoreService.biensDuProprietaire(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final biens = snapshot.data ?? [];

                  if (biens.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏠', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun bien publié',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Publiez votre premier logement',
                            style: TextStyle(color: AppColors.textSecondaire),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed:
                                () => context.push(AppRoutes.ajouterBien),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Publier un bien',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.vertProprietaire,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: biens.length,
                    itemBuilder: (context, index) {
                      final bien = biens[index];
                      return _CarteBien(bien: bien);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.ajouterBien),
        backgroundColor: AppColors.vertProprietaire,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CarteBien extends StatelessWidget {
  final PropertyModel bien;

  const _CarteBien({required this.bien});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image ou placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.bleuClair,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              image:
                  bien.photos.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(bien.photos.first),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                bien.photos.isEmpty
                    ? const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 48)),
                    )
                    : null,
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // titre et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bien.titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _badgeStatut(bien.statut),
                  ],
                ),
                const SizedBox(height: 6),

                // localisation
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondaire,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${bien.quartier ?? ''} ${bien.ville}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaire,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // prix et stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${bien.prix.toStringAsFixed(0)} GNF/mois',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vertProprietaire,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: AppColors.texteLeger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bien.nombreVues} vues',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.texteLeger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.favorite_outline,
                          size: 14,
                          color: AppColors.texteLeger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bien.nombreFavoris}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.texteLeger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatut(StatutBien statut) {
    Color couleur;
    String label;
    switch (statut) {
      case StatutBien.disponible:
        couleur = AppColors.succes;
        label = 'Disponible';
        break;
      case StatutBien.loue:
        couleur = AppColors.avertissement;
        label = 'Loué';
        break;
      case StatutBien.suspendu:
        couleur = AppColors.erreur;
        label = 'Suspendu';
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
