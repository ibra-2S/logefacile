import 'package:cloud_firestore/cloud_firestore.dart';

// statuts possibles d'une demande de visite
enum StatutDemande { enAttente, acceptee, refusee, annulee }

class VisitRequestModel {
  final String id;
  final String bienId;
  final String locataireId;
  final String proprietaireId;
  final DateTime dateProposee;
  final StatutDemande statut;
  final String? message;
  final String? raisonRefus;
  final DateTime dateCreation;
  final DateTime dateMiseAJour;

  VisitRequestModel({
    required this.id,
    required this.bienId,
    required this.locataireId,
    required this.proprietaireId,
    required this.dateProposee,
    this.statut = StatutDemande.enAttente,
    this.message,
    this.raisonRefus,
    required this.dateCreation,
    required this.dateMiseAJour,
  });

  factory VisitRequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VisitRequestModel(
      id: doc.id,
      bienId: d['bienId'] ?? '',
      locataireId: d['locataireId'] ?? '',
      proprietaireId: d['proprietaireId'] ?? '',
      dateProposee: (d['dateProposee'] as Timestamp).toDate(),
      statut: StatutDemande.values.firstWhere(
        (s) => s.name == d['statut'],
        orElse: () => StatutDemande.enAttente,
      ),
      message: d['message'],
      raisonRefus: d['raisonRefus'],
      dateCreation: (d['dateCreation'] as Timestamp).toDate(),
      dateMiseAJour: (d['dateMiseAJour'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bienId': bienId,
      'locataireId': locataireId,
      'proprietaireId': proprietaireId,
      'dateProposee': Timestamp.fromDate(dateProposee),
      'statut': statut.name,
      'message': message,
      'raisonRefus': raisonRefus,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateMiseAJour': Timestamp.fromDate(dateMiseAJour),
    };
  }

  // raccourcis utiles
  bool get estEnAttente => statut == StatutDemande.enAttente;
  bool get estAcceptee => statut == StatutDemande.acceptee;
  bool get estRefusee => statut == StatutDemande.refusee;
}
