import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/user_model.dart';
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
  bool _vueIncrementee = false;
  int _photoActuelle = 0;
  final PageController _pageController = PageController();
  Future<UserModel?>? _proprietaireFuture;

  // le bien est chargé une seule fois (pas de StreamBuilder temps réel qui
  // reconstruit toute la page — carte + carrousel — à chaque écriture Firestore)
  PropertyModel? _bien;
  bool _chargement = true;
  String? _erreurChargement;

  @override
  void initState() {
    super.initState();
    _chargerBien();
    _verifierFavori();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _incrementerVue();
    });
  }

  Future<void> _chargerBien() async {
    try {
      final bien = await _firestoreService.getBienParId(widget.bienId).first;
      if (!mounted) return;
      setState(() {
        _bien = bien;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurChargement = '$e';
        _chargement = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _incrementerVue() async {
    if (_vueIncrementee) return;
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.bienId)
            .get();
    if (!doc.exists) return;
    final proprietaireId = doc.data()?['proprietaireId'] ?? '';
    if (proprietaireId == utilisateur.uid) return;
    await _firestoreService.incrementerVues(widget.bienId);
    if (mounted) setState(() => _vueIncrementee = true);
  }

  Future<void> _verifierFavori() async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    final estFavori = await _firestoreService.estEnFavori(
      utilisateur.uid,
      widget.bienId,
    );
    if (mounted) setState(() => _enFavori = estFavori);
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

  Future<UserModel?> _obtenirProprietaire(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<Map<String, String>> _obtenirInfosProprietaire(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return {
        'nomComplet': doc.data()?['nomComplet'] ?? '',
        'photoUrl': doc.data()?['photoUrl'] ?? '',
      };
    }
    return {'nomComplet': '', 'photoUrl': ''};
  }

  Future<void> _demanderVisite(PropertyModel bien) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    final dateChoisie = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Choisissez le jour de la visite',
    );
    if (dateChoisie == null) return;
    if (!mounted) return;

    final heureChoisie = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: "Choisissez l'heure de la visite",
    );
    if (heureChoisie == null) return;
    if (!mounted) return;

    final dateProposee = DateTime(
      dateChoisie.year,
      dateChoisie.month,
      dateChoisie.day,
      heureChoisie.hour,
      heureChoisie.minute,
    );

    final infosProprietaire = await _obtenirInfosProprietaire(
      bien.proprietaireId,
    );

    final demande = VisitRequestModel(
      id: '',
      bienId: bien.id,
      locataireId: utilisateur.uid,
      proprietaireId: bien.proprietaireId,
      dateProposee: dateProposee,
      dateCreation: DateTime.now(),
      dateMiseAJour: DateTime.now(),
      statut: StatutDemande.enAttente,
      nomLocataire: utilisateur.nomComplet,
      titreBien: bien.titre,
      nomProprietaire: infosProprietaire['nomComplet'] ?? '',
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

  Future<void> _contacterProprietaire(PropertyModel bien) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    final infosProprietaire = await _obtenirInfosProprietaire(
      bien.proprietaireId,
    );

    final convId = await _firestoreService.creerOuRecupererConversation(
      utilisateur.uid,
      bien.proprietaireId,
      bien.id,
      titreBien: bien.titre,
      nomLocataire: utilisateur.nomComplet,
      nomProprietaire: infosProprietaire['nomComplet'] ?? '',
      photoLocataire: utilisateur.photoUrl,
      photoProprietaire: infosProprietaire['photoUrl'],
    );

    if (!context.mounted) return;
    context.push(AppRoutes.chat.replaceAll(':id', convId));
  }

  Future<void> _signalerBien(PropertyModel bien) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    String? raisonSelectionnee;
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setStateDialog) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Signaler ce bien'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Raison du signalement :',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...[
                          'Annonce frauduleuse',
                          'Photos incorrectes',
                          'Prix trompeur',
                          'Bien inexistant',
                          'Autre',
                        ].map(
                          (raison) => RadioListTile<String>(
                            title: Text(
                              raison,
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: raison,
                            groupValue: raisonSelectionnee,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged:
                                (val) => setStateDialog(
                                  () => raisonSelectionnee = val,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Description (optionnel)',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.texteLeger,
                            ),
                            filled: true,
                            fillColor: AppColors.fond,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed:
                          raisonSelectionnee == null
                              ? null
                              : () async {
                                await FirebaseFirestore.instance
                                    .collection('reports')
                                    .add({
                                      'bienId': bien.id,
                                      'signalePar': utilisateur.uid,
                                      'type': raisonSelectionnee,
                                      'description': descCtrl.text.trim(),
                                      'traite': false,
                                      'dateCreation': Timestamp.fromDate(
                                        DateTime.now(),
                                      ),
                                    });
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Signalement envoyé. Merci !',
                                      ),
                                      backgroundColor: AppColors.succes,
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.erreur,
                      ),
                      child: const Text(
                        'Envoyer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Builder(
        builder: (context) {
          if (_chargement) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_erreurChargement != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger cette annonce.\n$_erreurChargement',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.texteLeger),
                ),
              ),
            );
          }
          final bien = _bien;
          if (bien == null) {
            return const Center(child: Text('Bien introuvable'));
          }

          final position = LatLng(
            bien.localisation.latitude,
            bien.localisation.longitude,
          );
          // certaines anciennes annonces n'ont pas de coordonnées GPS
          final aUnePosition =
              bien.localisation.latitude != 0 ||
              bien.localisation.longitude != 0;

          return Stack(
            children: [
              // ── TOUT LE CONTENU SCROLLABLE ──
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── DIAPORAMA PHOTOS ──
                    Stack(
                      children: [
                        Hero(
                          tag: 'bienPhoto_${bien.id}',
                          flightShuttleBuilder: (
                            ctx,
                            anim,
                            dir,
                            fromCtx,
                            toCtx,
                          ) {
                            return Container(
                              color: AppColors.bleuClair,
                              alignment: Alignment.center,
                              child:
                                  bien.photos.isEmpty
                                      ? const Text(
                                        '🏠',
                                        style: TextStyle(fontSize: 60),
                                      )
                                      : Image.network(
                                        _imageOptimisee(bien.photos.first),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (_, __, ___) => const Text(
                                              '🏠',
                                              style: TextStyle(fontSize: 60),
                                            ),
                                      ),
                            );
                          },
                          child: SizedBox(
                            height: 300,
                            width: double.infinity,
                            child:
                                bien.photos.isEmpty
                                    ? Container(
                                      color: AppColors.bleuClair,
                                      child: const Center(
                                        child: Text(
                                          '🏠',
                                          style: TextStyle(fontSize: 80),
                                        ),
                                      ),
                                    )
                                    : PageView.builder(
                                    controller: _pageController,
                                    itemCount: bien.photos.length,
                                    onPageChanged:
                                        (index) => setState(
                                          () => _photoActuelle = index,
                                        ),
                                    itemBuilder:
                                        (context, index) => CachedNetworkImage(
                                          imageUrl: _imageOptimisee(
                                            bien.photos[index],
                                          ),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          fadeInDuration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          placeholder:
                                              (context, url) => Container(
                                                color: AppColors.bleuClair,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) => Container(
                                                color: AppColors.bleuClair,
                                                child: const Center(
                                                  child: Text(
                                                    '🏠',
                                                    style: TextStyle(
                                                      fontSize: 48,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),
                                  ),
                          ),
                        ),

                        // indicateur points
                        if (bien.photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                bien.photos.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _photoActuelle == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _photoActuelle == index
                                            ? Colors.white
                                            : Colors.white54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // compteur photos
                        if (bien.photos.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_photoActuelle + 1}/${bien.photos.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // flèches précédent / suivant (fonctionnent au clic,
                        // en plus du glissement)
                        if (bien.photos.length > 1) ...[
                          if (_photoActuelle > 0)
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _flechePhoto(
                                  Icons.chevron_left,
                                  () => _allerPhoto(_photoActuelle - 1),
                                ),
                              ),
                            ),
                          if (_photoActuelle < bien.photos.length - 1)
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _flechePhoto(
                                  Icons.chevron_right,
                                  () => _allerPhoto(_photoActuelle + 1),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),

                    // ── CONTENU ──
                    Padding(
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
                          const Text(
                            'par mois',
                            style: TextStyle(color: AppColors.texteLeger),
                          ),
                          const SizedBox(height: 12),

                          // localisation texte
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
                          // date de mise à jour
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.texteLeger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mis à jour le ${bien.dateMiseAJour.day.toString().padLeft(2, '0')}/${bien.dateMiseAJour.month.toString().padLeft(2, '0')}/${bien.dateMiseAJour.year} à ${bien.dateMiseAJour.hour.toString().padLeft(2, '0')}h${bien.dateMiseAJour.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteLeger,
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
                              _statItem(
                                '🚪',
                                '${bien.nombrePieces ?? '-'} pièces',
                              ),
                              _statItem('👁️', '${bien.nombreVues} vues'),
                              _statItem('❤️', '${bien.nombreFavoris}'),
                            ],
                          ),

                          // chambres / toilettes / cuisines
                          if (bien.nombreChambres != null ||
                              bien.nombreToilettes != null ||
                              bien.nombreCuisines != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (bien.nombreChambres != null)
                                    _statItem(
                                      '🛏️',
                                      '${bien.nombreChambres} chambre${bien.nombreChambres! > 1 ? 's' : ''}',
                                    ),
                                  if (bien.nombreToilettes != null)
                                    _statItem(
                                      '🚿',
                                      '${bien.nombreToilettes} toilette${bien.nombreToilettes! > 1 ? 's' : ''}',
                                    ),
                                  if (bien.nombreCuisines != null)
                                    _statItem(
                                      '🍳',
                                      '${bien.nombreCuisines} cuisine${bien.nombreCuisines! > 1 ? 's' : ''}',
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // statut disponibilité
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  bien.estDisponible
                                      ? AppColors.succes.withValues(alpha: 0.1)
                                      : AppColors.avertissement.withValues(
                                        alpha: 0.1,
                                      ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  bien.estDisponible
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  size: 16,
                                  color:
                                      bien.estDisponible
                                          ? AppColors.succes
                                          : AppColors.avertissement,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  bien.estDisponible
                                      ? 'Disponible à la location'
                                      : 'Actuellement loué',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        bien.estDisponible
                                            ? AppColors.succes
                                            : AppColors.avertissement,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // conditions financières (caution / avance / frais agence)
                          if (bien.moisCaution != null ||
                              bien.moisAvance != null ||
                              bien.fraisAgence != null) ...[
                            const Text(
                              'Conditions financières',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.texte,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  if (bien.moisCaution != null)
                                    _ligneFinance(
                                      'Caution',
                                      '${bien.moisCaution} mois',
                                      '${(bien.prix * bien.moisCaution!).toStringAsFixed(0)} GNF',
                                    ),
                                  if (bien.moisAvance != null)
                                    _ligneFinance(
                                      'Avance',
                                      '${bien.moisAvance} mois',
                                      '${(bien.prix * bien.moisAvance!).toStringAsFixed(0)} GNF',
                                    ),
                                  if (bien.fraisAgence != null)
                                    _ligneFinance(
                                      "Frais d'agence",
                                      '',
                                      '${bien.fraisAgence!.toStringAsFixed(0)} GNF',
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'À prévoir à l\'entrée',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.texte,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${((bien.prix * (bien.moisCaution ?? 0)) + (bien.prix * (bien.moisAvance ?? 0)) + (bien.fraisAgence ?? 0)).toStringAsFixed(0)} GNF',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.vertProprietaire,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // nom propriétaire réel (si agent)
                          if (bien.nomProprietaireReel != null &&
                              bien.nomProprietaireReel!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bleuClair,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: AppColors.bleuFonce,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Propriétaire : ${bien.nomProprietaireReel}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.bleuFonce,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(géré par un agent)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaire,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                            const SizedBox(height: 20),
                          ],

                          // ── CARTE GOOGLE MAPS ──
                          const Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (aUnePosition)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 220,
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: position,
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('bien'),
                                      position: position,
                                      infoWindow: InfoWindow(title: bien.titre),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  scrollGesturesEnabled: true,
                                  zoomGesturesEnabled: true,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 90,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.bleuClair,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Position GPS non renseignée pour cette annonce',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.bleuFonce,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // ── PRÉSENTATION DU PROPRIÉTAIRE ──
                          _sectionProprietaire(bien),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── BOUTONS FLOTTANTS ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _signalerBien(bien),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _toggleFavori(bien),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child:
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
                                  size: 22,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // boutons en bas
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final bien = _bien;
                  if (bien != null) _contacterProprietaire(bien);
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.bleuFonce,
                  size: 18,
                ),
                label: const Text(
                  'Contacter',
                  style: TextStyle(
                    color: AppColors.bleuFonce,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.bleuFonce),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  final bien = _bien;
                  if (bien != null) _demanderVisite(bien);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bleuFonce,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Demander une visite',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _allerPhoto(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _flechePhoto(IconData icone, VoidCallback onTap) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icone, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // insère une transformation Cloudinary pour livrer une image légère
  // (format auto, qualité auto, largeur max 1000px) au lieu de l'original
  String _imageOptimisee(String url) {
    const marqueur = '/image/upload/';
    if (!url.contains(marqueur)) return url;
    if (url.contains('${marqueur}f_auto') ||
        url.contains('${marqueur}q_auto')) {
      return url;
    }
    return url.replaceFirst(marqueur, '${marqueur}f_auto,q_auto,w_1000/');
  }

  Widget _sectionProprietaire(PropertyModel bien) {
    _proprietaireFuture ??= _obtenirProprietaire(bien.proprietaireId);
    return FutureBuilder<UserModel?>(
      future: _proprietaireFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final proprio = snapshot.data;
        if (proprio == null) return const SizedBox.shrink();

        final estAgent = proprio.role == UserRole.agent;
        final roleLabel = estAgent ? 'Agent immobilier' : 'Propriétaire';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estAgent ? "L'agent" : 'Le propriétaire',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.bleuClair,
                        backgroundImage:
                            (proprio.photoUrl != null &&
                                    proprio.photoUrl!.isNotEmpty)
                                ? NetworkImage(proprio.photoUrl!)
                                : null,
                        child:
                            (proprio.photoUrl == null ||
                                    proprio.photoUrl!.isEmpty)
                                ? Text(
                                  proprio.nomComplet.isNotEmpty
                                      ? proprio.nomComplet[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.bleuFonce,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    proprio.nomComplet.isNotEmpty
                                        ? proprio.nomComplet
                                        : 'Utilisateur',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.texte,
                                    ),
                                  ),
                                ),
                                if (proprio.estVerifie) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: AppColors.bleuFonce,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              estAgent && proprio.nomAgence != null &&
                                      proprio.nomAgence!.isNotEmpty
                                  ? '$roleLabel · ${proprio.nomAgence}'
                                  : roleLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaire,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (proprio.biographie != null &&
                      proprio.biographie!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      proprio.biographie!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaire,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (proprio.noteMoyenne != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${proprio.noteMoyenne!.toStringAsFixed(1)} / 5',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ligneFinance(String libelle, String detail, String montant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            libelle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaire,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '($detail)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.texteLeger,
              ),
            ),
          ],
          const Spacer(),
          Text(
            montant,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.texte,
            ),
          ),
        ],
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
