import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

const _bleuFonce = Color(0xFF1A237E);

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
  int _etape = 0;
  late UserRole _role;

  static const _titresEtapes = ['Identité', 'Connexion', 'Confirmation'];

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

  String? _validerEtape(int etape) {
    if (etape == 0) {
      if (_nomCtrl.text.trim().isEmpty) return 'Indiquez votre nom complet.';
    }
    if (etape == 1) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) return 'Indiquez votre adresse e-mail.';
      if (!email.contains('@') || !email.contains('.')) {
        return 'Adresse e-mail invalide.';
      }
      if (_mdpCtrl.text.length < 6) {
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      }
      if (_mdpCtrl.text != _confirmMdpCtrl.text) {
        return 'Les mots de passe ne correspondent pas.';
      }
    }
    return null;
  }

  void _suivant() {
    final erreur = _validerEtape(_etape);
    if (erreur != null) {
      setState(() => _erreur = erreur);
      return;
    }
    setState(() {
      _erreur = null;
      _etape++;
    });
  }

  void _precedent() {
    if (_etape == 0) {
      context.pop();
      return;
    }
    setState(() {
      _erreur = null;
      _etape--;
    });
  }

  Future<void> _sInscrire() async {
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
                    'Un email de confirmation a été envoyé à ${_emailCtrl.text.trim()}.\n\n⚠️ Vous devez cliquer sur le lien dans cet email AVANT de pouvoir vous connecter.\n\nVérifiez aussi vos spams !',
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
                        backgroundColor: _bleuFonce,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'OK',
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
    final dernier = _etape == 2;

    return Scaffold(
      backgroundColor: _bleuFonce,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _precedent,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                _titreRole(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Étape ${_etape + 1} sur 3 · ${_titresEtapes[_etape]}',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // barre de progression
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            i <= _etape ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // carte du formulaire
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.15, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_etape),
                        child: _contenuEtape(),
                      ),
                    ),

                    if (_erreur != null) ...[
                      const SizedBox(height: 14),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _chargement ? null : _precedent,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _bleuFonce),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _etape == 0 ? 'Annuler' : 'Retour',
                              style: const TextStyle(color: _bleuFonce),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed:
                                _chargement
                                    ? null
                                    : (dernier ? _sInscrire : _suivant),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _bleuFonce,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _chargement
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      dernier
                                          ? 'Créer mon compte'
                                          : 'Suivant',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
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

  Widget _contenuEtape() {
    switch (_etape) {
      case 0:
        return Column(
          key: const ValueKey('etape0'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faisons connaissance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Comment devons-nous vous appeler ?',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            _champ('Nom complet *', 'Votre nom et prénom', _nomCtrl),
            const SizedBox(height: 14),
            _champ(
              'Téléphone',
              'Numéro (optionnel)',
              _telCtrl,
              type: TextInputType.phone,
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey('etape1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vos identifiants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ils serviront à vous connecter.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            _champ(
              'Email *',
              'exemple@email.com',
              _emailCtrl,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            const Text(
              'Mot de passe *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _mdpCtrl,
              obscureText: !_mdpVisible,
              decoration: _deco('6 caractères minimum').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _mdpVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(() => _mdpVisible = !_mdpVisible),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Confirmer le mot de passe *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmMdpCtrl,
              obscureText: !_mdpVisible,
              decoration: _deco('Répétez le mot de passe'),
            ),
          ],
        );
      default:
        return Column(
          key: const ValueKey('etape2'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vérifiez vos informations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _recap('Profil', _titreRole()),
            _recap('Nom', _nomCtrl.text.trim()),
            _recap('Email', _emailCtrl.text.trim()),
            _recap(
              'Téléphone',
              _telCtrl.text.trim().isEmpty
                  ? 'Non renseigné'
                  : _telCtrl.text.trim(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bleuFonce.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Un e-mail de confirmation vous sera envoyé. Cliquez sur le '
                'lien avant de vous connecter.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        );
    }
  }

  Widget _recap(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _champ(
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
          decoration: _deco(hint),
        ),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
