import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/auth/providers/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _rechercheCtrl = TextEditingController();
  String _villeSelectionnee = 'Conakry';
  String? _typeSelectionne;
  final double _prixMax = 5000000;

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

                  // barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _rechercheCtrl,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un quartier, une ville...',
                        hintStyle: const TextStyle(
                          color: AppColors.texteLeger,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.bleuFonce,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // filtres rapides
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // sélection de la ville
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _villes.map((ville) {
                            final estSelectionne = ville == _villeSelectionnee;
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _villeSelectionnee = ville,
                                  ),
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
                  const SizedBox(height: 12),

                  // types de biens
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
                  const SizedBox(height: 20),

                  // résultats
                  Row(
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
                        onPressed:
                            () => context.push(AppRoutes.mesDemandesVisite),
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Mes demandes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // liste vide pour l'instant
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Text('🏠', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.aucunBienTrouve,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Les logements disponibles\napparaîtront ici',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaire,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .deconnecter();
                            if (context.mounted) {
                              context.go(AppRoutes.connexion);
                            }
                          },
                          icon: const Icon(
                            Icons.logout,
                            color: AppColors.erreur,
                          ),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(color: AppColors.erreur),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.erreur),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
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
