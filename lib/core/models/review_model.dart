import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String bienId;
  final String locataireId;
  final String proprietaireId;
  final double note;
  final String? commentaire;
  final String demandeVisiteId;
  final DateTime dateCreation;

  ReviewModel({
    required this.id,
    required this.bienId,
    required this.locataireId,
    required this.proprietaireId,
    required this.note,
    this.commentaire,
    required this.demandeVisiteId,
    required this.dateCreation,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      bienId: d['bienId'] ?? '',
      locataireId: d['locataireId'] ?? '',
      proprietaireId: d['proprietaireId'] ?? '',
      note: (d['note'] ?? 0).toDouble(),
      commentaire: d['commentaire'],
      demandeVisiteId: d['demandeVisiteId'] ?? '',
      dateCreation: (d['dateCreation'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bienId': bienId,
      'locataireId': locataireId,
      'proprietaireId': proprietaireId,
      'note': note,
      'commentaire': commentaire,
      'demandeVisiteId': demandeVisiteId,
      'dateCreation': Timestamp.fromDate(dateCreation),
    };
  }

  // vérifie que la note est valide (entre 1 et 5)
  bool get noteValide => note >= 1 && note <= 5;
}
