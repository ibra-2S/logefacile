import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
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
  bool _uploadPiece = false;
  bool _selectionEnCours = false;

  Future<void> _televerserPiece(UserModel utilisateur) async {
    if (_selectionEnCours || _uploadPiece) return;
    _selectionEnCours = true;
    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (_) {
      return;
    } finally {
      _selectionEnCours = false;
    }
    if (image == null) return;

    setState(() => _uploadPiece = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      final jsonData = jsonDecode(await response.stream.bytesToString());

      if (response.statusCode == 200) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(utilisateur.uid)
            .update({
              'carteIdentiteUrl': jsonData['secure_url'],
              'carteVerifiee': false,
            });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Pièce d'identité envoyée. Elle sera vérifiée sous 48 h.",
              ),
              backgroundColor: AppColors.succes,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Échec de l'envoi. Réessayez."),
            backgroundColor: AppColors.erreur,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadPiece = false);
    }
  }

  Future<void> _changerPhoto() async {
    if (_selectionEnCours || _uploadPhoto) return;
    _selectionEnCours = true;
    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (_) {
      return;
    } finally {
      _selectionEnCours = false;
    }
    if (image == null) return;

    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;

    setState(() => _uploadPhoto = true);

    try {
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
      if (mounted) setState(() => _uploadPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = ref.watch(utilisateurActuelProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body:
          utilisateur == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _entete(utilisateur),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _carteInfosPerso(utilisateur),
                        const SizedBox(height: 20),

                        _groupe('Compte', [
                          _tuile(
                            Icons.edit_outlined,
                            'Modifier le profil',
                            onTap:
                                () => _afficherModifierProfil(
                                  context,
                                  ref,
                                  utilisateur,
                                ),
                          ),
                          _tuile(
                            Icons.settings_outlined,
                            'Paramètres',
                            onTap: () => context.push(AppRoutes.parametres),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        _groupe('Support', [
                          _tuile(
                            Icons.help_outline,
                            "Centre d'aide",
                            onTap: () => context.push(AppRoutes.centreAide),
                          ),
                          _tuile(
                            Icons.mail_outline,
                            'Nous contacter',
                            onTap: () => context.push(AppRoutes.contact),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        _groupe('À propos', [
                          _tuile(
                            Icons.privacy_tip_outlined,
                            'Politique de confidentialité',
                            onTap:
                                () => context.push(AppRoutes.confidentialite),
                          ),
                          _tuile(
                            Icons.description_outlined,
                            "Conditions d'utilisation",
                            onTap: () => context.push(AppRoutes.conditions),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .deconnecter();
                              if (context.mounted) {
                                context.go(AppRoutes.connexion);
                              }
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.erreur,
                            ),
                            label: const Text(
                              'Se déconnecter',
                              style: TextStyle(
                                color: AppColors.erreur,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.erreur),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LogeFacile · version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.texteLeger,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  // ── en-tête dégradé avec avatar ──
  Widget _entete(UserModel utilisateur) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bleuFonce, AppColors.bleuMoyen],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _changerPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      utilisateur.photoUrl != null
                          ? NetworkImage(utilisateur.photoUrl!)
                          : null,
                  child:
                      utilisateur.photoUrl == null
                          ? Text(
                            utilisateur.nomComplet.isNotEmpty
                                ? utilisateur.nomComplet[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bleuFonce, width: 2),
                    ),
                    child:
                        _uploadPhoto
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: AppColors.bleuFonce,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.camera_alt,
                              color: AppColors.bleuFonce,
                              size: 14,
                            ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            utilisateur.nomComplet,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            utilisateur.email,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _labelRole(utilisateur.role.name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _couleurRole(utilisateur.role.name),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteInfosPerso(UserModel utilisateur) {
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
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 12),
          _ligneInfo(
            Icons.person_outline,
            'Nom complet',
            utilisateur.nomComplet,
          ),
          _ligneInfo(Icons.email_outlined, 'Email', utilisateur.email),
          _ligneInfo(
            Icons.phone_outlined,
            'Téléphone',
            utilisateur.telephone ?? 'Non renseigné',
          ),
          if (utilisateur.estLocataire || utilisateur.estProprietaireOuAgent)
            _lignePiece(utilisateur),
        ],
      ),
    );
  }

  Widget _lignePiece(UserModel utilisateur) {
    final aUnePiece = utilisateur.carteIdentiteUrl != null &&
        utilisateur.carteIdentiteUrl!.isNotEmpty;
    final statut =
        utilisateur.carteVerifiee
            ? 'vérifié'
            : aUnePiece
            ? 'en attente'
            : 'manquant';
    Color couleurStatut = AppColors.grisMoyen;
    if (statut == 'vérifié') couleurStatut = AppColors.succes;
    if (statut == 'en attente') couleurStatut = AppColors.avertissement;
    if (statut == 'manquant') couleurStatut = AppColors.erreur;

    return InkWell(
      onTap: _uploadPiece ? null : () => _televerserPiece(utilisateur),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Row(
          children: [
            const Icon(
              Icons.badge_outlined,
              size: 20,
              color: AppColors.bleuFonce,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pièce d'identité",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.texteLeger,
                    ),
                  ),
                  Text(
                    aUnePiece
                        ? 'Envoyée · appuyez pour remplacer'
                        : 'Appuyez pour envoyer une photo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.texte,
                    ),
                  ),
                ],
              ),
            ),
            if (_uploadPiece)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
      ),
    );
  }

  Widget _groupe(String titre, List<Widget> tuiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.texteLeger,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            children: [
              for (var i = 0; i < tuiles.length; i++) ...[
                tuiles[i],
                if (i != tuiles.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tuile(IconData icone, String titre, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icone, size: 20, color: AppColors.bleuFonce),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titre,
                style: const TextStyle(fontSize: 14, color: AppColors.texte),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.grisMoyen,
            ),
          ],
        ),
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
    UserModel utilisateur,
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
