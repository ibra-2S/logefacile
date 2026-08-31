import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _surfaceCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _chambresCtrl = TextEditingController();
  final _toilettesCtrl = TextEditingController();
  final _cuisinesCtrl = TextEditingController();
  final _nomProprietaireCtrl = TextEditingController();
  final _fraisAgenceCtrl = TextEditingController();

  TypeBien _typeSelectionne = TypeBien.maison;
  bool _chargement = false;
  String? _erreur;

  // conditions financières
  bool _avecCaution = false;
  int _moisCaution = 1;
  bool _avecAvance = false;
  int _moisAvance = 1;
  bool _avecFraisAgence = false;

  // localisation GPS
  GeoPoint? _localisation;
  bool _localisationEnCours = false;

  // photos
  final List<File> _photosSelectionnees = [];
  bool _uploadEnCours = false;

  static const String _cloudName = 'dfxnwioow';
  static const String _uploadPreset = 'g1qqzyep';

  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();

  final List<String> _equipements = [
    'wifi',
    'parking',
    'eau',
    'électricité',
    'climatisation',
    'gardien',
  ];
  final List<String> _equipementsSelectionnes = [];

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _quartierCtrl.dispose();
    _prixCtrl.dispose();
    _surfaceCtrl.dispose();
    _piecesCtrl.dispose();
    _chambresCtrl.dispose();
    _toilettesCtrl.dispose();
    _cuisinesCtrl.dispose();
    _nomProprietaireCtrl.dispose();
    _fraisAgenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenirLocalisation() async {
    setState(() => _localisationEnCours = true);
    try {
      bool serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez le GPS sur votre téléphone'),
              backgroundColor: AppColors.avertissement,
            ),
          );
        setState(() => _localisationEnCours = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission de localisation refusée'),
                backgroundColor: AppColors.erreur,
              ),
            );
          setState(() => _localisationEnCours = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission refusée définitivement. Activez-la dans les paramètres.',
              ),
              backgroundColor: AppColors.erreur,
            ),
          );
        setState(() => _localisationEnCours = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _localisation = GeoPoint(position.latitude, position.longitude);
        _localisationEnCours = false;
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Position enregistrée avec succès !'),
            backgroundColor: AppColors.succes,
          ),
        );
    } catch (e) {
      setState(() => _localisationEnCours = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la localisation. Réessayez.'),
            backgroundColor: AppColors.erreur,
          ),
        );
    }
  }

  Future<void> _selectionnerPhotos() async {
    if (_photosSelectionnees.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos autorisées'),
          backgroundColor: AppColors.avertissement,
        ),
      );
      return;
    }
    final restantes = 5 - _photosSelectionnees.length;
    final images = await _imagePicker.pickMultiImage(limit: restantes);
    if (images.isNotEmpty) {
      setState(() {
        for (final img in images) {
          if (_photosSelectionnees.length < 5)
            _photosSelectionnees.add(File(img.path));
        }
      });
    }
  }

  void _supprimerPhoto(int index) =>
      setState(() => _photosSelectionnees.removeAt(index));

  Future<List<String>> _uploaderPhotos() async {
    final urls = <String>[];
    setState(() => _uploadEnCours = true);
    for (final photo in _photosSelectionnees) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
        );
        request.fields['upload_preset'] = _uploadPreset;
        request.files.add(
          await http.MultipartFile.fromPath('file', photo.path),
        );
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        if (response.statusCode == 200)
          urls.add(jsonData['secure_url'] as String);
      } catch (e) {}
    }
    setState(() => _uploadEnCours = false);
    return urls;
  }

  Future<void> _publierBien() async {
    if (_titreCtrl.text.trim().isEmpty ||
        _adresseCtrl.text.trim().isEmpty ||
        _villeCtrl.text.trim().isEmpty ||
        _prixCtrl.text.trim().isEmpty) {
      setState(
        () => _erreur = 'Veuillez remplir tous les champs obligatoires.',
      );
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final messager = ScaffoldMessenger.of(context);
    final nav = GoRouter.of(context);

    try {
      final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
      if (utilisateur == null) return;

      List<String> photosUrls = [];
      if (_photosSelectionnees.isNotEmpty) photosUrls = await _uploaderPhotos();

      final bien = PropertyModel(
        id: '',
        proprietaireId: utilisateur.uid,
        proprietaireRole: utilisateur.role.name,
        nomProprietaireReel:
            utilisateur.role == UserRole.agent &&
                    _nomProprietaireCtrl.text.trim().isNotEmpty
                ? _nomProprietaireCtrl.text.trim()
                : null,
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _typeSelectionne,
        statut: StatutBien.disponible,
        prix: double.tryParse(_prixCtrl.text.trim()) ?? 0,
        surface: double.tryParse(_surfaceCtrl.text.trim()),
        nombrePieces: int.tryParse(_piecesCtrl.text.trim()),
        nombreChambres: int.tryParse(_chambresCtrl.text.trim()),
        nombreToilettes: int.tryParse(_toilettesCtrl.text.trim()),
        nombreCuisines: int.tryParse(_cuisinesCtrl.text.trim()),
        adresse: _adresseCtrl.text.trim(),
        ville: _villeCtrl.text.trim(),
        quartier:
            _quartierCtrl.text.trim().isEmpty
                ? null
                : _quartierCtrl.text.trim(),
        localisation: _localisation ?? const GeoPoint(9.5370, -13.6773),
        equipements: _equipementsSelectionnes,
        photos: photosUrls,
        moisCaution: _avecCaution ? _moisCaution : null,
        moisAvance: _avecAvance ? _moisAvance : null,
        fraisAgence:
            utilisateur.role == UserRole.agent &&
                    _avecFraisAgence &&
                    _fraisAgenceCtrl.text.trim().isNotEmpty
                ? double.tryParse(_fraisAgenceCtrl.text.trim())
                : null,
        datePublication: DateTime.now(),
        dateMiseAJour: DateTime.now(),
      );

      await _firestoreService.ajouterBien(bien);
      messager.showSnackBar(
        const SnackBar(
          content: Text('Bien publié avec succès !'),
          backgroundColor: AppColors.succes,
        ),
      );
      nav.pop();
    } catch (e) {
      setState(() => _erreur = 'Erreur lors de la publication. Réessayez.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;
    final estAgent = utilisateur?.role == UserRole.agent;

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Publier un bien',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECTION AGENT ──
            if (estAgent) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bleuClair,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.bleuFonce.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.bleuFonce,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Vous publiez en tant qu\'agent',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.bleuFonce,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _champTexte(
                      'Nom du propriétaire du bien *',
                      'Ex: Mamadou Diallo',
                      _nomProprietaireCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── TYPE DE BIEN ──
            _titreSectionn('Type de bien *'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    TypeBien.values.map((type) {
                      final estSelectionne = type == _typeSelectionne;
                      final labels = {
                        TypeBien.maison: '🏠 Maison',
                        TypeBien.appartement: '🏢 Appartement',
                        TypeBien.chambre: '🛏️ Chambre',
                        TypeBien.studio: '🪟 Studio',
                      };
                      return GestureDetector(
                        onTap: () => setState(() => _typeSelectionne = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
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
                          child: Text(
                            labels[type]!,
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

            // ── PHOTOS ──
            _titreSectionn('Photos du logement (max 5)'),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_photosSelectionnees.length < 5)
                    GestureDetector(
                      onTap: _selectionnerPhotos,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grisClair),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.bleuFonce,
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ajouter',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.bleuFonce,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ..._photosSelectionnees.asMap().entries.map((entry) {
                    final index = entry.key;
                    final photo = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(photo),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => _supprimerPhoto(index),
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
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bleuFonce.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Principale',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
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
            if (_uploadEnCours) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Upload des photos en cours...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaire,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── INFORMATIONS GÉNÉRALES ──
            _titreSectionn('Informations générales'),
            const SizedBox(height: 10),
            _champTexte(
              'Titre de l\'annonce *',
              'Ex: Bel appartement à Kaloum',
              _titreCtrl,
            ),
            const SizedBox(height: 12),
            _champTexte(
              'Description',
              'Décrivez votre bien en détail...',
              _descCtrl,
              lignes: 4,
            ),
            const SizedBox(height: 20),

            // ── LOCALISATION ──
            _titreSectionn('Localisation'),
            const SizedBox(height: 10),
            _champTexte('Ville *', 'Ex: Conakry', _villeCtrl),
            const SizedBox(height: 12),
            _champTexte(
              'Adresse complète *',
              'Ex: Rue KA-045, Kaloum',
              _adresseCtrl,
            ),
            const SizedBox(height: 12),
            _champTexte('Quartier', 'Ex: Kaloum, Dixinn...', _quartierCtrl),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _localisationEnCours ? null : _obtenirLocalisation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      _localisation != null
                          ? AppColors.succes.withValues(alpha: 0.1)
                          : AppColors.bleuClair,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _localisation != null
                            ? AppColors.succes
                            : AppColors.bleuFonce.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _localisationEnCours
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          _localisation != null
                              ? Icons.location_on
                              : Icons.location_searching,
                          color:
                              _localisation != null
                                  ? AppColors.succes
                                  : AppColors.bleuFonce,
                          size: 22,
                        ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _localisation != null
                                ? '✅ Position GPS enregistrée'
                                : 'Enregistrer ma position GPS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  _localisation != null
                                      ? AppColors.succes
                                      : AppColors.bleuFonce,
                            ),
                          ),
                          Text(
                            _localisation != null
                                ? 'Lat: ${_localisation!.latitude.toStringAsFixed(4)}, Lng: ${_localisation!.longitude.toStringAsFixed(4)}'
                                : 'Appuyez pour localiser le bien sur la carte',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaire,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_localisation != null)
                      GestureDetector(
                        onTap: () => setState(() => _localisation = null),
                        child: const Icon(
                          Icons.refresh,
                          color: AppColors.textSecondaire,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── DÉTAILS ──
            _titreSectionn('Détails du bien'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _champTexte(
                    'Prix mensuel (GNF) *',
                    'Ex: 500000',
                    _prixCtrl,
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _champTexte(
                    'Surface (m²)',
                    'Ex: 45',
                    _surfaceCtrl,
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _champTexte(
              'Nombre de pièces',
              'Ex: 3',
              _piecesCtrl,
              type: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _champTexte(
                    '🛏️ Chambres',
                    'Ex: 2',
                    _chambresCtrl,
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _champTexte(
                    '🚿 Toilettes',
                    'Ex: 1',
                    _toilettesCtrl,
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _champTexte(
                    '🍳 Cuisines',
                    'Ex: 1',
                    _cuisinesCtrl,
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── CONDITIONS FINANCIÈRES ──
            _titreSectionn('Conditions financières'),
            const SizedBox(height: 10),

            // caution
            _carteCondition(
              titre: '🔒 Caution',
              description: 'Demander une caution remboursable',
              active: _avecCaution,
              onChanged: (val) => setState(() => _avecCaution = val),
              contenu:
                  _avecCaution
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Nombre de mois :',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.texte,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _boutonMois(() {
                                if (_moisCaution > 1)
                                  setState(() => _moisCaution--);
                              }, Icons.remove),
                              const SizedBox(width: 16),
                              Text(
                                '$_moisCaution mois',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bleuFonce,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _boutonMois(() {
                                if (_moisCaution < 12)
                                  setState(() => _moisCaution++);
                              }, Icons.add),
                            ],
                          ),
                        ],
                      )
                      : null,
            ),
            const SizedBox(height: 10),

            // avance
            _carteCondition(
              titre: '📅 Avance',
              description: 'Demander un paiement en avance',
              active: _avecAvance,
              onChanged: (val) => setState(() => _avecAvance = val),
              contenu:
                  _avecAvance
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Nombre de mois :',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.texte,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _boutonMois(() {
                                if (_moisAvance > 1)
                                  setState(() => _moisAvance--);
                              }, Icons.remove),
                              const SizedBox(width: 16),
                              Text(
                                '$_moisAvance mois',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bleuFonce,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _boutonMois(() {
                                if (_moisAvance < 24)
                                  setState(() => _moisAvance++);
                              }, Icons.add),
                            ],
                          ),
                        ],
                      )
                      : null,
            ),

            // frais agence (agents seulement)
            if (estAgent) ...[
              const SizedBox(height: 10),
              _carteCondition(
                titre: '💼 Frais d\'agence',
                description: 'Ajouter des frais d\'agence',
                active: _avecFraisAgence,
                onChanged: (val) => setState(() => _avecFraisAgence = val),
                contenu:
                    _avecFraisAgence
                        ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _champTexte(
                            'Montant des frais (GNF)',
                            'Ex: 150000',
                            _fraisAgenceCtrl,
                            type: TextInputType.number,
                          ),
                        )
                        : null,
              ),
            ],
            const SizedBox(height: 20),

            // ── ÉQUIPEMENTS ──
            _titreSectionn('Équipements disponibles'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _equipements.map((eq) {
                    final estCoche = _equipementsSelectionnes.contains(eq);
                    return GestureDetector(
                      onTap:
                          () => setState(() {
                            estCoche
                                ? _equipementsSelectionnes.remove(eq)
                                : _equipementsSelectionnes.add(eq);
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
                            color: estCoche ? Colors.white : AppColors.texte,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 28),

            if (_erreur != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.erreur.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.erreur.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _erreur!,
                  style: const TextStyle(color: AppColors.erreur, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _chargement ? null : _publierBien,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertProprietaire,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _chargement
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Publier le bien',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _carteCondition({
    required String titre,
    required String description,
    required bool active,
    required ValueChanged<bool> onChanged,
    Widget? contenu,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppColors.bleuClair : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaire,
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

  Widget _boutonMois(VoidCallback onTap, IconData icone) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bleuFonce,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _titreSectionn(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.texte,
      ),
    );
  }

  Widget _champTexte(
    String label,
    String hint,
    TextEditingController ctrl, {
    int lignes = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.texte,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: lignes,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.texteLeger,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grisClair),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grisClair),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.bleuFonce),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
