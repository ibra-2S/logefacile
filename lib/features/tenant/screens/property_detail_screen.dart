import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/visit_request_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String bienId;
  const PropertyDetailScreen({super.key, required this.bienId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final _firestoreService = FirestoreService();
  bool _enFavori = false;
  bool _chargementFavori = false;

  @override
  void initState() {
    super.initState();
    _verifierFavori();
  }

  Future<void> _verifierFavori() async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    final estFavori = await _firestoreService.estEnFavori(
      utilisateur.uid,
      widget.bienId,
    );
    setState(() => _enFavori = estFavori);
  }

  Future<void> _toggleFavori(PropertyModel bien) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    setState(() => _chargementFavori = true);
    if (_enFavori) {
      await _firestoreService.retirerFavori(utilisateur.uid, bien.id);
    } else {
      await _firestoreService.ajouterFavori(utilisateur.uid, bien);
    }
    setState(() {
      _enFavori = !_enFavori;
      _chargementFavori = false;
    });
  }

  Future<void> _demanderVisite(PropertyModel bien) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    final dateChoisie = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (dateChoisie == null) return;
    if (!context.mounted) return;

    final demande = VisitRequestModel(
      id: '',
      bienId: bien.id,
      locataireId: utilisateur.uid,
      proprietaireId: bien.proprietaireId,
      dateProposee: dateChoisie,
      dateCreation: DateTime.now(),
      dateMiseAJour: DateTime.now(),
      statut: StatutDemande.enAttente,
    );

    await _firestoreService.ajouterDemandeVisite(demande);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande envoyée avec succès !'),
        backgroundColor: AppColors.succes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: StreamBuilder<PropertyModel?>(
        stream: _firestoreService.getBienParId(widget.bienId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bien = snapshot.data;
          if (bien == null) {
            return const Center(child: Text('Bien introuvable'));
          }
          return CustomScrollView(
            slivers: [
              // app bar avec image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.bleuFonce,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon:
                        _chargementFavori
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Icon(
                              _enFavori
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: _enFavori ? Colors.red : Colors.white,
                            ),
                    onPressed: () => _toggleFavori(bien),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      bien.photos.isNotEmpty
                          ? Image.network(bien.photos.first, fit: BoxFit.cover)
                          : Container(
                            color: AppColors.bleuClair,
                            child: const Center(
                              child: Text('🏠', style: TextStyle(fontSize: 80)),
                            ),
                          ),
                ),
              ),

              // contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // titre et prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              bien.titre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.texte,
                              ),
                            ),
                          ),
                          Text(
                            '${bien.prix.toStringAsFixed(0)} GNF',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.vertProprietaire,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'par mois',
                        style: const TextStyle(color: AppColors.texteLeger),
                      ),
                      const SizedBox(height: 12),

                      // localisation
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.bleuFonce,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${bien.quartier ?? ''} — ${bien.ville}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaire,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // stats rapides
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            '📐',
                            '${bien.surface?.toStringAsFixed(0) ?? '-'} m²',
                          ),
                          _statItem('🚪', '${bien.nombrePieces ?? '-'} pièces'),
                          _statItem('👁️', '${bien.nombreVues} vues'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // description
                      if (bien.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bien.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaire,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // équipements
                      if (bien.equipements.isNotEmpty) ...[
                        const Text(
                          'Équipements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              bien.equipements
                                  .map(
                                    (eq) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bleuClair,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        eq,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.bleuFonce,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // bouton demande visite
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final bien =
                await _firestoreService.getBienParId(widget.bienId).first;
            if (bien != null && context.mounted) {
              _demanderVisite(bien);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bleuFonce,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Demander une visite',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String valeur) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          valeur,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.texte,
          ),
        ),
      ],
    );
  }
}
