import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Écran de contenu statique réutilisable (confidentialité, conditions…).
class LegalScreen extends StatelessWidget {
  final String titre;
  final List<LegalSection> sections;
  final String? majAJour;

  const LegalScreen({
    super.key,
    required this.titre,
    required this.sections,
    this.majAJour,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        foregroundColor: Colors.white,
        title: Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (majAJour != null) ...[
            Text(
              'Dernière mise à jour : $majAJour',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.texteLeger,
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final section in sections) ...[
            if (section.titre != null) ...[
              Text(
                section.titre!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texte,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              section.corps,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondaire,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class LegalSection {
  final String? titre;
  final String corps;
  const LegalSection({this.titre, required this.corps});
}

// ── Contenus ──────────────────────────────────────────────────────────

const confidentialiteSections = <LegalSection>[
  LegalSection(
    corps:
        "LogeFacile accorde de l'importance à la protection de vos données "
        "personnelles. Cette politique explique quelles informations nous "
        "collectons et comment elles sont utilisées.",
  ),
  LegalSection(
    titre: 'Données collectées',
    corps:
        "• Informations de compte : nom, adresse e-mail, numéro de téléphone.\n"
        "• Contenu que vous publiez : annonces, photos, messages.\n"
        "• Données techniques : type d'appareil, journaux d'erreurs.\n"
        "• Localisation approximative, uniquement lorsque vous ajoutez la "
        "position d'un bien.",
  ),
  LegalSection(
    titre: 'Utilisation des données',
    corps:
        "Vos données servent à faire fonctionner l'application : afficher les "
        "annonces, mettre en relation locataires et propriétaires, envoyer les "
        "notifications, assurer la sécurité et modérer les contenus signalés.",
  ),
  LegalSection(
    titre: 'Partage',
    corps:
        "Vos coordonnées ne sont visibles par un autre utilisateur que lorsque "
        "vous engagez une conversation ou une demande de visite. Nous ne "
        "vendons aucune donnée à des tiers. L'hébergement est assuré par "
        "Google Firebase et le stockage des images par Cloudinary.",
  ),
  LegalSection(
    titre: 'Vos droits',
    corps:
        "Vous pouvez consulter et modifier vos informations depuis l'onglet "
        "Profil, et supprimer définitivement votre compte depuis Paramètres. "
        "Pour toute question, contactez-nous via la rubrique « Nous contacter ».",
  ),
];

const conditionsSections = <LegalSection>[
  LegalSection(
    corps:
        "En utilisant LogeFacile, vous acceptez les présentes conditions "
        "d'utilisation. L'application met en relation des personnes cherchant "
        "un logement en location avec des propriétaires et des agents.",
  ),
  LegalSection(
    titre: 'Compte utilisateur',
    corps:
        "Vous devez fournir des informations exactes et garder votre mot de "
        "passe confidentiel. Vous êtes responsable de l'activité de votre "
        "compte.",
  ),
  LegalSection(
    titre: 'Publication des annonces',
    corps:
        "Les propriétaires et agents s'engagent à publier des annonces "
        "véridiques : prix réel, photos du bien concerné, disponibilité à "
        "jour. Toute annonce frauduleuse ou trompeuse peut être signalée et "
        "supprimée.",
  ),
  LegalSection(
    titre: 'Comportement',
    corps:
        "Sont interdits : le harcèlement, les propos injurieux, l'usurpation "
        "d'identité, la demande de paiement en dehors des modalités convenues "
        "entre les parties. LogeFacile n'intervient pas dans les transactions "
        "financières et ne saurait être tenu responsable d'un litige entre "
        "utilisateurs.",
  ),
  LegalSection(
    titre: 'Résiliation',
    corps:
        "Nous pouvons suspendre un compte qui enfreint ces conditions. Vous "
        "pouvez supprimer votre compte à tout moment depuis les Paramètres.",
  ),
];
