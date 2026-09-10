import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// Écran de connexion de la console d'administration.
///
/// Ne gère que l'authentification e-mail / mot de passe. La vérification du
/// rôle « admin » est faite plus loin par [AdminWebShell] : un compte non
/// admin qui se connecte ici verra l'écran « Accès réservé ».
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _mdpVisible = false;
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (_emailCtrl.text.trim().isEmpty || _mdpCtrl.text.isEmpty) {
      setState(() => _erreur = 'Renseignez votre e-mail et votre mot de passe.');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).connecter(
            email: _emailCtrl.text.trim(),
            motDePasse: _mdpCtrl.text.trim(),
          );
      // Succès : le routeur bascule automatiquement vers la console.
    } catch (e) {
      setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _motDePasseOublie() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Renseignez d\'abord votre e-mail.');
      return;
    }
    try {
      await ref
          .read(authServiceProvider)
          .reinitialiserMotDePasse(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de réinitialisation envoyé.'),
          backgroundColor: AppColors.succes,
        ),
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bleuFonce,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // le PNG a beaucoup de marge transparente verticale :
                  // on ne garde que la bande centrale.
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      heightFactor: 0.58,
                      child: Image.asset('assets/images/logo.png', width: 220),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Console d\'administration',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'E-mail',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        onSubmitted: (_) => _seConnecter(),
                        decoration: _deco('admin@logefacile.com'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _mdpCtrl,
                        obscureText: !_mdpVisible,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _seConnecter(),
                        decoration: _deco('Votre mot de passe').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mdpVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _mdpVisible = !_mdpVisible),
                          ),
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.erreur.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.erreur.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _erreur!,
                            style: const TextStyle(
                              color: AppColors.erreur,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _chargement ? null : _motDePasseOublie,
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _chargement ? null : _seConnecter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bleuFonce,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _chargement
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
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
                const SizedBox(height: 16),
                const Text(
                  'Accès réservé aux administrateurs LogeFacile.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
