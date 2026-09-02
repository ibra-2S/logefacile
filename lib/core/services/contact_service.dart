import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une conversation WhatsApp (ou un appel téléphonique) avec un
/// propriétaire / agent depuis son numéro enregistré dans le profil.
class ContactService {
  /// indicatif par défaut si le numéro n'en contient pas (Guinée : +224)
  static const _indicatifParDefaut = '224';

  /// Transforme un numéro saisi librement ("620 00 00 00", "+224620000000",
  /// "00224 620-00-00-00"…) en un numéro international sans "+" ni espaces,
  /// utilisable par l'API wa.me. Retourne `null` si le numéro est vide.
  static String? normaliserNumero(String? brut) {
    if (brut == null) return null;
    var n = brut.trim();
    if (n.isEmpty) return null;

    final plus = n.startsWith('+');
    // ne garder que les chiffres
    n = n.replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty) return null;

    if (plus) return n; // déjà au format international
    if (n.startsWith('00')) return n.substring(2); // 00224… -> 224…
    if (n.startsWith(_indicatifParDefaut)) return n;

    // numéro local guinéen : on retire un éventuel 0 initial puis on préfixe
    if (n.startsWith('0')) n = n.substring(1);
    return '$_indicatifParDefaut$n';
  }

  /// true si l'on dispose d'un numéro exploitable
  static bool aUnNumero(String? brut) => normaliserNumero(brut) != null;

  /// Ouvre WhatsApp avec le message pré-rempli. Tente d'abord l'application
  /// WhatsApp, puis bascule sur wa.me (navigateur) si elle n'est pas installée.
  /// Retourne false si aucune option n'a pu être ouverte.
  static Future<bool> ouvrirWhatsApp({
    required String? telephone,
    String? message,
  }) async {
    final numero = normaliserNumero(telephone);
    if (numero == null) return false;

    final aMessage = message != null && message.isNotEmpty;
    final texteEncode = aMessage ? Uri.encodeComponent(message) : '';

    final appUri = Uri.parse(
      'whatsapp://send?phone=$numero${aMessage ? '&text=$texteEncode' : ''}',
    );
    final webUri = Uri.parse(
      'https://wa.me/$numero${aMessage ? '?text=$texteEncode' : ''}',
    );

    try {
      if (await canLaunchUrl(appUri)) {
        return launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // certaines plateformes lèvent si le schéma n'est pas déclaré : on ignore
    }
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Lance un appel téléphonique classique.
  static Future<bool> appeler(String? telephone) async {
    final numero = normaliserNumero(telephone);
    if (numero == null) return false;
    return launchUrl(Uri.parse('tel:+$numero'));
  }

  /// Copie le numéro dans le presse-papiers (repli si rien ne s'ouvre).
  static Future<void> copierNumero(String? telephone) async {
    final numero = normaliserNumero(telephone);
    if (numero == null) return;
    await Clipboard.setData(ClipboardData(text: '+$numero'));
  }
}
