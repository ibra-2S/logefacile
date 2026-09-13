import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/communes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/cloche_notifications.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/property_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

enum TriAnnonce { recentes, prixCroissant, prixDecroissant, populaires }

extension on TriAnnonce {
  String get label => switch (this) {
    TriAnnonce.recentes => 'Plus récentes',
    TriAnnonce.prixCroissant => 'Prix croissant',
    TriAnnonce.prixDecroissant => 'Prix décroissant',
    TriAnnonce.populaires => 'Plus populaires',
  };
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _rechercheCtrl = TextEditingController();
  final _firestoreService = FirestoreService();

  // incrémenté au "pull to refresh" pour relancer le flux Firestore
  int _nonce = 0;

  Future<void> _rafraichir() async {
    setState(() => _nonce++);
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  // tri et filtres (tous appliqués côté application)
  TriAnnonce _tri = TriAnnonce.recentes;
  String? _zone; // null = toutes les communes de Conakry
  String? _typeSelectionne; // null = tous les types
  double? _prixMax;
  int? _chambresMin;

  bool get _filtresActifs =>
      _tri != TriAnnonce.recentes ||
      _zone != null ||
      _typeSelectionne != null ||
      _prixMax != null ||
      _chambresMin != null;

  static const _types = <Map<String, String>>[
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

  String _formatPrix(num valeur) {
    final s = valeur.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  List<PropertyModel> _appliquerTriEtFiltres(List<PropertyModel> biens) {
    var resultat =
        biens.where((b) {
          // zone / commune : les biens qui renseignent leur commune sont
          // filtrés dessus ; les anciennes annonces sans commune renseignée
          // retombent sur une recherche texte pour rester trouvables.
          if (_zone != null) {
            final correspondCommune = b.commune == _zone;
            final correspondTexte =
                b.commune == null &&
                '${b.ville} ${b.quartier ?? ''} ${b.adresse}'
                    .toLowerCase()
                    .contains(_zone!.toLowerCase());
            if (!correspondCommune && !correspondTexte) return false;
          }
          // type
          if (_typeSelectionne != null && b.type.name != _typeSelectionne) {
            return false;
          }
          // prix
          if (_prixMax != null && b.prix > _prixMax!) return false;
          // chambres
          if (_chambresMin != null && (b.nombreChambres ?? 0) < _chambresMin!) {
            return false;
          }
          return true;
        }).toList();

    switch (_tri) {
      case TriAnnonce.recentes:
        resultat.sort((a, b) => b.datePublication.compareTo(a.datePublication));
      case TriAnnonce.prixCroissant:
        resultat.sort((a, b) => a.prix.compareTo(b.prix));
      case TriAnnonce.prixDecroissant:
        resultat.sort((a, b) => b.prix.compareTo(a.prix));
      case TriAnnonce.populaires:
        resultat.sort((a, b) => b.nombreVues.compareTo(a.nombreVues));
    }
    return resultat;
  }

  void _ouvrirTri() {
    var triTemp = _tri;
    var zoneTemp = _zone;
    var typeTemp = _typeSelectionne;
    var prixTemp = _prixMax;
    var chambresTemp = _chambresMin;

    const optionsPrix = <double?>[null, 1000000, 2000000, 3000000, 5000000];
    const optionsChambres = <int?>[null, 1, 2, 3];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheet) => Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.grisClair,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Trier et filtrer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _titreSection('Conakry et ses communes'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.fond,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: zoneTemp,
                              isExpanded: true,
                              hint: const Text('Toutes les communes'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Toutes les communes'),
                                ),
                                ...communesConakry.map(
                                  (c) => DropdownMenuItem<String?>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged: (v) => setSheet(() => zoneTemp = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _titreSection('Type de logement'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(
                              'Tous',
                              typeTemp == null,
                              () => setSheet(() => typeTemp = null),
                            ),
                            ..._types.map(
                              (t) => _chip(
                                t['label']!,
                                typeTemp == t['valeur'],
                                () => setSheet(() => typeTemp = t['valeur']),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _titreSection('Trier par'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              TriAnnonce.values
                                  .map(
                                    (t) => _chip(
                                      t.label,
                                      triTemp == t,
                                      () => setSheet(() => triTemp = t),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),

                        _titreSection('Prix maximum (GNF / mois)'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              optionsPrix
                                  .map(
                                    (p) => _chip(
                                      p == null
                                          ? 'Tous'
                                          : '≤ ${_formatPrix(p)}',
                                      prixTemp == p,
                                      () => setSheet(() => prixTemp = p),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),

                        _titreSection('Chambres (minimum)'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              optionsChambres
                                  .map(
                                    (c) => _chip(
                                      c == null ? 'Peu importe' : '$c +',
                                      chambresTemp == c,
                                      () => setSheet(() => chambresTemp = c),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setSheet(() {
                                    triTemp = TriAnnonce.recentes;
                                    zoneTemp = null;
                                    typeTemp = null;
                                    prixTemp = null;
                                    chambresTemp = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.grisMoyen,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Réinitialiser',
                                  style: TextStyle(color: AppColors.texte),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _tri = triTemp;
                                    _zone = zoneTemp;
                                    _typeSelectionne = typeTemp;
                                    _prixMax = prixTemp;
                                    _chambresMin = chambresTemp;
                                  });
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bleuFonce,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Appliquer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _titreSection(String texte) => Text(
    texte,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.texteLeger,
    ),
  );

  Widget _chip(String texte, bool actif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? AppColors.bleuFonce : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? AppColors.bleuFonce : AppColors.grisClair,
          ),
        ),
        child: Text(
          texte,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: actif ? Colors.white : AppColors.texte,
          ),
        ),
      ),
    );
  }

  void _ouvrirListeCommunes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grisClair,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisir une commune',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _optionCommune(
                            ctx,
                            label: 'Toutes les communes',
                            selectionnee: _zone == null,
                            onTap: () {
                              setState(() => _zone = null);
                              Navigator.pop(ctx);
                            },
                          ),
                          ...communesConakry.map(
                            (c) => _optionCommune(
                              ctx,
                              label: c,
                              selectionnee: _zone == c,
                              onTap: () {
                                setState(() => _zone = c);
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _optionCommune(
    BuildContext ctx, {
    required String label,
    required bool selectionnee,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selectionnee ? Icons.location_on : Icons.location_on_outlined,
        color: selectionnee ? AppColors.bleuFonce : AppColors.textSecondaire,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selectionnee ? FontWeight.w700 : FontWeight.w500,
          color: selectionnee ? AppColors.bleuFonce : AppColors.texte,
        ),
      ),
      trailing:
          selectionnee
              ? const Icon(Icons.check, color: AppColors.bleuFonce)
              : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Column(
        children: [
          // bannière de recherche
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              20,
            ),
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
                Row(
                  children: [
                    Expanded(
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (utilisateur != null)
                      ClocheNotifications(uid: utilisateur.uid),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                    ),
                    const SizedBox(width: 10),
                    // bouton tri / filtres
                    GestureDetector(
                      onTap: _ouvrirTri,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.tune, color: AppColors.bleuFonce),
                            if (_filtresActifs)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.erreur,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ligne commune + accès "Mes demandes" — ouvre juste la liste des
          // communes, pas le filtre complet (accessible via l'icône réglages)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _ouvrirListeCommunes,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppColors.textSecondaire,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _zone ?? 'Toutes les communes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texte,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (utilisateur != null)
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.mesDemandesVisite),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('Mes demandes'),
                  ),
              ],
            ),
          ),

          // liste des biens
          Expanded(
            child: StreamBuilder<List<PropertyModel>>(
              key: ValueKey(_nonce),
              stream: _firestoreService.rechercherBiens(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const PropertyListSkeleton();
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyState(
                            icone: Icons.error_outline,
                            titre: 'Impossible de charger les annonces',
                            message: '${snapshot.error}',
                            couleur: AppColors.erreur,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var biens = snapshot.data ?? [];

                if (_rechercheCtrl.text.isNotEmpty) {
                  final q = _rechercheCtrl.text.toLowerCase();
                  biens =
                      biens
                          .where(
                            (b) =>
                                b.titre.toLowerCase().contains(q) ||
                                b.adresse.toLowerCase().contains(q) ||
                                b.ville.toLowerCase().contains(q) ||
                                (b.quartier?.toLowerCase().contains(q) ??
                                    false) ||
                                (b.commune?.toLowerCase().contains(q) ?? false),
                          )
                          .toList();
                }

                biens = _appliquerTriEtFiltres(biens);

                // biens les plus consultés PARMI ceux qui correspondent aux
                // filtres actifs (commune, type, prix...) — le carrousel
                // s'adapte donc quand on choisit une commune.
                final vedettes =
                    ([...biens]..sort(
                      (a, b) => b.nombreVues.compareTo(a.nombreVues),
                    )).take(6).toList();

                if (biens.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vedettes.isNotEmpty)
                          _CarrouselVedettes(
                            vedettes: vedettes,
                            estInvite: utilisateur == null,
                          ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyState(
                            icone: Icons.travel_explore,
                            titre: 'Aucun logement trouvé',
                            message:
                                _filtresActifs || _rechercheCtrl.text.isNotEmpty
                                    ? 'Aucune annonce ne correspond à votre recherche. Essayez d\'élargir les filtres.'
                                    : 'Aucune annonce disponible pour le moment. Revenez bientôt !',
                            couleur: AppColors.tealLocataire,
                            action:
                                _filtresActifs || _rechercheCtrl.text.isNotEmpty
                                    ? OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _tri = TriAnnonce.recentes;
                                          _zone = null;
                                          _typeSelectionne = null;
                                          _prixMax = null;
                                          _chambresMin = null;
                                          _rechercheCtrl.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Réinitialiser'),
                                    )
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (vedettes.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _CarrouselVedettes(
                            vedettes: vedettes,
                            estInvite: utilisateur == null,
                          ),
                        ),

                      // séparation avant le fil complet des biens disponibles
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: AppColors.grisClair, height: 1),
                              SizedBox(height: 14),
                              Text(
                                'Tous nos biens disponibles',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.texte,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // biens disponibles, affichés deux par deux
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _CarteBienGrille(
                              key: ValueKey(biens[index].id),
                              bien: biens[index],
                              estInvite: utilisateur == null,
                            ),
                            childCount: biens.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ouvre la fiche détaillée d'un bien, ou invite l'invité à se connecter
/// s'il n'a pas de compte — partagé entre le fil principal et le carrousel
/// des biens en vedette.
void _ouvrirBienOuInviter(
  BuildContext context,
  PropertyModel bien,
  bool estInvite,
) {
  if (!estInvite) {
    context.push(AppRoutes.detailBien.replaceAll(':id', bien.id));
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: AppColors.bleuFonce,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Connectez-vous pour voir ce bien',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez un compte gratuit ou connectez-vous pour consulter '
                  'les détails, les photos et contacter le propriétaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaire,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.connexion);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bleuFonce,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutes.choixRole);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.bleuFonce),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Créer un compte",
                      style: TextStyle(
                        color: AppColors.bleuFonce,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// carte du fil principal, affichée deux par deux dans la grille : la photo
/// occupe toute la carte, le texte est incrusté par-dessus (même langage
/// visuel que la carte du carrousel « En ce moment »).
class _CarteBienGrille extends StatelessWidget {
  final PropertyModel bien;
  final bool estInvite;
  const _CarteBienGrille({
    super.key,
    required this.bien,
    required this.estInvite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ouvrirBienOuInviter(context, bien, estInvite),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'bienPhoto_${bien.id}',
                child: PropertyPhoto(
                  photos: bien.photos,
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1.0],
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bien.type.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bien.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bien.localisationCourte,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${bien.prix.toStringAsFixed(0)} GNF/mois',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// bandeau « En ce moment » : un seul carrousel, dans lequel les biens les
/// plus consultés défilent à tour de rôle (un seul visible à la fois,
/// défilement automatique + swipe manuel possible). Inséré comme premier
/// élément du fil pour qu'il défile avec les annonces au lieu de rester
/// fixé en haut de l'écran.
class _CarrouselVedettes extends StatefulWidget {
  final List<PropertyModel> vedettes;
  final bool estInvite;
  const _CarrouselVedettes({required this.vedettes, required this.estInvite});

  @override
  State<_CarrouselVedettes> createState() => _CarrouselVedettesState();
}

class _CarrouselVedettesState extends State<_CarrouselVedettes> {
  final _controller = PageController();
  Timer? _minuteur;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _demarrerMinuteur();
  }

  @override
  void didUpdateWidget(covariant _CarrouselVedettes oldWidget) {
    super.didUpdateWidget(oldWidget);
    // le flux Firestore peut faire varier le nombre de biens en vogue en
    // direct (nouvelle annonce, changement de tri) — on réajuste l'index
    // et on relance le minuteur en conséquence.
    if (oldWidget.vedettes.length != widget.vedettes.length) {
      if (widget.vedettes.isEmpty) {
        _index = 0;
      } else if (_index >= widget.vedettes.length) {
        _index = 0;
        if (_controller.hasClients) _controller.jumpToPage(0);
      }
      _demarrerMinuteur();
    }
  }

  void _demarrerMinuteur() {
    _minuteur?.cancel();
    _minuteur = null;
    if (widget.vedettes.length > 1) {
      _minuteur = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || widget.vedettes.length < 2) return;
        final suivant = (_index + 1) % widget.vedettes.length;
        _controller.animateToPage(
          suivant,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 En ce moment',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.vedettes.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder:
                  (context, i) => _CarteVedette(
                    key: ValueKey(widget.vedettes[i].id),
                    bien: widget.vedettes[i],
                    estInvite: widget.estInvite,
                  ),
            ),
          ),
          if (widget.vedettes.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.vedettes.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _index == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        _index == i ? AppColors.bleuFonce : AppColors.grisClair,
                    borderRadius: BorderRadius.circular(3),
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

/// carte plein écran (dans le carrousel) d'un bien en vogue — même règle
/// d'accès que le fil principal (invité redirigé vers la connexion).
class _CarteVedette extends StatelessWidget {
  final PropertyModel bien;
  final bool estInvite;
  const _CarteVedette({
    super.key,
    required this.bien,
    required this.estInvite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ouvrirBienOuInviter(context, bien, estInvite),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // la photo occupe toute la carte
              PropertyPhoto(
                photos: bien.photos,
                height: double.infinity,
                width: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
              // voile dégradé pour que le texte reste lisible sur la photo
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              // type de bien, en haut
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bien.type.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // texte incrusté sur la photo, en bas
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bien.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bien.localisationCourte,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${bien.prix.toStringAsFixed(0)} GNF/mois',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
