import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _mdpVisible = false;
  bool _chargement = false;
  String? _erreur;
  bool _emailNonVerifie = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    setState(() {
      _chargement = true;
      _erreur = null;
      _emailNonVerifie = false;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .connecter(
            email: _emailCtrl.text.trim(),
            motDePasse: _mdpCtrl.text.trim(),
          );

      if (!mounted) return;

      final utilisateur = ref.read(authNotifierProvider).asData?.value;
      if (utilisateur != null) {
        _redirigerSelonRole(utilisateur.role);
      }
    } catch (e) {
      final erreur = e.toString();
      setState(() {
        _erreur = erreur;
        // détecter si c'est l'erreur de vérification email
        if (erreur.contains('confirmer votre email')) {
          _emailNonVerifie = true;
        }
      });
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _renvoyerEmail() async {
    if (_emailCtrl.text.trim().isEmpty || _mdpCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Entrez votre email et mot de passe d\'abord.');
      return;
    }

    setState(() => _chargement = true);
    try {
      await ref
          .read(authServiceProvider)
          .renvoyerEmailVerification(
            _emailCtrl.text.trim(),
            _mdpCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de vérification renvoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _seConnecterGoogle() async {
    setState(() => _chargement = true);
    try {
      await ref.read(authNotifierProvider.notifier).connecterAvecGoogle();
      if (!mounted) return;
      final utilisateur = ref.read(authNotifierProvider).asData?.value;
      if (utilisateur != null) _redirigerSelonRole(utilisateur.role);
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _motDePasseOublie() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Entrez votre email d\'abord.');
      return;
    }
    try {
      await ref
          .read(authServiceProvider)
          .reinitialiserMotDePasse(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de réinitialisation envoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    }
  }

  void _redirigerSelonRole(UserRole role) {
    switch (role) {
      case UserRole.proprietaire:
      case UserRole.agent:
        context.go(AppRoutes.tableauBordProprietaire);
        break;
      case UserRole.locataire:
        context.go(AppRoutes.rechercheLocataire);
        break;
      case UserRole.admin:
        context.go(AppRoutes.tableauBordAdmin);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E7EC6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // ── Logo principal ──
                Image.asset(
                  'assets/images/logo.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Connectez-vous à votre compte',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // ── Formulaire ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _styleChamp('Entrez votre email'),
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
                        decoration: _styleChamp(
                          'Entrez votre mot de passe',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mdpVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () =>
                                    setState(() => _mdpVisible = !_mdpVisible),
                          ),
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _erreur!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                              // bouton renvoyer email si email non vérifié
                              if (_emailNonVerifie) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _renvoyerEmail,
                                  child: const Text(
                                    'Renvoyer l\'email de confirmation →',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _motDePasseOublie,
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _chargement ? null : _seConnecter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF175295),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _chargement
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Bouton Google ──
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white30)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white30)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _chargement ? null : _seConnecterGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 20,
                    ),
                    label: const Text(
                      'Continuer avec Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Pas encore de compte ?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.choixRole),
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _styleChamp(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
