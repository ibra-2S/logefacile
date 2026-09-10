import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

const _bleuFonce = Color(0xFF1A237E);

/// Pays / indicatif proposés pour le numéro de téléphone.
class _Pays {
  final String nom;
  final String drapeau;
  final String indicatif; // sans le « + »
  final int longueurMin;
  final int longueurMax;

  const _Pays(
    this.nom,
    this.drapeau,
    this.indicatif,
    this.longueurMin, [
    int? longueurMax,
  ]) : longueurMax = longueurMax ?? longueurMin;
}

const _paysListe = <_Pays>[
  _Pays('Guinée', '🇬🇳', '224', 9),
  _Pays('Sénégal', '🇸🇳', '221', 9),
  _Pays('Mali', '🇲🇱', '223', 8),
  _Pays("Côte d'Ivoire", '🇨🇮', '225', 10),
  _Pays('Guinée-Bissau', '🇬🇼', '245', 7, 9),
  _Pays('Sierra Leone', '🇸🇱', '232', 8, 9),
  _Pays('Liberia', '🇱🇷', '231', 7, 9),
  _Pays('Gambie', '🇬🇲', '220', 7),
  _Pays('Mauritanie', '🇲🇷', '222', 8),
  _Pays('France', '🇫🇷', '33', 9),
];

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
  _Pays _paysSel = _paysListe.first;

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
      final errTel = _validerTelephone();
      if (errTel != null) return errTel;
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

  /// Retire espaces / séparateurs et l'éventuel indicatif (« + », « 00 » ou
  /// l'indicatif du pays sélectionné) d'une saisie, en renvoyant à la fois
  /// l'indicatif détecté dans le champ (ou `null`) et le numéro national.
  ({String? indicatifSaisi, String national}) _decouperNumero(String brut) {
    var s = brut.replaceAll(RegExp(r'[\s.\-()/]'), '');
    String? indic;

    if (s.startsWith('+') || s.startsWith('00')) {
      s = s.startsWith('+') ? s.substring(1) : s.substring(2);
      indic = _indicatifConnu(s);
      if (indic != null) s = s.substring(indic.length);
    } else if (s.startsWith(_paysSel.indicatif) &&
        s.length > _paysSel.longueurMax) {
      // ex : « 224620000000 » saisi sans + ni 00
      indic = _paysSel.indicatif;
      s = s.substring(indic.length);
    }

    if (s.startsWith('0')) s = s.substring(1); // 0 national
    return (indicatifSaisi: indic, national: s);
  }

  /// Cherche, parmi les indicatifs connus, le plus long qui préfixe [digits].
  String? _indicatifConnu(String digits) {
    final trouves =
        _paysListe.map((p) => p.indicatif).where(digits.startsWith).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    return trouves.isEmpty ? null : trouves.first;
  }

  /// Valide le numéro par rapport à l'indicatif choisi. `null` = OK
  /// (le téléphone reste optionnel).
  String? _validerTelephone() {
    final brut = _telCtrl.text.trim();
    if (brut.isEmpty) return null;

    if (brut.startsWith('+') && _indicatifConnu(brut.substring(1)) == null) {
      return "Indicatif non reconnu. Choisissez le pays dans la liste et "
          "saisissez le numéro sans indicatif.";
    }

    final d = _decouperNumero(brut);
    if (d.indicatifSaisi != null && d.indicatifSaisi != _paysSel.indicatif) {
      return "L'indicatif du numéro (+${d.indicatifSaisi}) ne correspond pas "
          "au pays sélectionné (${_paysSel.drapeau} +${_paysSel.indicatif}).";
    }

    if (!RegExp(r'^\d+$').hasMatch(d.national)) {
      return 'Le numéro ne doit contenir que des chiffres.';
    }

    final n = d.national.length;
    if (n < _paysSel.longueurMin || n > _paysSel.longueurMax) {
      return 'Numéro invalide pour ${_paysSel.nom} : '
          '${_formatLongueur()} attendus (sans l\'indicatif).';
    }
    return null;
  }

  /// Numéro au format international « +224620000000 », ou `null` si vide.
  String? _telephoneComplet() {
    if (_telCtrl.text.trim().isEmpty) return null;
    final d = _decouperNumero(_telCtrl.text.trim());
    return '+${_paysSel.indicatif}${d.national}';
  }

  String _formatLongueur() =>
      _paysSel.longueurMin == _paysSel.longueurMax
          ? '${_paysSel.longueurMin} chiffres'
          : '${_paysSel.longueurMin} à ${_paysSel.longueurMax} chiffres';

  Future<void> _choisirPays() async {
    final choix = await showModalBottomSheet<_Pays>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                const Text(
                  'Indicatif du pays',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        _paysListe
                            .map(
                              (p) => ListTile(
                                leading: Text(
                                  p.drapeau,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                title: Text(p.nom),
                                trailing: Text(
                                  '+${p.indicatif}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                selected: p.indicatif == _paysSel.indicatif,
                                onTap: () => Navigator.pop(ctx, p),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
    if (choix != null) {
      setState(() {
        _paysSel = choix;
        _erreur = _validerTelephone();
      });
    }
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
            telephone: _telephoneComplet(),
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
            const Text(
              'Téléphone',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _choisirPays,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _paysSel.drapeau,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${_paysSel.indicatif}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
                    ],
                    decoration: _deco('Numéro (optionnel)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_paysSel.nom} · ${_formatLongueur()} attendus, sans l\'indicatif',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
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
                    _mdpVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
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
                  : '${_paysSel.drapeau} ${_telephoneComplet()}',
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
