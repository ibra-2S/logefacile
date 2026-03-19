import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const String _cloudName = 'dfxnwioow';
  static const String _uploadPreset = 'g1qqzyep';

  bool _uploadPhoto = false;

  Future<void> _changerPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    setState(() => _uploadPhoto = true);

    try {
      // upload sur Cloudinary
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        final photoUrl = jsonData['secure_url'] as String;

        // mise à jour dans Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(utilisateur.uid)
            .update({'photoUrl': photoUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour !'),
              backgroundColor: AppColors.succes,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du chargement de la photo.'),
            backgroundColor: AppColors.erreur,
          ),
        );
      }
    } finally {
      setState(() => _uploadPhoto = false);
    }
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
          'Mon profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // photo de profil cliquable
                    Center(
                      child: GestureDetector(
                        onTap: _changerPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.bleuClair,
                              backgroundImage:
                                  utilisateur.photoUrl != null
                                      ? NetworkImage(utilisateur.photoUrl!)
                                      : null,
                              child:
                                  utilisateur.photoUrl == null
                                      ? Text(
                                        utilisateur.nomComplet.isNotEmpty
                                            ? utilisateur.nomComplet[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.bleuFonce,
                                        ),
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.bleuFonce,
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    _uploadPhoto
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      utilisateur.nomComplet,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _couleurRole(
                          utilisateur.role.name,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _labelRole(utilisateur.role.name),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _couleurRole(utilisateur.role.name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // informations du profil
                    _sectionInfo('Informations personnelles', [
                      _ligneInfo(
                        Icons.person_outline,
                        'Nom complet',
                        utilisateur.nomComplet,
                      ),
                      _ligneInfo(
                        Icons.email_outlined,
                        'Email',
                        utilisateur.email,
                      ),
                      _ligneInfo(
                        Icons.phone_outlined,
                        'Téléphone',
                        utilisateur.telephone ?? 'Non renseigné',
                      ),
                    ]),
                    const SizedBox(height: 16),

                    if (utilisateur.estLocataire) ...[
                      _sectionInfo('Documents', [
                        _ligneInfo(
                          Icons.badge_outlined,
                          "Pièce d'identité",
                          utilisateur.carteIdentiteUrl != null
                              ? 'Téléchargée'
                              : 'Non téléchargée',
                          statut:
                              utilisateur.carteVerifiee
                                  ? 'vérifié'
                                  : utilisateur.carteIdentiteUrl != null
                                  ? 'en attente'
                                  : 'manquant',
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // bouton modifier le profil
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _afficherModifierProfil(
                              context,
                              ref,
                              utilisateur,
                            ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Modifier le profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bleuFonce,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // bouton déconnexion
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .deconnecter();
                          if (context.mounted) context.go(AppRoutes.connexion);
                        },
                        icon: const Icon(Icons.logout, color: AppColors.erreur),
                        label: const Text(
                          'Se déconnecter',
                          style: TextStyle(color: AppColors.erreur),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.erreur),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _sectionInfo(String titre, List<Widget> lignes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 12),
          ...lignes,
        ],
      ),
    );
  }

  Widget _ligneInfo(
    IconData icone,
    String label,
    String valeur, {
    String? statut,
  }) {
    Color couleurStatut = AppColors.grisMoyen;
    if (statut == 'vérifié') couleurStatut = AppColors.succes;
    if (statut == 'en attente') couleurStatut = AppColors.avertissement;
    if (statut == 'manquant') couleurStatut = AppColors.erreur;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.bleuFonce),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.texteLeger,
                  ),
                ),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.texte,
                  ),
                ),
              ],
            ),
          ),
          if (statut != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: couleurStatut.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: couleurStatut,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _couleurRole(String role) {
    switch (role) {
      case 'proprietaire':
        return AppColors.vertProprietaire;
      case 'agent':
        return AppColors.bleuAgent;
      case 'locataire':
        return AppColors.tealLocataire;
      case 'admin':
        return AppColors.violetAdmin;
      default:
        return AppColors.bleuFonce;
    }
  }

  String _labelRole(String role) {
    switch (role) {
      case 'proprietaire':
        return '🏠 Propriétaire';
      case 'agent':
        return '🤝 Agent';
      case 'locataire':
        return '🔍 Locataire';
      case 'admin':
        return '🛡️ Admin';
      default:
        return role;
    }
  }

  void _afficherModifierProfil(
    BuildContext context,
    WidgetRef ref,
    utilisateur,
  ) {
    final nomCtrl = TextEditingController(text: utilisateur.nomComplet);
    final telCtrl = TextEditingController(text: utilisateur.telephone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modifier le profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texte,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(utilisateur.uid)
                          .update({
                            'nomComplet': nomCtrl.text.trim(),
                            'telephone': telCtrl.text.trim(),
                          });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil mis à jour !'),
                            backgroundColor: AppColors.succes,
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
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
