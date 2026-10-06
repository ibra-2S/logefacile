import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Surveille l'accès à Internet pour afficher le bandeau « Pas de connexion »
/// et bloquer proprement les actions qui ont besoin du réseau.
///
/// connectivity_plus ne dit que si le téléphone est relié à un réseau (Wi-Fi,
/// données mobiles) : un Wi-Fi sans Internet ou un forfait épuisé compte
/// quand même comme « connecté ». On confirme donc par une résolution DNS.
class ConnexionService {
  ConnexionService._();
  static final instance = ConnexionService._();

  /// true tant qu'Internet est joignable (optimiste au démarrage)
  final enLigne = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _relance;

  void demarrer() {
    if (_sub != null) return;
    _sub = Connectivity().onConnectivityChanged.listen((_) => verifier());
    verifier();
  }

  /// Teste l'accès réel à Internet et met à jour [enLigne].
  Future<bool> verifier() async {
    final reseaux = await Connectivity().checkConnectivity();
    var ok = !reseaux.every((r) => r == ConnectivityResult.none);
    if (ok) {
      try {
        final r = await InternetAddress.lookup(
          'firestore.googleapis.com',
        ).timeout(const Duration(seconds: 5));
        ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
      } catch (_) {
        ok = false;
      }
    }
    enLigne.value = ok;

    // hors ligne : on re-teste régulièrement, car un réseau qui retrouve
    // Internet (forfait rechargé…) ne déclenche pas toujours d'événement
    _relance?.cancel();
    if (!ok) {
      _relance = Timer(const Duration(seconds: 10), verifier);
    }
    return ok;
  }

  /// À appeler au début d'une action qui a besoin du réseau : affiche un
  /// message et renvoie false si l'appareil est hors ligne.
  Future<bool> exigerConnexion(BuildContext context) async {
    if (await verifier()) return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pas de connexion Internet. Vérifiez votre réseau puis réessayez.',
          ),
          backgroundColor: AppColors.erreur,
        ),
      );
    }
    return false;
  }
}
