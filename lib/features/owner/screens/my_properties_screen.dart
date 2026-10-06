import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/equipements.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/commune_dropdown.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/property_photo.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

class MyPropertiesScreen extends ConsumerWidget {
  const MyPropertiesScreen({super.key});

  void _ouvrirAjout(BuildContext context, {required bool enAttente}) {
    if (enAttente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Votre compte doit être validé par un administrateur avant de '
            'publier un bien.',
          ),
          backgroundColor: AppColors.avertissement,
        ),
      );
      return;
    }
    context.push(AppRoutes.ajouterBien);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final firestoreService = FirestoreService();
    final enAttente = utilisateur?.compteEnAttenteValidation ?? false;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Mes biens',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _ouvrirAjout(context, enAttente: enAttente),
          ),
        ],
      ),
      body:
          utilisateur == null
              ? const PropertyListSkeleton()
              : StreamBuilder<List<PropertyModel>>(
                stream: firestoreService.biensDuProprietaire(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const PropertyListSkeleton();
                  }
                  final biens = snapshot.data ?? [];
                  if (biens.isEmpty) {
                    return RefreshIndicator(
                      onRefresh:
                          () => Future<void>.delayed(
                            const Duration(milliseconds: 600),
                          ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.62,
                            child: EmptyState(
                              icone: Icons.add_home_work_outlined,
                              titre: 'Aucun bien publié',
                              message:
                                  'Publiez votre premier logement pour le '
                                  'rendre visible aux locataires.',
                              couleur: AppColors.vertProprietaire,
                              action: ElevatedButton.icon(
                                onPressed:
                                    () => _ouvrirAjout(
                                      context,
                                      enAttente: enAttente,
                                    ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
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
                      itemCount: biens.length,
                      itemBuilder: (context, index) {
                        final bien = biens[index];
                        return _CarteBien(
                          bien: bien,
                          firestoreService: firestoreService,
                          estAgent: utilisateur.role == UserRole.agent,
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirAjout(context, enAttente: enAttente),
        backgroundColor:
            enAttente ? AppColors.grisMoyen : AppColors.vertProprietaire,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CarteBien extends StatelessWidget {
  final PropertyModel bien;
  final FirestoreService firestoreService;
  final bool estAgent;

  const _CarteBien({
    required this.bien,
    required this.firestoreService,
    required this.estAgent,
  });

  Future<void> _toggleDisponibilite(BuildContext context) async {
    final nouveauStatut =
        bien.statut == StatutBien.disponible
            ? StatutBien.loue
            : StatutBien.disponible;

    final confirme = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              bien.statut == StatutBien.disponible
                  ? 'Marquer comme loué ?'
                  : 'Marquer comme disponible ?',
            ),
            content: Text(
              bien.statut == StatutBien.disponible
                  ? 'Ce bien sera marqué comme loué et retiré des recherches.'
                  : 'Ce bien sera à nouveau visible dans les recherches.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bleuFonce,
                ),
                child: const Text(
                  'Confirmer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirme != true) return;
    await firestoreService.modifierBien(bien.id, {
      'statut': nouveauStatut.name,
      'estDisponible': nouveauStatut == StatutBien.disponible,
      'dateMiseAJour': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> _supprimerBien(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Supprimer ce bien ?'),
            content: const Text(
              'Cette action est irréversible. Le bien sera définitivement supprimé.',
            ),
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

    if (confirme != true) return;
    await firestoreService.supprimerBien(bien.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bien supprimé avec succès !'),
          backgroundColor: AppColors.succes,
        ),
      );
    }
  }

  void _afficherModifierBien(BuildContext context) {
    // controllers pré-remplis avec les valeurs actuelles
    final titreCtrl = TextEditingController(text: bien.titre);
    final descCtrl = TextEditingController(text: bien.description);
    final prixCtrl = TextEditingController(text: bien.prix.toStringAsFixed(0));
    final surfaceCtrl = TextEditingController(
      text: bien.surface?.toStringAsFixed(0) ?? '',
    );
    final piecesCtrl = TextEditingController(
      text: bien.nombrePieces?.toString() ?? '',
    );
    final chambresCtrl = TextEditingController(
      text: bien.nombreChambres?.toString() ?? '',
    );
    final toilettesCtrl = TextEditingController(
      text: bien.nombreToilettes?.toString() ?? '',
    );
    final cuisinesCtrl = TextEditingController(
      text: bien.nombreCuisines?.toString() ?? '',
    );
    final salonsCtrl = TextEditingController(
      text: bien.nombreSalons?.toString() ?? '',
    );
    final villeCtrl = TextEditingController(text: bien.ville);
    final adresseCtrl = TextEditingController(text: bien.adresse);
    final quartierCtrl = TextEditingController(text: bien.quartier ?? '');
    final nomProprietaireCtrl = TextEditingController(
      text: bien.nomProprietaireReel ?? '',
    );
    final fraisAgenceCtrl = TextEditingController(
      text: bien.fraisAgence?.toStringAsFixed(0) ?? '',
    );

    TypeBien typeSelectionne = bien.type;
    String? communeSelectionnee = bien.commune;
    bool avecCaution = bien.moisCaution != null;
    int moisCaution = bien.moisCaution ?? 1;
    bool avecAvance = bien.moisAvance != null;
    int moisAvance = bien.moisAvance ?? 1;
    bool avecFraisAgence = bien.fraisAgence != null;
    List<String> equipementsSelectionnes = List.from(bien.equipements);

    // localisation GPS : un bien publié sans position a (0, 0) enregistré.
    bool avecLocalisation =
        bien.localisation.latitude != 0 || bien.localisation.longitude != 0;
    GeoPoint? localisationChoisie = avecLocalisation ? bien.localisation : null;
    bool localisationEnCours = false;

    // Bornes géographiques approximatives du Grand Conakry (mêmes bornes
    // que sur l'écran de publication).
    const conakryLatMin = 9.45;
    const conakryLatMax = 9.85;
    const conakryLngMin = -13.85;
    const conakryLngMax = -13.45;
    bool dansConakry(double lat, double lng) =>
        lat >= conakryLatMin &&
        lat <= conakryLatMax &&
        lng >= conakryLngMin &&
        lng <= conakryLngMax;

    Future<void> obtenirLocalisation(
      BuildContext ctx,
      StateSetter setStateModal,
    ) async {
      setStateModal(() => localisationEnCours = true);
      try {
        final serviceActif = await Geolocator.isLocationServiceEnabled();
        if (!serviceActif) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Activez le GPS sur votre téléphone'),
                backgroundColor: AppColors.avertissement,
              ),
            );
          }
          setStateModal(() => localisationEnCours = false);
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Permission de localisation refusée'),
                  backgroundColor: AppColors.erreur,
                ),
              );
            }
            setStateModal(() => localisationEnCours = false);
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission refusée définitivement. Activez-la dans les paramètres.',
                ),
                backgroundColor: AppColors.erreur,
              ),
            );
          }
          setStateModal(() => localisationEnCours = false);
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        if (!dansConakry(position.latitude, position.longitude)) {
          setStateModal(() => localisationEnCours = false);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Votre position actuelle est hors de Conakry. '
                  'La localisation GPS ne peut être enregistrée que depuis Conakry.',
                ),
                backgroundColor: AppColors.erreur,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        setStateModal(() {
          localisationChoisie = GeoPoint(position.latitude, position.longitude);
          localisationEnCours = false;
        });

        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Position enregistrée avec succès !'),
              backgroundColor: AppColors.succes,
            ),
          );
        }
      } catch (e) {
        setStateModal(() => localisationEnCours = false);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la localisation. Réessayez.'),
              backgroundColor: AppColors.erreur,
            ),
          );
        }
      }
    }

    // photos : celles déjà en ligne (URLs) + celles ajoutées localement
    // (fichiers, pas encore téléversées)
    final photosExistantes = List<String>.from(bien.photos);
    final nouvellesPhotos = <File>[];
    bool enregistrementEnCours = false;
    final imagePicker = ImagePicker();

    final equipements = equipementsDisponibles;
    final labels = {
      TypeBien.maison: 'Maison',
      TypeBien.appartement: 'Appartement',
      TypeBien.chambre: 'Chambre',
      TypeBien.studio: 'Studio',
    };
    final icones = {
      TypeBien.maison: Icons.home_outlined,
      TypeBien.appartement: Icons.apartment_outlined,
      TypeBien.chambre: Icons.bed_outlined,
      TypeBien.studio: Icons.weekend_outlined,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateModal) => Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // titre modal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modifier le bien',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.texte,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppColors.erreur),
                              ),
                              TextSpan(text: ' Champs obligatoires'),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaire,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── TYPE ──
                        _titreSectionn('Type de bien', obligatoire: true),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                TypeBien.values.map((type) {
                                  final estSelectionne =
                                      type == typeSelectionne;
                                  return GestureDetector(
                                    onTap:
                                        () => setStateModal(
                                          () => typeSelectionne = type,
                                        ),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            estSelectionne
                                                ? AppColors.vertProprietaire
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              estSelectionne
                                                  ? AppColors.vertProprietaire
                                                  : AppColors.grisClair,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icones[type],
                                            size: 15,
                                            color:
                                                estSelectionne
                                                    ? Colors.white
                                                    : AppColors.texte,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            labels[type]!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  estSelectionne
                                                      ? Colors.white
                                                      : AppColors.texte,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── PHOTOS ──
                        _titreSectionn('Photos (max 5)'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              if (photosExistantes.length +
                                      nouvellesPhotos.length <
                                  5)
                                GestureDetector(
                                  onTap: () async {
                                    final restantes =
                                        5 -
                                        (photosExistantes.length +
                                            nouvellesPhotos.length);
                                    final images = await imagePicker
                                        .pickMultiImage(limit: restantes);
                                    if (images.isNotEmpty) {
                                      setStateModal(() {
                                        for (final img in images) {
                                          if (photosExistantes.length +
                                                  nouvellesPhotos.length <
                                              5) {
                                            nouvellesPhotos.add(
                                              File(img.path),
                                            );
                                          }
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.grisClair,
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: AppColors.bleuFonce,
                                          size: 28,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Ajouter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.bleuFonce,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ...photosExistantes.asMap().entries.map((
                                entry,
                              ) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(entry.value),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 14,
                                      child: GestureDetector(
                                        onTap:
                                            () => setStateModal(
                                              () => photosExistantes
                                                  .removeAt(entry.key),
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              ...nouvellesPhotos.asMap().entries.map((entry) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        image: DecorationImage(
                                          image: FileImage(entry.value),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 14,
                                      child: GestureDetector(
                                        onTap:
                                            () => setStateModal(
                                              () => nouvellesPhotos.removeAt(
                                                entry.key,
                                              ),
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── AGENT : nom propriétaire ──
                        if (estAgent) ...[
                          _champEdition(
                            'Nom du propriétaire',
                            nomProprietaireCtrl,
                            obligatoire: true,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── INFORMATIONS GÉNÉRALES ──
                        _titreSectionn('Informations générales'),
                        const SizedBox(height: 8),
                        _champEdition('Titre', titreCtrl, obligatoire: true),
                        const SizedBox(height: 12),
                        _champEdition('Description', descCtrl, lignes: 3),
                        const SizedBox(height: 16),

                        // ── LOCALISATION ──
                        _titreSectionn('Localisation'),
                        const SizedBox(height: 8),
                        _champEdition('Ville', villeCtrl, obligatoire: true),
                        const SizedBox(height: 12),
                        CommuneDropdown(
                          valeur: communeSelectionnee,
                          onChanged: (v) =>
                              setStateModal(() => communeSelectionnee = v),
                          fillColor: const Color(0xFFF5F5F5),
                          labelFontSize: 12,
                          contentPaddingHorizontal: 14,
                        ),
                        const SizedBox(height: 12),
                        _champEdition('Quartier', quartierCtrl),
                        const SizedBox(height: 12),
                        _champEdition('Adresse', adresseCtrl, obligatoire: true),
                        const SizedBox(height: 16),
                        _carteConditionModal(
                          titre: 'Ajouter la localisation exacte',
                          icone: Icons.location_on_outlined,
                          active: avecLocalisation,
                          onChanged: (val) {
                            setStateModal(() {
                              avecLocalisation = val;
                              if (!val) localisationChoisie = null;
                            });
                          },
                          contenu:
                              avecLocalisation
                                  ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Vous devez être physiquement sur '
                                          'place, sur le lieu du bien, au '
                                          'moment de l\'enregistrer.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaire,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        GestureDetector(
                                          onTap:
                                              localisationEnCours
                                                  ? null
                                                  : () => obtenirLocalisation(
                                                    ctx,
                                                    setStateModal,
                                                  ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  localisationChoisie != null
                                                      ? AppColors.succes
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    localisationChoisie != null
                                                        ? AppColors.succes
                                                        : AppColors.bleuFonce
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                localisationEnCours
                                                    ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : Icon(
                                                      localisationChoisie !=
                                                              null
                                                          ? Icons.location_on
                                                          : Icons
                                                              .location_searching,
                                                      color:
                                                          localisationChoisie !=
                                                                  null
                                                              ? AppColors
                                                                  .succes
                                                              : AppColors
                                                                  .bleuFonce,
                                                      size: 20,
                                                    ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    localisationChoisie != null
                                                        ? 'Lat: ${localisationChoisie!.latitude.toStringAsFixed(4)}, Lng: ${localisationChoisie!.longitude.toStringAsFixed(4)}'
                                                        : 'Appuyez une fois sur place, à l\'adresse du bien',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          localisationChoisie !=
                                                                  null
                                                              ? AppColors
                                                                  .succes
                                                              : AppColors
                                                                  .bleuFonce,
                                                    ),
                                                  ),
                                                ),
                                                if (localisationChoisie !=
                                                    null)
                                                  GestureDetector(
                                                    onTap:
                                                        () => setStateModal(
                                                          () =>
                                                              localisationChoisie =
                                                                  null,
                                                        ),
                                                    child: const Icon(
                                                      Icons.refresh,
                                                      color: AppColors
                                                          .textSecondaire,
                                                      size: 16,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // ── DÉTAILS ──
                        _titreSectionn('Détails du bien'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _champEdition(
                                'Prix (GNF)',
                                prixCtrl,
                                obligatoire: true,
                                type: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champEdition(
                                'Surface (m²)',
                                surfaceCtrl,
                                type: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _champEdition(
                          'Nombre de pièces',
                          piecesCtrl,
                          type: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _champEdition(
                                'Chambres',
                                chambresCtrl,
                                type: TextInputType.number,
                                icone: Icons.bed_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champEdition(
                                'Salons',
                                salonsCtrl,
                                type: TextInputType.number,
                                icone: Icons.weekend_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _champEdition(
                                'Toilettes',
                                toilettesCtrl,
                                type: TextInputType.number,
                                icone: Icons.bathtub_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _champEdition(
                                'Cuisines',
                                cuisinesCtrl,
                                type: TextInputType.number,
                                icone: Icons.kitchen_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── CONDITIONS FINANCIÈRES ──
                        _titreSectionn('Conditions financières'),
                        const SizedBox(height: 8),

                        // caution
                        _carteConditionModal(
                          titre: 'Caution',
                          icone: Icons.security_outlined,
                          active: avecCaution,
                          onChanged:
                              (val) => setStateModal(() => avecCaution = val),
                          contenu:
                              avecCaution
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Nombre de mois :',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _boutonMois(() {
                                            if (moisCaution > 1)
                                              setStateModal(
                                                () => moisCaution--,
                                              );
                                          }, Icons.remove),
                                          const SizedBox(width: 16),
                                          Text(
                                            '$moisCaution mois',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.bleuFonce,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          _boutonMois(() {
                                            if (moisCaution < 12)
                                              setStateModal(
                                                () => moisCaution++,
                                              );
                                          }, Icons.add),
                                        ],
                                      ),
                                    ],
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 8),

                        // avance
                        _carteConditionModal(
                          titre: 'Avance',
                          icone: Icons.calendar_month_outlined,
                          active: avecAvance,
                          onChanged:
                              (val) => setStateModal(() => avecAvance = val),
                          contenu:
                              avecAvance
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Nombre de mois :',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _boutonMois(() {
                                            if (moisAvance > 1)
                                              setStateModal(() => moisAvance--);
                                          }, Icons.remove),
                                          const SizedBox(width: 16),
                                          Text(
                                            '$moisAvance mois',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.bleuFonce,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          _boutonMois(() {
                                            if (moisAvance < 24)
                                              setStateModal(() => moisAvance++);
                                          }, Icons.add),
                                        ],
                                      ),
                                    ],
                                  )
                                  : null,
                        ),

                        // frais agence (agents seulement)
                        if (estAgent) ...[
                          const SizedBox(height: 8),
                          _carteConditionModal(
                            titre: 'Frais d\'agence',
                            icone: Icons.badge_outlined,
                            active: avecFraisAgence,
                            onChanged:
                                (val) =>
                                    setStateModal(() => avecFraisAgence = val),
                            contenu:
                                avecFraisAgence
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _champEdition(
                                        'Montant (GNF)',
                                        fraisAgenceCtrl,
                                        type: TextInputType.number,
                                      ),
                                    )
                                    : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── ÉQUIPEMENTS ──
                        _titreSectionn('Équipements'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              equipements.map((eq) {
                                final estCoche = equipementsSelectionnes
                                    .contains(eq);
                                return GestureDetector(
                                  onTap:
                                      () => setStateModal(() {
                                        estCoche
                                            ? equipementsSelectionnes.remove(eq)
                                            : equipementsSelectionnes.add(eq);
                                      }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          estCoche
                                              ? AppColors.vertProprietaire
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            estCoche
                                                ? AppColors.vertProprietaire
                                                : AppColors.grisClair,
                                      ),
                                    ),
                                    child: Text(
                                      eq,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            estCoche
                                                ? Colors.white
                                                : AppColors.texte,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // bouton enregistrer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                enregistrementEnCours
                                    ? null
                                    : () async {
                                      final champManquant =
                                          (estAgent &&
                                              nomProprietaireCtrl.text
                                                  .trim()
                                                  .isEmpty) ||
                                          titreCtrl.text.trim().isEmpty ||
                                          villeCtrl.text.trim().isEmpty ||
                                          communeSelectionnee == null ||
                                          adresseCtrl.text.trim().isEmpty ||
                                          prixCtrl.text.trim().isEmpty;
                                      if (champManquant) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Veuillez remplir tous les champs obligatoires.',
                                            ),
                                            backgroundColor: AppColors.erreur,
                                          ),
                                        );
                                        return;
                                      }
                                      setStateModal(
                                        () => enregistrementEnCours = true,
                                      );

                                      final photosFinales = List<String>.from(
                                        photosExistantes,
                                      )..addAll(
                                        await CloudinaryService.uploaderImages(
                                          nouvellesPhotos,
                                        ),
                                      );

                                      final donnees = {
                                        'titre': titreCtrl.text.trim(),
                                        'description': descCtrl.text.trim(),
                                        'type': typeSelectionne.name,
                                        'prix':
                                            double.tryParse(
                                              prixCtrl.text.trim(),
                                            ) ??
                                            bien.prix,
                                        'surface': double.tryParse(
                                          surfaceCtrl.text.trim(),
                                        ),
                                        'nombrePieces': int.tryParse(
                                          piecesCtrl.text.trim(),
                                        ),
                                        'nombreChambres': int.tryParse(
                                          chambresCtrl.text.trim(),
                                        ),
                                        'nombreToilettes': int.tryParse(
                                          toilettesCtrl.text.trim(),
                                        ),
                                        'nombreCuisines': int.tryParse(
                                          cuisinesCtrl.text.trim(),
                                        ),
                                        'nombreSalons': int.tryParse(
                                          salonsCtrl.text.trim(),
                                        ),
                                        'ville': villeCtrl.text.trim(),
                                        'commune': communeSelectionnee,
                                        'adresse': adresseCtrl.text.trim(),
                                        'quartier':
                                            quartierCtrl.text.trim().isEmpty
                                                ? null
                                                : quartierCtrl.text.trim(),
                                        // (0, 0) = pas de position renseignée ;
                                        // l'écran de détail se base sur ce
                                        // couple pour décider d'afficher ou
                                        // non la carte.
                                        'localisation':
                                            localisationChoisie ??
                                                const GeoPoint(0, 0),
                                        'photos': photosFinales,
                                        'nomProprietaireReel':
                                            estAgent &&
                                                    nomProprietaireCtrl.text
                                                        .trim()
                                                        .isNotEmpty
                                                ? nomProprietaireCtrl.text
                                                    .trim()
                                                : null,
                                        'equipements': equipementsSelectionnes,
                                        'moisCaution':
                                            avecCaution ? moisCaution : null,
                                        'moisAvance':
                                            avecAvance ? moisAvance : null,
                                        'fraisAgence':
                                            estAgent &&
                                                    avecFraisAgence &&
                                                    fraisAgenceCtrl.text
                                                        .trim()
                                                        .isNotEmpty
                                                ? double.tryParse(
                                                  fraisAgenceCtrl.text.trim(),
                                                )
                                                : null,
                                        'dateMiseAJour': Timestamp.fromDate(
                                          DateTime.now(),
                                        ),
                                      };
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await firestoreService.modifierBien(
                                        bien.id,
                                        donnees,
                                      );
                                      if (context.mounted) {
                                        final photosEchouees =
                                            nouvellesPhotos.length -
                                            (photosFinales.length -
                                                photosExistantes.length);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              photosEchouees > 0
                                                  ? 'Bien modifié, mais $photosEchouees photo(s) n\'ont pas pu être envoyées.'
                                                  : 'Bien modifié avec succès !',
                                            ),
                                            backgroundColor: photosEchouees > 0
                                                ? AppColors.avertissement
                                                : AppColors.succes,
                                          ),
                                        );
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bleuFonce,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child:
                                enregistrementEnCours
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Enregistrer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  static Widget _titreSectionn(String titre, {bool obligatoire = false}) {
    return Text.rich(
      TextSpan(text: titre, children: [if (obligatoire) _etoile]),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.texte,
      ),
    );
  }


  /// étoile rouge qui signale un champ obligatoire
  static const _etoile = TextSpan(
    text: ' *',
    style: TextStyle(color: AppColors.erreur),
  );

  static Widget _champEdition(
    String label,
    TextEditingController ctrl, {
    int lignes = 1,
    TextInputType type = TextInputType.text,
    IconData? icone,
    bool obligatoire = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icone != null) ...[
              Icon(icone, size: 14, color: AppColors.textSecondaire),
              const SizedBox(width: 5),
            ],
            Text.rich(
              TextSpan(text: label, children: [if (obligatoire) _etoile]),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.texte,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: lignes,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _carteConditionModal({
    required String titre,
    required bool active,
    required ValueChanged<bool> onChanged,
    IconData? icone,
    Widget? contenu,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AppColors.bleuClair : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              active
                  ? AppColors.bleuFonce.withValues(alpha: 0.3)
                  : AppColors.grisClair,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (icone != null) ...[
                      Icon(icone, size: 15, color: AppColors.bleuFonce),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: onChanged,
                activeColor: AppColors.bleuFonce,
              ),
            ],
          ),
          if (contenu != null) contenu,
        ],
      ),
    );
  }

  static Widget _boutonMois(VoidCallback onTap, IconData icone) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.bleuFonce,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icone, color: Colors.white, size: 16),
      ),
    );
  }

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
          // image
          PropertyPhoto(photos: bien.photos, height: 120),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondaire,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bien.localisationCourte,
                      style: const TextStyle(
                        fontSize: 13,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _afficherModifierBien(context),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.bleuFonce,
                        ),
                        label: const Text(
                          'Modifier',
                          style: TextStyle(
                            color: AppColors.bleuFonce,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.bleuFonce),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleDisponibilite(context),
                        icon: Icon(
                          bien.statut == StatutBien.disponible
                              ? Icons.lock_outline
                              : Icons.lock_open_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          bien.statut == StatutBien.disponible
                              ? 'Marquer loué'
                              : 'Disponible',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              bien.statut == StatutBien.disponible
                                  ? AppColors.avertissement
                                  : AppColors.succes,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _supprimerBien(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.erreur,
                    ),
                    label: const Text(
                      'Supprimer ce bien',
                      style: TextStyle(color: AppColors.erreur, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.erreur),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
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