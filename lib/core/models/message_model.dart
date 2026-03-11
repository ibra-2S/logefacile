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

  ConversationModel({
    required this.id,
    required this.participants,
    required this.bienId,
    required this.dernierMessage,
    required this.dateDernierMessage,
    this.messagesNonLus = const {},
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      bienId: d['bienId'] ?? '',
      dernierMessage: d['dernierMessage'] ?? '',
      dateDernierMessage: (d['dateDernierMessage'] as Timestamp).toDate(),
      messagesNonLus: Map<String, int>.from(d['messagesNonLus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'bienId': bienId,
      'dernierMessage': dernierMessage,
      'dateDernierMessage': Timestamp.fromDate(dateDernierMessage),
      'messagesNonLus': messagesNonLus,
    };
  }
}
