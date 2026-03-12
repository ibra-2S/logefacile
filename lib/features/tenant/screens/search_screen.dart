import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _rechercheCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  String _villeSelectionnee = 'Conakry';
  String? _typeSelectionne;

  final List<String> _villes = [
    'Conakry',
    'Kindia',
    'Labé',
    'Kankan',
    'Nzérékoré',
    'Mamou',
  ];

  final List<Map<String, String>> _types = [
    {'valeur': 'maison', 'label': '🏠 Maison'},
    {'valeur': 'appartement', 'label': '🏢 Appartement'},
    {'valeur': 'chambre', 'label': '🛏️ Chambre'},
    {'valeur': 'studio', 'label': '🪟 Studio'},
  ];

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

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
            icon: const Icon(Icons.favorite_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.mesFavoris),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.conversations),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.push(AppRoutes.profil),
          ),
        ],
      ),
      body: Column(
        children: [
          // bannière de recherche
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bleuFonce, AppColors.tealLocataire],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${utilisateur?.nomComplet.split(' ').first ?? ''} 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Trouvez votre logement idéal',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _rechercheCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un quartier, une ville...',
                      hintStyle: TextStyle(
                        color: AppColors.texteLeger,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.bleuFonce,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // villes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _villes.map((ville) {
                          final estSelectionne = ville == _villeSelectionnee;
                          return GestureDetector(
                            onTap:
                                () =>
                                    setState(() => _villeSelectionnee = ville),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    estSelectionne
                                        ? AppColors.bleuFonce
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      estSelectionne
                                          ? AppColors.bleuFonce
                                          : AppColors.grisClair,
                                ),
                              ),
                              child: Text(
                                ville,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      estSelectionne
                                          ? Colors.white
                                          : AppColors.texte,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // types
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _types.map((type) {
                          final estSelectionne =
                              type['valeur'] == _typeSelectionne;
                          return GestureDetector(
                            onTap:
                                () => setState(() {
                                  _typeSelectionne =
                                      estSelectionne ? null : type['valeur'];
                                }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    estSelectionne
                                        ? AppColors.tealLocataire
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      estSelectionne
                                          ? AppColors.tealLocataire
                                          : AppColors.grisClair,
                                ),
                              ),
                              child: Text(
                                type['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      estSelectionne
                                          ? Colors.white
                                          : AppColors.texte,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // titre résultats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logements disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texte,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.mesDemandesVisite),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Mes demandes'),
                ),
              ],
            ),
          ),

          // liste des biens depuis Firestore
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              stream: _firestoreService.rechercherBiens(
                ville: _villeSelectionnee,
                type:
                    _typeSelectionne != null
                        ? TypeBien.values.firstWhere(
                          (t) => t.name == _typeSelectionne,
                        )
                        : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var biens = snapshot.data ?? [];

                // filtre texte local
                if (_rechercheCtrl.text.isNotEmpty) {
                  final q = _rechercheCtrl.text.toLowerCase();
                  biens =
                      biens
                          .where(
                            (b) =>
                                b.titre.toLowerCase().contains(q) ||
                                b.adresse.toLowerCase().contains(q) ||
                                (b.quartier?.toLowerCase().contains(q) ??
                                    false),
                          )
                          .toList();
                }

                if (biens.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🏠', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 16),
                        Text(
                          'Aucun logement trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Essayez d\'autres filtres',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaire,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: biens.length,
                  itemBuilder: (context, index) {
                    final bien = biens[index];
                    return _CarteBien(bien: bien);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteBien extends StatelessWidget {
  final PropertyModel bien;
  const _CarteBien({required this.bien});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
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
              padding: const EdgeInsets.all(14),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondaire,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bien.quartier ?? ''} — ${bien.ville}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaire,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${bien.prix.toStringAsFixed(0)} GNF/mois',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealLocataire,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bleuClair,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bien.type.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.bleuFonce,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
