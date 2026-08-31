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

  NotificationModel({
    required this.id,
    required this.destinataireId,
    required this.type,
    required this.titre,
    required this.corps,
    this.lien = '',
    this.lu = false,
    required this.dateCreation,
  });

  static DateTime _lireDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
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
    );
  }

  IconData get icone => switch (type) {
    TypeNotification.demandeVisite => Icons.event_available,
    TypeNotification.demandeAcceptee => Icons.check_circle,
    TypeNotification.demandeRefusee => Icons.cancel,
    TypeNotification.demandeAnnulee => Icons.event_busy,
    TypeNotification.message => Icons.chat_bubble,
    TypeNotification.autre => Icons.notifications,
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
