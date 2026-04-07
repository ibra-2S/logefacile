import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();
  bool _mdpVisible = false;
  bool _chargement = false;
  String? _erreur;
  late UserRole _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    _role = extra is UserRole ? extra : UserRole.locataire;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (_nomCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _mdpCtrl.text.trim().isEmpty) {
      setState(
        () => _erreur = 'Veuillez remplir tous les champs obligatoires.',
      );
      return;
    }

    if (_mdpCtrl.text != _confirmMdpCtrl.text) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }

    if (_mdpCtrl.text.length < 6) {
      setState(
        () => _erreur = 'Le mot de passe doit contenir au moins 6 caractères.',
      );
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .inscrire(
            email: _emailCtrl.text.trim(),
            motDePasse: _mdpCtrl.text.trim(),
            nomComplet: _nomCtrl.text.trim(),
            role: _role,
            telephone:
                _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          );

      if (!mounted) return;

      // afficher le dialogue de succès
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Compte créé !',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Un email de confirmation a été envoyé à ${_emailCtrl.text.trim()}.\n\nVeuillez confirmer votre email avant de vous connecter.',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go(AppRoutes.connexion);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Aller à la connexion',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String _titreRole() {
    switch (_role) {
      case UserRole.proprietaire:
        return '🏠 Compte Propriétaire';
      case UserRole.agent:
        return '🤝 Compte Agent';
      case UserRole.locataire:
        return '🔍 Compte Locataire';
      case UserRole.admin:
        return '🛡️ Compte Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                _titreRole(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Créez votre compte gratuitement',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // formulaire
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _champTexte('Nom complet *', 'Votre nom complet', _nomCtrl),
                    const SizedBox(height: 14),
                    _champTexte(
                      'Email *',
                      'Votre adresse email',
                      _emailCtrl,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _champTexte(
                      'Téléphone',
                      'Votre numéro (optionnel)',
                      _telCtrl,
                      type: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Mot de passe *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _mdpCtrl,
                      obscureText: !_mdpVisible,
                      decoration: _styleChamp('6 caractères minimum').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _mdpVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed:
                              () => setState(() => _mdpVisible = !_mdpVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Confirmer le mot de passe *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmMdpCtrl,
                      obscureText: true,
                      decoration: _styleChamp('Répétez votre mot de passe'),
                    ),

                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _erreur!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _chargement ? null : _sInscrire,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
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
                                  "S'inscrire",
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Déjà un compte ?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.connexion),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: _styleChamp(hint),
        ),
      ],
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
