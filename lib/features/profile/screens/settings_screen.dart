import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  Future<void> _chargerPreferences() async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) {
      setState(() => _chargement = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(utilisateur.uid)
              .get();
      if (!mounted) return;
      setState(() {
        _notifications = doc.data()?['notificationsActives'] ?? true;
        _chargement = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _majNotifications(bool valeur) async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    setState(() => _notifications = valeur);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(utilisateur.uid)
        .update({'notificationsActives': valeur});
  }

  Future<void> _changerMotDePasse() async {
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    if (utilisateur == null) return;
    try {
      await ref
          .read(authServiceProvider)
          .reinitialiserMotDePasse(utilisateur.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de réinitialisation envoyé à ${utilisateur.email}'),
          backgroundColor: AppColors.succes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.erreur),
      );
    }
  }

  Future<void> _supprimerCompte() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Supprimer le compte'),
            content: const Text(
              'Cette action est définitive. Vos annonces, favoris et messages '
              'seront perdus. Voulez-vous continuer ?',
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
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
    if (confirme != true) return;

    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    final authUser = FirebaseAuth.instance.currentUser;
    if (utilisateur == null || authUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(utilisateur.uid)
          .delete();
      await authUser.delete();
      if (!mounted) return;
      context.go(AppRoutes.connexion);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 'requires-recent-login'
              ? 'Pour des raisons de sécurité, reconnectez-vous puis réessayez.'
              : 'Échec de la suppression. Réessayez.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.erreur),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        foregroundColor: Colors.white,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body:
          _chargement
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _groupe('Notifications', [
                    SwitchListTile(
                      value: _notifications,
                      onChanged: _majNotifications,
                      activeThumbColor: AppColors.bleuFonce,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Notifications push',
                        style: TextStyle(fontSize: 14, color: AppColors.texte),
                      ),
                      subtitle: const Text(
                        'Messages, demandes de visite, alertes',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _groupe('Préférences', [
                    _ligne(Icons.language, 'Langue', valeur: 'Français'),
                    const Divider(height: 1),
                    _ligne(
                      Icons.brightness_6_outlined,
                      'Thème',
                      valeur: 'Système',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _groupe('Sécurité', [
                    _ligne(
                      Icons.lock_reset,
                      'Changer le mot de passe',
                      onTap: _changerMotDePasse,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _groupe('Zone de danger', [
                    _ligne(
                      Icons.delete_forever,
                      'Supprimer mon compte',
                      couleur: AppColors.erreur,
                      onTap: _supprimerCompte,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'LogeFacile · version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.texteLeger,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _groupe(String titre, List<Widget> enfants) {
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
          child: Column(children: enfants),
        ),
      ],
    );
  }

  Widget _ligne(
    IconData icone,
    String titre, {
    String? valeur,
    VoidCallback? onTap,
    Color? couleur,
  }) {
    final c = couleur ?? AppColors.texte;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icone, size: 20, color: couleur ?? AppColors.bleuFonce),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(fontSize: 14, color: c),
              ),
            ),
            if (valeur != null)
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.texteLeger,
                ),
              ),
            if (onTap != null)
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
}
