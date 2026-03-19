import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
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

  TypeBien _typeSelectionne = TypeBien.maison;
  bool _chargement = false;
  String? _erreur;

  // photos sélectionnées
  final List<File> _photosSelectionnees = [];
  bool _uploadEnCours = false;

  // Cloudinary config
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
    super.dispose();
  }

  // sélectionner des photos depuis la galerie
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
          if (_photosSelectionnees.length < 5) {
            _photosSelectionnees.add(File(img.path));
          }
        }
      });
    }
  }

  // supprimer une photo
  void _supprimerPhoto(int index) {
    setState(() => _photosSelectionnees.removeAt(index));
  }

  // uploader les photos sur Cloudinary
  Future<List<String>> _uploaderPhotos() async {
    final urls = <String>[];
    setState(() => _uploadEnCours = true);

    for (final photo in _photosSelectionnees) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        urls.add(jsonData['secure_url'] as String);
      }
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

      // upload des photos si sélectionnées
      List<String> photosUrls = [];
      if (_photosSelectionnees.isNotEmpty) {
        photosUrls = await _uploaderPhotos();
      }

      final bien = PropertyModel(
        id: '',
        proprietaireId: utilisateur.uid,
        proprietaireRole: utilisateur.role.name,
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _typeSelectionne,
        statut: StatutBien.disponible,
        prix: double.tryParse(_prixCtrl.text.trim()) ?? 0,
        surface: double.tryParse(_surfaceCtrl.text.trim()),
        nombrePieces: int.tryParse(_piecesCtrl.text.trim()),
        adresse: _adresseCtrl.text.trim(),
        ville: _villeCtrl.text.trim(),
        quartier:
            _quartierCtrl.text.trim().isEmpty
                ? null
                : _quartierCtrl.text.trim(),
        localisation: const GeoPoint(9.5370, -13.6773),
        equipements: _equipementsSelectionnes,
        photos: photosUrls,
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
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        elevation: 0,
        title: const Text(
          'Publier un bien',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // type de bien
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

            // ── SECTION PHOTOS ──
            _titreSectionn('Photos du logement (max 5)'),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // bouton ajouter photo
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
                          border: Border.all(
                            color: AppColors.grisClair,
                            style: BorderStyle.solid,
                          ),
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

                  // photos sélectionnées
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

            // informations de base
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

            // localisation
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
            const SizedBox(height: 20),

            // détails
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
            const SizedBox(height: 20),

            // équipements
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

            // message d'erreur
            if (_erreur != null) ...[
              Text(
                _erreur!,
                style: const TextStyle(color: AppColors.erreur, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],

            // bouton publier
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
