import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Gestion des notifications push (FCM).
///
/// L'envoi réel des push est fait par une Cloud Function déclenchée à la
/// création d'un document dans la collection `notifications`
/// (voir functions/index.js). Ici on gère : la permission, l'enregistrement
/// du token de l'appareil, et la réception quand l'app est ouverte.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  /// scaffold messenger pour afficher les notifs au premier plan
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// lien à ouvrir suite au tap sur une notification (consommé par l'app)
  final ValueNotifier<String?> lienAOuvrir = ValueNotifier(null);

  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      final texte =
          '${notif?.title ?? ''} — ${notif?.body ?? ''}'.trim();
      if (texte.length > 3) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(texte),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_capterLien);
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _capterLien(initial);
  }

  void _capterLien(RemoteMessage message) {
    final lien = message.data['lien'] as String?;
    if (lien != null && lien.isNotEmpty) lienAOuvrir.value = lien;
  }

  /// à appeler après connexion : enregistre le token de l'appareil
  Future<void> enregistrerToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      _fcm.onTokenRefresh.listen((nouveau) {
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([nouveau]),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // pas bloquant
    }
  }

  /// à appeler à la déconnexion : retire le token de cet appareil
  Future<void> retirerToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
