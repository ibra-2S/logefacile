import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  static const _email = 'support@logefacile.gn';
  static const _telephone = '+224 620 00 00 00';

  final _messageCtrl = TextEditingController();
  String _sujet = 'Question générale';
  bool _envoi = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _copier(String valeur, String libelle) async {
    await Clipboard.setData(ClipboardData(text: valeur));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$libelle copié'),
        backgroundColor: AppColors.succes,
      ),
    );
  }

  Future<void> _envoyer() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écrivez votre message'),
          backgroundColor: AppColors.avertissement,
        ),
      );
      return;
    }
    final utilisateur = ref.read(utilisateurActuelProvider).asData?.value;
    setState(() => _envoi = true);
    try {
      await FirebaseFirestore.instance.collection('support_messages').add({
        'uid': utilisateur?.uid,
        'nom': utilisateur?.nomComplet,
        'email': utilisateur?.email,
        'sujet': _sujet,
        'message': message,
        'traite': false,
        'dateCreation': Timestamp.fromDate(DateTime.now()),
      });
      if (!mounted) return;
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message envoyé. Nous vous répondrons par e-mail.'),
          backgroundColor: AppColors.succes,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Échec de l'envoi. Réessayez."),
          backgroundColor: AppColors.erreur,
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
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
          'Nous contacter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _carteCoordonnee(
            Icons.mail_outline,
            'E-mail',
            _email,
            () => _copier(_email, 'E-mail'),
          ),
          const SizedBox(height: 10),
          _carteCoordonnee(
            Icons.phone_outlined,
            'Téléphone',
            _telephone,
            () => _copier(_telephone, 'Numéro'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Envoyer un message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                  'Sujet',
                  style: TextStyle(fontSize: 12, color: AppColors.texteLeger),
                ),
                DropdownButton<String>(
                  value: _sujet,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    'Question générale',
                    'Problème technique',
                    'Signaler un abus',
                    'Suggestion',
                    'Autre',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _sujet = v ?? _sujet),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Décrivez votre demande…',
                    filled: true,
                    fillColor: AppColors.fond,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _envoyer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bleuFonce,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child:
                        _envoi
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Envoyer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteCoordonnee(
    IconData icone,
    String label,
    String valeur,
    VoidCallback onCopier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Icon(icone, color: AppColors.bleuFonce),
          const SizedBox(width: 14),
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.texte,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopier,
            icon: const Icon(Icons.copy, size: 18, color: AppColors.grisMoyen),
            tooltip: 'Copier',
          ),
        ],
      ),
    );
  }
}
