import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/connexion_service.dart';

/// Bandeau affiché en haut de tous les écrans quand Internet est coupé.
/// Les annonces déjà chargées restent consultables (cache Firestore).
class BandeauHorsLigne extends StatelessWidget {
  final Widget child;
  const BandeauHorsLigne({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnexionService.instance.enLigne,
      builder: (context, enLigne, _) {
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child:
                  enLigne
                      ? const SizedBox(width: double.infinity)
                      : Material(
                        color: AppColors.erreur,
                        child: SafeArea(
                          bottom: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.wifi_off,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Pas de connexion Internet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
            Expanded(
              // le bandeau occupe déjà la barre d'état : on évite que
              // l'AppBar en dessous ajoute une seconde marge en haut.
              // Toujours le même widget parent, pour ne pas reconstruire
              // l'écran en cours (et perdre sa saisie) à chaque coupure.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: !enLigne,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
