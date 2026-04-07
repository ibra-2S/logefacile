import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';
import '../models/property_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/visit_request_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //BIENS

  // ajouter un nouveau bien
  Future<String> ajouterBien(PropertyModel bien) async {
    final doc = await _db.collection('properties').add(bien.toMap());
    return doc.id;
  }

  // modifier un bien existant
  Future<void> modifierBien(String bienId, Map<String, dynamic> donnees) async {
    await _db.collection('properties').doc(bienId).update(donnees);
  }

  // supprimer un bien
  Future<void> supprimerBien(String bienId) async {
    await _db.collection('properties').doc(bienId).delete();
  }

  // récupérer un bien par son id
  Future<PropertyModel?> recupererBien(String bienId) async {
    final doc = await _db.collection('properties').doc(bienId).get();
    if (doc.exists) return PropertyModel.fromFirestore(doc);
    return null;
  }

  // récupérer tous les biens d'un propriétaire
  Stream<List<PropertyModel>> biensDuProprietaire(String proprietaireId) {
    return _db
        .collection('properties')
        .where('proprietaireId', isEqualTo: proprietaireId)
        .orderBy('datePublication', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PropertyModel.fromFirestore).toList());
  }

  // rechercher des biens avec filtres
  Stream<List<PropertyModel>> rechercherBiens({
    String? ville,
    double? prixMax,
    TypeBien? type,
    int? nombrePieces,
  }) {
    Query query = _db
        .collection('properties')
        .where('estDisponible', isEqualTo: true);

    if (ville != null && ville.isNotEmpty) {
      query = query.where('ville', isEqualTo: ville);
    }
    if (prixMax != null) {
      query = query.where('prix', isLessThanOrEqualTo: prixMax);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (nombrePieces != null) {
      query = query.where('nombrePieces', isEqualTo: nombrePieces);
    }

    return query
        .orderBy('datePublication', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PropertyModel.fromFirestore).toList());
  }

  // incrémenter le nombre de vues d'un bien
  Future<void> incrementerVues(String bienId) async {
    await _db.collection('properties').doc(bienId).update({
      'nombreVues': FieldValue.increment(1),
    });
  }

  //FAVORIS

  // ajouter un bien en favori
  Future<void> ajouterFavori(String locataireId, PropertyModel bien) async {
    final favId = '${locataireId}_${bien.id}';
    await _db.collection('favorites').doc(favId).set({
      'tenantId': locataireId,
      'propertyId': bien.id,
      'savedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _db.collection('properties').doc(bien.id).update({
      'nombreFavoris': FieldValue.increment(1),
    });
  }

  // retirer un bien des favoris
  Future<void> retirerFavori(String locataireId, String bienId) async {
    final favId = '${locataireId}_$bienId';
    await _db.collection('favorites').doc(favId).delete();
    await _db.collection('properties').doc(bienId).update({
      'nombreFavoris': FieldValue.increment(-1),
    });
  }

  // vérifier si un bien est en favori
  Future<bool> estEnFavori(String locataireId, String bienId) async {
    final favId = '${locataireId}_$bienId';
    final doc = await _db.collection('favorites').doc(favId).get();
    return doc.exists;
  }

  // récupérer tous les favoris d'un locataire
  Stream<List<String>> favorisLocataire(String locataireId) {
    return _db
        .collection('favorites')
        .where('tenantId', isEqualTo: locataireId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => d.data()['propertyId'] as String).toList(),
        );
  }

  //DEMANDES DE VISITE

  // créer une demande de visite
  Future<void> creerDemandeVisite(VisitRequestModel demande) async {
    await _db.collection('visitRequests').add(demande.toMap());
  }

  // mettre à jour le statut d'une demande
  Future<void> mettreAJourStatutDemande(
    String demandeId,
    StatutDemande statut, {
    String? raisonRefus,
    bool etaitAcceptee = false,
  }) async {
    final Map<String, dynamic> donnees = {
      'statut': statut.name,
      'dateMiseAJour': Timestamp.fromDate(DateTime.now()),
      'etaitAcceptee': etaitAcceptee,
    };
    if (raisonRefus != null) donnees['raisonRefus'] = raisonRefus;
    await _db.collection('visitRequests').doc(demandeId).update(donnees);
  }

  // supprimer une demande de visite
  Future<void> supprimerDemande(String demandeId) async {
    await _db.collection('visitRequests').doc(demandeId).delete();
  }

  // demandes reçues par un propriétaire
  Stream<List<VisitRequestModel>> demandesRecues(String proprietaireId) {
    return _db
        .collection('visitRequests')
        .where('proprietaireId', isEqualTo: proprietaireId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((s) => s.docs.map(VisitRequestModel.fromFirestore).toList());
  }

  // demandes envoyées par un locataire
  Stream<List<VisitRequestModel>> demandesEnvoyees(String locataireId) {
    return _db
        .collection('visitRequests')
        .where('locataireId', isEqualTo: locataireId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((s) => s.docs.map(VisitRequestModel.fromFirestore).toList());
  }

  // AVIS

  // ajouter un avis
  Future<void> ajouterAvis(ReviewModel avis) async {
    await _db.collection('reviews').add(avis.toMap());
    final avisSnapshot =
        await _db
            .collection('reviews')
            .where('bienId', isEqualTo: avis.bienId)
            .get();
    final notes =
        avisSnapshot.docs
            .map((d) => (d.data()['note'] as num).toDouble())
            .toList();
    final moyenne = notes.reduce((a, b) => a + b) / notes.length;
    await _db.collection('properties').doc(avis.bienId).update({
      'noteMoyenne': moyenne,
      'nombreAvis': notes.length,
    });
  }

  // récupérer les avis d'un bien
  Stream<List<ReviewModel>> avisduBien(String bienId) {
    return _db
        .collection('reviews')
        .where('bienId', isEqualTo: bienId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());
  }

  // ── CONVERSATIONS & MESSAGES ─────────────────────────────────────────────

  // créer ou récupérer une conversation
  Future<String> creerOuRecupererConversation(
    String locataireId,
    String proprietaireId,
    String bienId, {
    String titreBien = '',
    String nomLocataire = '',
    String nomProprietaire = '',
    String? photoLocataire,
    String? photoProprietaire,
  }) async {
    final snapshot =
        await _db
            .collection('conversations')
            .where('participants', arrayContains: locataireId)
            .where('bienId', isEqualTo: bienId)
            .get();

    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(proprietaireId)) return doc.id;
    }

    // créer une nouvelle conversation avec les noms
    final doc = await _db.collection('conversations').add({
      'participants': [locataireId, proprietaireId],
      'bienId': bienId,
      'dernierMessage': '',
      'dateDernierMessage': Timestamp.fromDate(DateTime.now()),
      'messagesNonLus': {locataireId: 0, proprietaireId: 0},
      'titreBien': titreBien,
      // noms par participant pour affichage côté locataire et propriétaire
      'nomParticipant': {
        locataireId: nomLocataire,
        proprietaireId: nomProprietaire,
      },
      'photoParticipant': {
        locataireId: photoLocataire ?? '',
        proprietaireId: photoProprietaire ?? '',
      },
    });
    return doc.id;
  }

  // envoyer un message
  Future<void> envoyerMessage(String convId, MessageModel message) async {
    await _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .add(message.toMap());

    // récupérer les participants pour incrémenter le compteur du destinataire
    final convDoc = await _db.collection('conversations').doc(convId).get();
    final participants = List<String>.from(
      convDoc.data()?['participants'] ?? [],
    );
    final destinataireId = participants.firstWhere(
      (p) => p != message.expediteurId,
      orElse: () => '',
    );

    await _db.collection('conversations').doc(convId).update({
      'dernierMessage': message.contenu,
      'dateDernierMessage': Timestamp.fromDate(message.dateEnvoi),
      if (destinataireId.isNotEmpty)
        'messagesNonLus.$destinataireId': FieldValue.increment(1),
    });
  }

  // marquer un message comme lu
  Future<void> marquerMessageLu(String convId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .doc(messageId)
        .update({'estLu': true});
  }

  // réinitialiser le compteur de messages non lus pour un utilisateur
  Future<void> reinitialiserMessagesNonLus(String convId, String uid) async {
    await _db.collection('conversations').doc(convId).update({
      'messagesNonLus.$uid': 0,
    });
  }

  // flux des messages d'une conversation
  Stream<List<MessageModel>> messagesConversation(String convId) {
    return _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('dateEnvoi')
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromFirestore).toList());
  }

  // conversations d'un utilisateur
  Stream<List<ConversationModel>> conversationsUtilisateur(String uid) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('dateDernierMessage', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ConversationModel.fromFirestore).toList());
  }

  // récupérer un bien par id en stream
  Stream<PropertyModel?> getBienParId(String bienId) {
    return _db
        .collection('properties')
        .doc(bienId)
        .snapshots()
        .map((doc) => doc.exists ? PropertyModel.fromFirestore(doc) : null);
  }

  // ajouter une demande de visite
  Future<void> ajouterDemandeVisite(VisitRequestModel demande) async {
    await _db.collection('visitRequests').add(demande.toMap());
  }

  //ALERTES

  // créer une alerte de recherche
  Future<void> creerAlerte({
    required String locataireId,
    required String ville,
    double? prixMax,
    String? type,
  }) async {
    await _db.collection('searchAlerts').add({
      'locataireId': locataireId,
      'ville': ville,
      'prixMax': prixMax,
      'type': type,
      'dateCreation': Timestamp.fromDate(DateTime.now()),
      'active': true,
    });
  }

  // récupérer les alertes d'un locataire
  Stream<List<Map<String, dynamic>>> alertesLocataire(String locataireId) {
    return _db
        .collection('searchAlerts')
        .where('locataireId', isEqualTo: locataireId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // supprimer une alerte
  Future<void> supprimerAlerte(String alerteId) async {
    await _db.collection('searchAlerts').doc(alerteId).delete();
  }

  //ADMIN

  // récupérer tous les utilisateurs
  Stream<List<UserModel>> tousLesUtilisateurs() {
    return _db
        .collection('users')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  // modifier le statut d'un utilisateur
  Future<void> modifierStatutUtilisateur(String uid, bool estActif) async {
    await _db.collection('users').doc(uid).update({'estActif': estActif});
  }

  // supprimer un utilisateur
  Future<void> supprimerUtilisateur(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // récupérer tous les signalements
  Stream<List<Map<String, dynamic>>> tousLesSignalements() {
    return _db
        .collection('reports')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  // marquer un signalement comme traité
  Future<void> marquerSignalementTraite(String signalementId) async {
    await _db.collection('reports').doc(signalementId).update({
      'traite': true,
      'dateMiseAJour': Timestamp.fromDate(DateTime.now()),
    });
  }
}
