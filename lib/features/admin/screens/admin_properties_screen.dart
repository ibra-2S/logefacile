import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/cloche_notifications.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/property_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

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
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Tous les biens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (utilisateur != null) ClocheNotifications(uid: utilisateur.uid),
          const SizedBox(width: 4),
        ],
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
    return GestureDetector(
      onTap: () => _ouvrirFiche(context),
      child: Container(
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
            PropertyPhoto(
              photos: bien.photos,
              height: 70,
              width: 70,
              borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  void _ouvrirFiche(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => _FicheBien(bien: bien, firestoreService: firestoreService),
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

// ── Fiche détaillée d'un bien (bottom sheet) ───────────────────────────────

class _FicheBien extends StatelessWidget {
  final PropertyModel bien;
  final FirestoreService firestoreService;

  const _FicheBien({required this.bien, required this.firestoreService});

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} à '
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  String _typeLabel(TypeBien t) => switch (t) {
    TypeBien.maison => 'Maison',
    TypeBien.appartement => 'Appartement',
    TypeBien.chambre => 'Chambre',
    TypeBien.studio => 'Studio',
  };

  String _statutLabel(StatutBien s) => switch (s) {
    StatutBien.disponible => 'Disponible',
    StatutBien.loue => 'Loué',
    StatutBien.suspendu => 'Suspendu',
  };

  Color _statutColor(StatutBien s) => switch (s) {
    StatutBien.disponible => AppColors.succes,
    StatutBien.loue => AppColors.avertissement,
    StatutBien.suspendu => AppColors.erreur,
  };

  String _roleLabel(UserRole r) => switch (r) {
    UserRole.proprietaire => 'Propriétaire',
    UserRole.agent => 'Agent immobilier',
    UserRole.locataire => 'Locataire',
    UserRole.admin => 'Administrateur',
  };

  @override
  Widget build(BuildContext context) {
    final prix = bien.prix.toStringAsFixed(0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // photos
            if (bien.photos.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: bien.photos.length,
                  itemBuilder:
                      (_, i) => Image.network(
                        bien.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: AppColors.marine.withValues(alpha: 0.12),
                              child: const Center(
                                child: Icon(
                                  Icons.home_work_outlined,
                                  size: 48,
                                  color: AppColors.marine,
                                ),
                              ),
                            ),
                      ),
                ),
              )
            else
              Container(
                height: 140,
                color: AppColors.marine.withValues(alpha: 0.12),
                child: const Center(
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 48,
                    color: AppColors.marine,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
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
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bien.titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texte,
                          ),
                        ),
                      ),
                      _puce(
                        _statutLabel(bien.statut),
                        _statutColor(bien.statut),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$prix GNF / mois',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.vertProprietaire,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _section('Localisation'),
                  _ligne('Adresse', bien.adresse.isEmpty ? '—' : bien.adresse),
                  _ligne(
                    'Quartier',
                    bien.quartier?.isNotEmpty == true ? bien.quartier! : '—',
                  ),
                  _ligne('Ville', bien.ville.isEmpty ? '—' : bien.ville),

                  const SizedBox(height: 16),
                  _section('Caractéristiques'),
                  _ligne('Type', _typeLabel(bien.type)),
                  if (bien.surface != null)
                    _ligne('Surface', '${bien.surface!.toStringAsFixed(0)} m²'),
                  if (bien.nombrePieces != null)
                    _ligne('Pièces', '${bien.nombrePieces}'),
                  if (bien.nombreChambres != null)
                    _ligne('Chambres', '${bien.nombreChambres}'),
                  if (bien.nombreToilettes != null)
                    _ligne('Toilettes', '${bien.nombreToilettes}'),
                  if (bien.nombreCuisines != null)
                    _ligne('Cuisines', '${bien.nombreCuisines}'),

                  if (bien.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _section('Description'),
                    Text(
                      bien.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondaire,
                      ),
                    ),
                  ],

                  if (bien.equipements.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _section('Équipements'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final e in bien.equipements)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bleuClair,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.bleuFonce,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  if (bien.moisCaution != null ||
                      bien.moisAvance != null ||
                      bien.fraisAgence != null) ...[
                    const SizedBox(height: 16),
                    _section('Conditions financières'),
                    if (bien.moisCaution != null)
                      _ligne('Caution', '${bien.moisCaution} mois'),
                    if (bien.moisAvance != null)
                      _ligne('Avance', '${bien.moisAvance} mois'),
                    if (bien.fraisAgence != null)
                      _ligne(
                        "Frais d'agence",
                        '${bien.fraisAgence!.toStringAsFixed(0)} GNF',
                      ),
                  ],

                  const SizedBox(height: 16),
                  _section('Publication'),
                  _ligne('Publié le', _date(bien.datePublication)),
                  _ligne('Mis à jour le', _date(bien.dateMiseAJour)),
                  _ligne('Vues', '${bien.nombreVues}'),
                  _ligne('Favoris', '${bien.nombreFavoris}'),
                  if (bien.noteMoyenne != null)
                    _ligne(
                      'Note moyenne',
                      '${bien.noteMoyenne!.toStringAsFixed(1)} / 5 '
                          '(${bien.nombreAvis} avis)',
                    ),

                  const SizedBox(height: 16),
                  _section('Propriétaire'),
                  if (bien.nomProprietaireReel != null &&
                      bien.nomProprietaireReel!.isNotEmpty)
                    _ligne('Propriétaire réel', bien.nomProprietaireReel!),
                  FutureBuilder<UserModel?>(
                    future: firestoreService.utilisateurParId(
                      bien.proprietaireId,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final u = snap.data;
                      if (u == null) {
                        return _ligne('Compte', 'Introuvable');
                      }
                      return Column(
                        children: [
                          _ligne('Nom du compte', u.nomComplet),
                          _ligne('Rôle', _roleLabel(u.role)),
                          _ligne('Téléphone', u.telephone ?? '—'),
                          _ligne('Email', u.email),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String titre) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      titre.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.texteLeger,
      ),
    ),
  );

  Widget _ligne(String label, String valeur) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaire,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.texte,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _puce(String texte, Color couleur) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: couleur.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      texte,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: couleur,
      ),
    ),
  );
}
