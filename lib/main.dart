import 'dart:async';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'core/services/firestore_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/rappel_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

@pragma('vm:entry-point')
Future<void> _messageArrierePlan(RemoteMessage message) async {
  // rien de spécial : Android affiche la notification système tout seul
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // force le moteur de rendu récent de Google Maps sur Android : sans ça,
  // l'ancien moteur (LEGACY) tourne en "virtual display", consomme beaucoup
  // de mémoire (crash/fermeture après plusieurs ouvertures de carte) et
  // perturbe les gestes des widgets autour de la carte.
  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    mapsImpl.useAndroidViewSurface = true;
    try {
      await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {
      // déjà initialisé ou moteur récent indisponible : on continue
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_messageArrierePlan);
  await NotificationService.instance.initialiser();
  await RappelService.initialiser();

  runApp(
    // ProviderScope nécessaire pour Riverpod
    const ProviderScope(child: LogeFacile()),
  );
}

// permet de faire défiler les listes / carrousels aussi à la souris et au
// trackpad (émulateur, bureau) — par défaut Flutter n'accepte que le tactile
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}

class LogeFacile extends ConsumerStatefulWidget {
  const LogeFacile({super.key});

  @override
  ConsumerState<LogeFacile> createState() => _LogeFacileState();
}

class _LogeFacileState extends ConsumerState<LogeFacile> {
  StreamSubscription? _badgeSub;
  String? _uidSuivi;

  @override
  void initState() {
    super.initState();
    // ouvre l'écran ciblé quand une notification push est tapée
    NotificationService.instance.lienAOuvrir.addListener(_ouvrirLien);
  }

  @override
  void dispose() {
    NotificationService.instance.lienAOuvrir.removeListener(_ouvrirLien);
    _badgeSub?.cancel();
    super.dispose();
  }

  void _ouvrirLien() {
    final lien = NotificationService.instance.lienAOuvrir.value;
    if (lien == null || lien.isEmpty) return;
    NotificationService.instance.lienAOuvrir.value = null;
    ref.read(routeurApp).push(lien);
  }

  // met à jour le badge de l'icône de l'app = nb de notifications non lues
  void _suivreBadge(String? uid) {
    if (uid == _uidSuivi) return;
    _uidSuivi = uid;
    _badgeSub?.cancel();
    if (uid == null) {
      AppBadgePlus.updateBadge(0);
      return;
    }
    _badgeSub = FirestoreService().notificationsUtilisateur(uid).listen((
      notifs,
    ) {
      final nonLues = notifs.where((n) => !n.lu).length;
      AppBadgePlus.updateBadge(nonLues);
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeur = ref.watch(routeurApp);

    // enregistre le token FCM + suit le badge selon l'état de connexion
    ref.listen(utilisateurActuelProvider, (previous, next) {
      final uid = next.asData?.value?.uid;
      if (uid != null) {
        NotificationService.instance.enregistrerToken(uid);
      }
      _suivreBadge(uid);
    });

    return MaterialApp.router(
      title: 'LogeFacile',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6F80FA),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      routerConfig: routeur,
    );
  }
}
