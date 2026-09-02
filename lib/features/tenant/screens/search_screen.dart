import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
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

  static const _communesConakry = <String>[
    'Kaloum',
    'Dixinn',
    'Ratoma',
    'Matam',
    'Matoto',
    'Lambanyi',
    'Sonfonia',
    'Gbessia',
    'Kagbélén',
    'Sanoyah',
    'Manéah',
    'Tombolia',
  ];

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
          // zone / commune
          if (_zone != null) {
            final texte =
                '${b.ville} ${b.quartier ?? ''} ${b.adresse}'.toLowerCase();
            if (!texte.contains(_zone!.toLowerCase())) return false;
          }
          // type
          if (_typeSelectionne != null && b.type.name != _typeSelectionne) {
            return false;
          }
          // prix
          if (_prixMax != null && b.prix > _prixMax!) return false;
          // chambres
          if (_chambresMin != null &&
              (b.nombreChambres ?? 0) < _chambresMin!) {
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
                                ..._communesConakry.map(
                                  (c) => DropdownMenuItem<String?>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (v) => setSheet(() => zoneTemp = v),
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
                                () => setSheet(
                                  () => typeTemp = t['valeur'],
                                ),
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

  String _resumeFiltres() {
    final parts = <String>[];
    parts.add(_zone ?? 'Toutes les communes');
    if (_typeSelectionne != null) {
      parts.add(
        _types.firstWhere((t) => t['valeur'] == _typeSelectionne)['label']!,
      );
    }
    if (_tri != TriAnnonce.recentes) parts.add(_tri.label);
    return parts.join('  ·  ');
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
                            style: TextStyle(color: Colors.white70, fontSize: 13),
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
                            const Icon(
                              Icons.tune,
                              color: AppColors.bleuFonce,
                            ),
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

          // ligne résumé filtres + accès "Mes demandes"
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _ouvrirTri,
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
                            _resumeFiltres(),
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
                                    false),
                          )
                          .toList();
                }

                biens = _appliquerTriEtFiltres(biens);

                if (biens.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
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
                                _filtresActifs ||
                                        _rechercheCtrl.text.isNotEmpty
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: biens.length,
                    itemBuilder: (context, index) {
                      final bien = biens[index];
                      return _CarteBien(bien: bien);
                    },
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
            Hero(
              tag: 'bienPhoto_${bien.id}',
              child: PropertyPhoto(photos: bien.photos, height: 120),
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
