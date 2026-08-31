import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';

class AdminPropertiesScreen extends ConsumerStatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  ConsumerState<AdminPropertiesScreen> createState() =>
      _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends ConsumerState<AdminPropertiesScreen> {
  final _rechercheCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  String? _filtreStatut;

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Tous les biens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // barre de recherche
          Container(
            color: AppColors.bleuFonce,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _rechercheCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un bien...',
                hintStyle: const TextStyle(
                  color: AppColors.texteLeger,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.bleuFonce,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // filtres statut
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filtreChip('Tous', null),
                  const SizedBox(width: 8),
                  _filtreChip('Disponible', 'disponible'),
                  const SizedBox(width: 8),
                  _filtreChip('Loué', 'loue'),
                  const SizedBox(width: 8),
                  _filtreChip('Suspendu', 'suspendu'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // liste des biens
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              stream: _firestoreService.tousLesBiens(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PropertyListSkeleton();
                }

                var biens = snapshot.data ?? [];

                // filtre recherche
                if (_rechercheCtrl.text.isNotEmpty) {
                  final q = _rechercheCtrl.text.toLowerCase();
                  biens =
                      biens
                          .where(
                            (b) =>
                                b.titre.toLowerCase().contains(q) ||
                                b.ville.toLowerCase().contains(q) ||
                                (b.quartier?.toLowerCase().contains(q) ??
                                    false),
                          )
                          .toList();
                }

                // filtre statut
                if (_filtreStatut != null) {
                  biens =
                      biens
                          .where((b) => b.statut.name == _filtreStatut)
                          .toList();
                }

                if (biens.isEmpty) {
                  return const EmptyState(
                    icone: Icons.home_work_outlined,
                    titre: 'Aucun bien trouvé',
                    message:
                        'Aucune annonce ne correspond à votre recherche ou '
                        'à ce filtre.',
                    couleur: AppColors.violetAdmin,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: biens.length,
                  itemBuilder: (context, index) {
                    final bien = biens[index];
                    return _CarteBienAdmin(
                      bien: bien,
                      firestoreService: _firestoreService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtreChip(String label, String? valeur) {
    final estSelectionne = _filtreStatut == valeur;
    return GestureDetector(
      onTap: () => setState(() => _filtreStatut = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? AppColors.bleuFonce : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: estSelectionne ? AppColors.bleuFonce : AppColors.grisClair,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: estSelectionne ? Colors.white : AppColors.texte,
          ),
        ),
      ),
    );
  }
}

class _CarteBienAdmin extends StatelessWidget {
  final PropertyModel bien;
  final FirestoreService firestoreService;

  const _CarteBienAdmin({required this.bien, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          // photo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.bleuClair,
              borderRadius: BorderRadius.circular(10),
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
                      child: Text('🏠', style: TextStyle(fontSize: 28)),
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bien.titre,
                  style: const TextStyle(
                    fontSize: 14,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${bien.prix.toStringAsFixed(0)} GNF/mois',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vertProprietaire,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _badgeStatut(bien.statut),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 12,
                      color: AppColors.texteLeger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${bien.nombreVues} vues',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.texteLeger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.favorite_outline,
                      size: 12,
                      color: AppColors.texteLeger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${bien.nombreFavoris}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.texteLeger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // action supprimer
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.grisMoyen),
            onSelected: (valeur) async {
              if (valeur == 'supprimer') {
                final confirme = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Supprimer ce bien ?'),
                        content: const Text('Cette action est irréversible.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.erreur,
                            ),
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                );
                if (confirme == true) {
                  await firestoreService.supprimerBien(bien.id);
                }
              } else if (valeur == 'suspendre') {
                await firestoreService.modifierBien(bien.id, {
                  'statut': 'suspendu',
                  'estDisponible': false,
                });
              } else if (valeur == 'disponible') {
                await firestoreService.modifierBien(bien.id, {
                  'statut': 'disponible',
                  'estDisponible': true,
                });
              }
            },
            itemBuilder:
                (context) => [
                  if (bien.statut == StatutBien.suspendu)
                    const PopupMenuItem(
                      value: 'disponible',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.succes,
                          ),
                          SizedBox(width: 8),
                          Text('Rendre disponible'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'suspendre',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: AppColors.avertissement),
                          SizedBox(width: 8),
                          Text('Suspendre'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.erreur),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: AppColors.erreur),
                        ),
                      ],
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: couleur,
        ),
      ),
    );
  }
}
