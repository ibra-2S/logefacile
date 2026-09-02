import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum TypeNotification {
  demandeVisite,
  demandeAcceptee,
  demandeRefusee,
  demandeAnnulee,
  message,
  autre,
}

class NotificationModel {
  final String id;
  final String destinataireId;
  final TypeNotification type;
  final String titre;
  final String corps;
  final String lien; // route à ouvrir (vide = aucune)
  final bool lu;
  final DateTime dateCreation;

  /// moment où la notification a été ouverte/lue (null si pas encore lue).
  /// Sert à la faire disparaître 24 h après ouverture.
  final DateTime? luLe;

  NotificationModel({
    required this.id,
    required this.destinataireId,
    required this.type,
    required this.titre,
    required this.corps,
    this.lien = '',
    this.lu = false,
    required this.dateCreation,
    this.luLe,
  });

  static DateTime _lireDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static DateTime? _lireDateNullable(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationModel(
      id: doc.id,
      destinataireId: d['destinataireId'] ?? '',
      type: TypeNotification.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => TypeNotification.autre,
      ),
      titre: d['titre'] ?? '',
      corps: d['corps'] ?? '',
      lien: d['lien'] ?? '',
      lu: d['lu'] ?? false,
      dateCreation: _lireDate(d['dateCreation']),
      luLe: _lireDateNullable(d['luLe']),
    );
  }

  /// true quand la notification a été lue il y a plus de 24 h : on la masque
  /// (et un nettoyage la supprimera de Firestore). Une notification non lue
  /// n'est jamais masquée.
  bool get estExpiree {
    final l = luLe;
    return lu &&
        l != null &&
        DateTime.now().difference(l) >= const Duration(hours: 24);
  }

  IconData get icone => switch (type) {
    TypeNotification.demandeVisite => Icons.event_available_outlined,
    TypeNotification.demandeAcceptee => Icons.check_circle_outline,
    TypeNotification.demandeRefusee => Icons.cancel_outlined,
    TypeNotification.demandeAnnulee => Icons.event_busy_outlined,
    TypeNotification.message => Icons.chat_bubble_outline,
    TypeNotification.autre => Icons.notifications_outlined,
  };

  Color get couleur => switch (type) {
    TypeNotification.demandeVisite => AppColors.bleuFonce,
    TypeNotification.demandeAcceptee => AppColors.succes,
    TypeNotification.demandeRefusee => AppColors.erreur,
    TypeNotification.demandeAnnulee => AppColors.grisMoyen,
    TypeNotification.message => AppColors.tealLocataire,
    TypeNotification.autre => AppColors.bleuMoyen,
  };
}
