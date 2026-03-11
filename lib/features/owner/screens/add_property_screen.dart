import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final _firestoreService = FirestoreService();

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

    // on capture le contexte avant le await
    final messager = ScaffoldMessenger.of(context);
    final nav = GoRouter.of(context);

    try {
      final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
      if (utilisateur == null) return;

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
