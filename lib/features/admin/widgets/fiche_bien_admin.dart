import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

// ── Fiche détaillée d'un bien (bottom sheet), partagée entre l'écran
// « Tous les biens » et l'écran « Signalements » de l'administration.

class FicheBienAdmin extends StatelessWidget {
  final PropertyModel bien;
  final FirestoreService firestoreService;

  const FicheBienAdmin({
    super.key,
    required this.bien,
    required this.firestoreService,
  });

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
                  if (bien.nombreSalons != null)
                    _ligne(
                      'Salons',
                      bien.nombreSalons == 0
                          ? 'Aucun'
                          : '${bien.nombreSalons}',
                    ),
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

/// Ouvre la fiche détaillée d'un bien dans un bottom sheet.
void ouvrirFicheBienAdmin(
  BuildContext context, {
  required PropertyModel bien,
  required FirestoreService firestoreService,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => FicheBienAdmin(bien: bien, firestoreService: firestoreService),
  );
}
