import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final _firestoreService = FirestoreService();
  final _villeCtrl = TextEditingController();
  final _prixMaxCtrl = TextEditingController();
  TypeBienAlerte? _typeSelectionne;
  bool _chargement = false;

  @override
  void dispose() {
    _villeCtrl.dispose();
    _prixMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _creerAlerte() async {
    if (_villeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une ville')),
      );
      return;
    }

    setState(() => _chargement = true);
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    await _firestoreService.creerAlerte(
      locataireId: utilisateur.uid,
      ville: _villeCtrl.text.trim(),
      prixMax: double.tryParse(_prixMaxCtrl.text.trim()),
      type: _typeSelectionne?.name,
    );

    setState(() => _chargement = false);
    _villeCtrl.clear();
    _prixMaxCtrl.clear();
    setState(() => _typeSelectionne = null);

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
                  _champTexte('Ville *', 'Ex: Conakry', _villeCtrl),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  final alertes = snapshot.data ?? [];
                  if (alertes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Aucune alerte active',
                          style: TextStyle(color: AppColors.textSecondaire),
                        ),
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
                                        alerte['ville'] ?? '',
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.texteLeger,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.fond,
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
