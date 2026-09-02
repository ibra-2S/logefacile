import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  // ── questions communes à tous les profils ──
  static const _commun = <List<String>>[
    [
      "J'ai oublié mon mot de passe",
      "Sur l'écran de connexion, utilisez « Mot de passe oublié », ou depuis "
          "Profil → Paramètres → « Changer le mot de passe » pour recevoir un "
          "e-mail de réinitialisation.",
    ],
    [
      'Comment modifier mes informations ?',
      "Onglet Profil → « Modifier le profil » pour le nom et le téléphone, "
          "ou appuyez sur votre photo pour la changer.",
    ],
    [
      'Comment vérifier mon identité ?',
      "Dans Profil, appuyez sur la ligne « Pièce d'identité » et envoyez une "
          "photo de votre pièce. Un badge « Vérifié » apparaît une fois le "
          "contrôle effectué ; cela rassure les autres utilisateurs.",
    ],
  ];

  static const _locataire = <List<String>>[
    [
      'Comment rechercher un logement ?',
      "Depuis l'onglet « Recherche », tapez un quartier ou une ville, puis "
          "affinez avec le bouton filtres (prix, type de bien, nombre de "
          "pièces). Chaque annonce affiche sa position sur une carte.",
    ],
    [
      'Comment demander une visite ?',
      "Sur la page d'une annonce, appuyez sur « Demander une visite » et "
          "choisissez le jour ET l'heure. Le propriétaire ou l'agent reçoit la "
          "demande et peut l'accepter ou la refuser.",
    ],
    [
      'Où suivre mes demandes de visite ?',
      "Dans l'onglet « Demandes » (le bouton central de la barre du bas). "
          "Vous y voyez le statut de chaque demande et pouvez l'annuler.",
    ],
    [
      'Comment contacter un propriétaire ou un agent ?',
      "Ouvrez l'annonce et appuyez sur « Contacter » : choisissez un message "
          "dans l'application ou WhatsApp (si le numéro est renseigné). Une "
          "conversation apparaît dans l'onglet « Messages ».",
    ],
    [
      'Comment enregistrer une annonce en favori ?',
      "Appuyez sur le cœur en haut à droite d'une annonce. Retrouvez tout "
          "dans l'onglet « Favoris » (le bouton central de la barre).",
    ],
    [
      'Comment créer une alerte de recherche ?',
      "Depuis l'écran de recherche, enregistrez vos critères en alerte : "
          "vous êtes prévenu(e) dès qu'une nouvelle annonce y correspond.",
    ],
    [
      'Que veulent dire caution et avance ?',
      "La caution est un dépôt de garantie exprimé en nombre de mois de loyer, "
          "restitué au départ. L'avance correspond aux mois de loyer payés "
          "d'avance à l'entrée. Le détail apparaît sur chaque annonce.",
    ],
    [
      "J'ai repéré une fausse annonce, que faire ?",
      "Ouvrez l'annonce, appuyez sur l'icône drapeau en haut à droite et "
          "choisissez un motif. L'équipe examine chaque signalement.",
    ],
  ];

  static const _proprietaire = <List<String>>[
    [
      'Comment publier une annonce ?',
      "Onglet « Mes biens » → « Ajouter un bien ». Renseignez le titre, le "
          "prix, la localisation (le GPS aide à placer le bien sur la carte), "
          "les caractéristiques, et ajoutez au moins une photo, puis validez.",
    ],
    [
      'Comment modifier, suspendre ou supprimer une annonce ?',
      "Dans « Mes biens », ouvrez le bien : vous pouvez le modifier, le "
          "marquer comme loué / disponible, ou le retirer. Un bien suspendu "
          "n'apparaît plus dans les recherches.",
    ],
    [
      'Comment gérer les demandes de visite ?',
      "Onglet « Demandes » : acceptez ou refusez chaque demande. À "
          "l'acceptation, l'application propose d'ajouter le rendez-vous à "
          "votre agenda et programme un rappel avant la visite.",
    ],
    [
      'Comment répondre aux locataires ?',
      "Onglet « Messages ». Le badge indique les conversations non lues. "
          "Vous pouvez aussi être contacté(e) via WhatsApp si votre numéro "
          "est renseigné dans le profil.",
    ],
    [
      'Comment suivre les performances de mes biens ?',
      "Le tableau de bord affiche vos statistiques : vues, favoris, demandes, "
          "et des graphes que vous pouvez adapter par semaine, mois ou année. "
          "Un export PDF est disponible.",
    ],
    [
      'Comment définir la caution, l\'avance et les frais ?',
      "Ces champs se remplissent au moment de créer ou modifier l'annonce, "
          "en nombre de mois de loyer. Ils s'affichent ensuite aux locataires.",
    ],
  ];

  static const _agent = <List<String>>[
    [
      'Comment gérer les biens de plusieurs propriétaires ?',
      "Publiez chaque bien depuis « Mes biens » comme d'habitude. Tous vos "
          "mandats sont regroupés au même endroit ; le tableau de bord "
          "cumule les statistiques.",
    ],
    [
      'Comment indiquer le vrai propriétaire d\'un bien ?',
      "Au moment de créer l'annonce, renseignez le champ « Propriétaire "
          "réel ». Les locataires voient alors « géré par un agent ».",
    ],
    [
      'Comment renseigner mon agence et mes frais d\'agence ?',
      "Le nom de l'agence se règle dans le profil. Les frais d'agence "
          "(montant fixe) se saisissent sur chaque annonce et s'affichent "
          "dans les conditions financières.",
    ],
    [
      'Comment gérer les demandes de visite et les messages ?',
      "Comme un propriétaire : onglet « Demandes » pour accepter / refuser "
          "(avec rappel + agenda), onglet « Messages » pour les échanges, "
          "et WhatsApp si votre numéro est renseigné.",
    ],
    [
      'Comment publier une annonce ?',
      "Onglet « Mes biens » → « Ajouter un bien » : titre, prix, "
          "localisation, caractéristiques et au moins une photo.",
    ],
  ];

  static const _admin = <List<String>>[
    [
      'Comment modérer une annonce ?',
      "Tableau de bord → « Tous les biens », ou l'onglet « Biens ». Touchez "
          "une carte pour voir la fiche complète ; le menu « ⋮ » permet de "
          "suspendre, rendre disponible ou supprimer l'annonce.",
    ],
    [
      'Comment gérer les utilisateurs ?',
      "Onglet « Utilisateurs » : les comptes sont classés par rôle. Touchez "
          "une carte pour voir la fiche (coordonnées, biens publiés / loués "
          "pour un propriétaire…) ; le menu « ⋮ » permet de suspendre ou "
          "supprimer un compte.",
    ],
    [
      'Comment traiter un signalement ?',
      "Onglet « Signalements ». La pastille indique le nombre de "
          "signalements non traités. Ouvrez-en un, vérifiez l'annonce "
          "concernée, puis marquez-le comme traité.",
    ],
    [
      'Où voir les statistiques détaillées ?',
      "Sur le tableau de bord, 3 graphes sont affichés ; le bouton « Plus de "
          "statistiques » ouvre une page complète : taux d'occupation, types "
          "de bien, revenus estimés, distribution des loyers, top quartiers, "
          "délai moyen de location, etc.",
    ],
    [
      'Comment promouvoir un compte en administrateur ?',
      "Il n'y a pas d'inscription admin dans l'application. Dans la console "
          "Firebase → Firestore → collection « users », ouvrez le document du "
          "compte et passez le champ « role » à « admin ».",
    ],
  ];

  ({String titre, List<List<String>> faq}) _contenu(UserRole? role) {
    switch (role) {
      case UserRole.locataire:
        return (titre: 'Aide — Locataire', faq: [..._locataire, ..._commun]);
      case UserRole.proprietaire:
        return (
          titre: 'Aide — Propriétaire',
          faq: [..._proprietaire, ..._commun],
        );
      case UserRole.agent:
        return (titre: 'Aide — Agent', faq: [..._agent, ..._commun]);
      case UserRole.admin:
        return (titre: 'Aide — Administration', faq: [..._admin, ..._commun]);
      case null:
        return (
          titre: 'Questions fréquentes',
          faq: [..._locataire, ..._proprietaire, ..._commun],
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(utilisateurActuelProvider).asData?.value?.role;
    final contenu = _contenu(role);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.bleuFonce,
        foregroundColor: Colors.white,
        title: const Text(
          "Centre d'aide",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            contenu.titre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Questions et réponses adaptées à votre profil.',
            style: const TextStyle(fontSize: 12, color: AppColors.texteLeger),
          ),
          const SizedBox(height: 12),
          Container(
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
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: AppColors.grisClair),
              child: Column(
                children: [
                  for (var i = 0; i < contenu.faq.length; i++)
                    ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Text(
                        contenu.faq[i][0],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texte,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            contenu.faq[i][1],
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: AppColors.textSecondaire,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bleuClair,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vous n'avez pas trouvé de réponse ?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bleuFonce,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Notre équipe vous répond sous 48 h.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaire,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.contact),
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: const Text('Nous contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bleuFonce,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
