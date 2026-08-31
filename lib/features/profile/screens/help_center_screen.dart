import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faq = <List<String>>[
    [
      'Comment publier une annonce ?',
      "Depuis l'onglet propriétaire, appuyez sur « Ajouter un bien », "
          "remplissez le titre, le prix, la localisation et ajoutez au moins "
          "une photo, puis validez. L'annonce est visible immédiatement.",
    ],
    [
      'Comment demander une visite ?',
      "Sur la page d'une annonce, appuyez sur « Demander une visite » et "
          "choisissez une date. Le propriétaire reçoit la demande et peut "
          "l'accepter ou la refuser. Vous suivez l'état dans l'onglet « Demandes ».",
    ],
    [
      'Comment contacter un propriétaire ?',
      "Ouvrez l'annonce et appuyez sur « Contacter ». Une conversation est "
          "créée dans l'onglet « Messages ». Vos coordonnées ne sont partagées "
          "que si vous le décidez dans la discussion.",
    ],
    [
      'Comment ajouter une annonce en favori ?',
      "Appuyez sur le cœur en haut à droite d'une annonce. Retrouvez toutes "
          "vos annonces enregistrées dans l'onglet « Favoris ».",
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
          "choisissez un motif. Notre équipe examine chaque signalement.",
    ],
    [
      'Comment modifier mes informations ?',
      "Onglet Profil → « Modifier le profil » pour le nom et le téléphone, "
          "ou appuyez sur votre photo pour la changer.",
    ],
    [
      "J'ai oublié mon mot de passe",
      "Sur l'écran de connexion, utilisez « Mot de passe oublié », ou depuis "
          "Profil → Paramètres → « Changer le mot de passe » pour recevoir un "
          "e-mail de réinitialisation.",
    ],
  ];

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.texte,
            ),
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
              data: Theme.of(context).copyWith(dividerColor: AppColors.grisClair),
              child: Column(
                children: [
                  for (var i = 0; i < _faq.length; i++)
                    ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Text(
                        _faq[i][0],
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
                            _faq[i][1],
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
