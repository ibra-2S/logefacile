import 'package:cloud_firestore/cloud_firestore.dart';

// les différents rôles possibles dans l'app
enum UserRole { proprietaire, agent, locataire, admin }

class UserModel {
  final String uid;
  final String email;
  final String nomComplet;
  final String? photoUrl;
  final UserRole role;
  final String? telephone;
  final bool estVerifie;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime derniereCo;

  // champs spécifiques aux propriétaires et agents
  final String? nomAgence;
  final String? biographie;
  final int totalBiens;
  final double? noteMoyenne;

  // champs spécifiques aux locataires
  final String? carteIdentiteUrl;
  final bool carteVerifiee;
  final int totalFavoris;

  UserModel({
    required this.uid,
    required this.email,
    required this.nomComplet,
    this.photoUrl,
    required this.role,
    this.telephone,
    this.estVerifie = false,
    this.estActif = true,
    required this.dateCreation,
    required this.derniereCo,
    this.nomAgence,
    this.biographie,
    this.totalBiens = 0,
    this.noteMoyenne,
    this.carteIdentiteUrl,
    this.carteVerifiee = false,
    this.totalFavoris = 0,
  });

  // construction depuis un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: d['email'] ?? '',
      nomComplet: d['nomComplet'] ?? '',
      photoUrl: d['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.locataire,
      ),
      telephone: d['telephone'],
      estVerifie: d['estVerifie'] ?? false,
      estActif: d['estActif'] ?? true,
      dateCreation: (d['dateCreation'] as Timestamp).toDate(),
      derniereCo: (d['derniereCo'] as Timestamp).toDate(),
      nomAgence: d['nomAgence'],
      biographie: d['biographie'],
      totalBiens: d['totalBiens'] ?? 0,
      noteMoyenne: d['noteMoyenne']?.toDouble(),
      carteIdentiteUrl: d['carteIdentiteUrl'],
      carteVerifiee: d['carteVerifiee'] ?? false,
      totalFavoris: d['totalFavoris'] ?? 0,
    );
  }

  // conversion en map pour sauvegarder dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nomComplet': nomComplet,
      'photoUrl': photoUrl,
      'role': role.name,
      'telephone': telephone,
      'estVerifie': estVerifie,
      'estActif': estActif,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'derniereCo': Timestamp.fromDate(derniereCo),
      'nomAgence': nomAgence,
      'biographie': biographie,
      'totalBiens': totalBiens,
      'noteMoyenne': noteMoyenne,
      'carteIdentiteUrl': carteIdentiteUrl,
      'carteVerifiee': carteVerifiee,
      'totalFavoris': totalFavoris,
    };
  }

  // raccourcis utiles
  bool get estProprietaireOuAgent =>
      role == UserRole.proprietaire || role == UserRole.agent;
  bool get estLocataire => role == UserRole.locataire;
  bool get estAdmin => role == UserRole.admin;
}
