import 'package:cloud_firestore/cloud_firestore.dart';

// types de messages possibles
enum TypeMessage { texte, image }

class MessageModel {
  final String id;
  final String expediteurId;
  final String contenu;
  final TypeMessage type;
  final bool estLu;
  final DateTime dateEnvoi;

  MessageModel({
    required this.id,
    required this.expediteurId,
    required this.contenu,
    this.type = TypeMessage.texte,
    this.estLu = false,
    required this.dateEnvoi,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      expediteurId: d['expediteurId'] ?? '',
      contenu: d['contenu'] ?? '',
      type: TypeMessage.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => TypeMessage.texte,
      ),
      estLu: d['estLu'] ?? false,
      dateEnvoi: (d['dateEnvoi'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expediteurId': expediteurId,
      'contenu': contenu,
      'type': type.name,
      'estLu': estLu,
      'dateEnvoi': Timestamp.fromDate(dateEnvoi),
    };
  }
}

// modèle pour une conversation complète
class ConversationModel {
  final String id;
  final List<String> participants;
  final String bienId;
  final String dernierMessage;
  final DateTime dateDernierMessage;
  final Map<String, int> messagesNonLus;
  final String titreBien;
  // noms et photos par uid de participant
  final Map<String, String> nomParticipant;
  final Map<String, String> photoParticipant;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.bienId,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.messagesNonLus = const {},
    this.titreBien = '',
    this.nomParticipant = const {},
    this.photoParticipant = const {},
  });

  // obtenir le nom de l'interlocuteur (pas moi)
  String nomInterlocuteur(String monUid) {
    final autreUid = participants.firstWhere(
      (p) => p != monUid,
      orElse: () => '',
    );
    return nomParticipant[autreUid] ?? '';
  }

  // obtenir la photo de l'interlocuteur
  String? photoInterlocuteur(String monUid) {
    final autreUid = participants.firstWhere(
      (p) => p != monUid,
      orElse: () => '',
    );
    final photo = photoParticipant[autreUid] ?? '';
    return photo.isEmpty ? null : photo;
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      bienId: d['bienId'] ?? '',
      dernierMessage: d['dernierMessage'] ?? '',
      dateDernierMessage: (d['dateDernierMessage'] as Timestamp).toDate(),
      messagesNonLus: Map<String, int>.from(d['messagesNonLus'] ?? {}),
      titreBien: d['titreBien'] ?? '',
      nomParticipant: Map<String, String>.from(d['nomParticipant'] ?? {}),
      photoParticipant: Map<String, String>.from(d['photoParticipant'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'bienId': bienId,
      'dernierMessage': dernierMessage,
      'dateDernierMessage': Timestamp.fromDate(dateDernierMessage),
      'messagesNonLus': messagesNonLus,
      'titreBien': titreBien,
      'nomParticipant': nomParticipant,
      'photoParticipant': photoParticipant,
    };
  }
}
