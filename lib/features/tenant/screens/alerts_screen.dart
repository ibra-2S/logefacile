import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/equipements.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/commune_dropdown.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final _firestoreService = FirestoreService();
  final _villeCtrl = TextEditingController(text: 'Conakry');
  final _prixMaxCtrl = TextEditingController();
  TypeBienAlerte? _typeSelectionne;
  String? _communeSelectionnee;
  final List<String> _equipementsSelectionnes = [];
  bool _chargement = false;

  @override
  void dispose() {
    _villeCtrl.dispose();
    _prixMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _creerAlerte() async {
    setState(() => _chargement = true);
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    await _firestoreService.creerAlerte(
      locataireId: utilisateur.uid,
      ville: _villeCtrl.text.trim(),
      commune: _communeSelectionnee,
      prixMax: double.tryParse(_prixMaxCtrl.text.trim()),
      type: _typeSelectionne?.name,
      equipements: _equipementsSelectionnes,
    );

    setState(() {
      _chargement = false;
      _typeSelectionne = null;
      _communeSelectionnee = null;
      _equipementsSelectionnes.clear();
    });
    _prixMaxCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerte créée avec succès !'),
        backgroundColor: AppColors.succes,
      ),
    );
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
          'Mes alertes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // créer une alerte
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔔 Nouvelle alerte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Soyez notifié dès qu\'un bien correspond à vos critères',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaire,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _champTexte(
                    'Ville',
                    'Conakry',
                    _villeCtrl,
                    actif: false,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LogeFacile est disponible uniquement à Conakry.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaire),
                  ),
                  const SizedBox(height: 12),
                  CommuneDropdown(
                    valeur: _communeSelectionnee,
                    onChanged: (v) => setState(() => _communeSelectionnee = v),
                    border: Border.all(color: AppColors.grisClair),
                  ),
                  const SizedBox(height: 12),
                  _champTexte(
                    'Prix maximum (GNF)',
                    'Ex: 500000',
                    _prixMaxCtrl,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Type de bien',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.texte,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          TypeBienAlerte.values.map((type) {
                            final estSelectionne = type == _typeSelectionne;
                            return GestureDetector(
                              onTap:
                                  () => setState(
                                    () =>
                                        _typeSelectionne =
                                            estSelectionne ? null : type,
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
                                          ? AppColors.bleuFonce
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        estSelectionne
                                            ? AppColors.bleuFonce
                                            : AppColors.grisClair,
                                  ),
                                ),
                                child: Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 13,
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
                  const SizedBox(height: 12),
                  const Text(
                    'Commodités souhaitées',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.texte,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Un bien correspond dès qu\'il a au moins une des '
                    'commodités cochées ici.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaire),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        equipementsDisponibles.map((eq) {
                          final estCoche = _equipementsSelectionnes.contains(
                            eq,
                          );
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
                                        ? AppColors.bleuFonce
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      estCoche
                                          ? AppColors.bleuFonce
                                          : AppColors.grisClair,
                                ),
                              ),
                              child: Text(
                                eq,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      estCoche ? Colors.white : AppColors.texte,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _chargement ? null : _creerAlerte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bleuFonce,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child:
                          _chargement
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Créer l\'alerte',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // liste des alertes
            const Text(
              'Mes alertes actives',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.texte,
              ),
            ),
            const SizedBox(height: 12),

            if (utilisateur != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.alertesLocataire(utilisateur.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Shimmer(
                      child: Column(
                        children: [
                          SkeletonBox(
                            height: 64,
                            radius: 12,
                            width: double.infinity,
                          ),
                          SizedBox(height: 12),
                          SkeletonBox(
                            height: 64,
                            radius: 12,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    );
                  }
                  final alertes = snapshot.data ?? [];
                  if (alertes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: EmptyState(
                        icone: Icons.notifications_none,
                        titre: 'Aucune alerte active',
                        message:
                            'Créez une alerte ci-dessus : vous serez prévenu '
                            'dès qu\'une annonce correspond à vos critères.',
                        couleur: AppColors.bleuFonce,
                      ),
                    );
                  }
                  return Column(
                    children:
                        alertes.map((alerte) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grisClair),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🔔',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alerte['commune'] != null
                                            ? '${alerte['commune']} — ${alerte['ville'] ?? ''}'
                                            : alerte['ville'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.texte,
                                        ),
                                      ),
                                      if (alerte['prixMax'] != null)
                                        Text(
                                          'Max : ${alerte['prixMax']} GNF',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaire,
                                          ),
                                        ),
                                      if (alerte['type'] != null)
                                        Text(
                                          alerte['type'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaire,
                                          ),
                                        ),
                                      if ((alerte['equipements'] as List?)
                                              ?.isNotEmpty ??
                                          false)
                                        Text(
                                          (alerte['equipements'] as List)
                                              .join(', '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaire,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.erreur,
                                  ),
                                  onPressed:
                                      () => _firestoreService.supprimerAlerte(
                                        alerte['id'],
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _champTexte(
    String label,
    String hint,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    bool actif = true,
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
          keyboardType: type,
          enabled: actif,
          style: TextStyle(
            fontSize: 14,
            color: actif ? AppColors.texte : AppColors.textSecondaire,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.texteLeger,
              fontSize: 13,
            ),
            suffixIcon:
                actif
                    ? null
                    : const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.textSecondaire,
                    ),
            filled: true,
            fillColor: actif ? AppColors.fond : const Color(0xFFEDEEF1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grisClair),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grisClair),
            ),
            disabledBorder: OutlineInputBorder(
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

enum TypeBienAlerte {
  maison,
  appartement,
  chambre,
  studio;

  String get label {
    switch (this) {
      case TypeBienAlerte.maison:
        return '🏠 Maison';
      case TypeBienAlerte.appartement:
        return '🏢 Appartement';
      case TypeBienAlerte.chambre:
        return '🛏️ Chambre';
      case TypeBienAlerte.studio:
        return '🪟 Studio';
    }
  }
}
