import 'package:cloud_firestore/cloud_firestore.dart';

// types de biens disponibles
enum TypeBien { maison, appartement, chambre, studio }

// état du bien
enum StatutBien { disponible, loue, suspendu }

class PropertyModel {
  final String id;
  final String proprietaireId;
  final String proprietaireRole;
  final String titre;
  final String description;
  final TypeBien type;
  final StatutBien statut;
  final double prix;
  final double? surface;
  final int? nombrePieces;
  final String adresse;
  final String ville;
  final String? quartier;
  final GeoPoint localisation;
  final List<String> photos;
  final List<String> equipements;
  final bool estDisponible;
  final int nombreVues;
  final int nombreFavoris;
  final double? noteMoyenne;
  final int nombreAvis;
  final DateTime datePublication;
  final DateTime dateMiseAJour;

  PropertyModel({
    required this.id,
    required this.proprietaireId,
    required this.proprietaireRole,
    required this.titre,
    required this.description,
    required this.type,
    required this.statut,
    required this.prix,
    this.surface,
    this.nombrePieces,
    required this.adresse,
    required this.ville,
    this.quartier,
    required this.localisation,
    this.photos = const [],
    this.equipements = const [],
    this.estDisponible = true,
    this.nombreVues = 0,
    this.nombreFavoris = 0,
    this.noteMoyenne,
    this.nombreAvis = 0,
    required this.datePublication,
    required this.dateMiseAJour,
  });

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      proprietaireId: d['proprietaireId'] ?? '',
      proprietaireRole: d['proprietaireRole'] ?? '',
      titre: d['titre'] ?? '',
      description: d['description'] ?? '',
      type: TypeBien.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => TypeBien.maison,
      ),
      statut: StatutBien.values.firstWhere(
        (s) => s.name == d['statut'],
        orElse: () => StatutBien.disponible,
      ),
      prix: (d['prix'] ?? 0).toDouble(),
      surface: d['surface']?.toDouble(),
      nombrePieces: d['nombrePieces'],
      adresse: d['adresse'] ?? '',
      ville: d['ville'] ?? '',
      quartier: d['quartier'],
      localisation: d['localisation'] ?? const GeoPoint(0, 0),
      photos: List<String>.from(d['photos'] ?? []),
      equipements: List<String>.from(d['equipements'] ?? []),
      estDisponible: d['estDisponible'] ?? true,
      nombreVues: d['nombreVues'] ?? 0,
      nombreFavoris: d['nombreFavoris'] ?? 0,
      noteMoyenne: d['noteMoyenne']?.toDouble(),
      nombreAvis: d['nombreAvis'] ?? 0,
      datePublication: (d['datePublication'] as Timestamp).toDate(),
      dateMiseAJour: (d['dateMiseAJour'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proprietaireId': proprietaireId,
      'proprietaireRole': proprietaireRole,
      'titre': titre,
      'description': description,
      'type': type.name,
      'statut': statut.name,
      'prix': prix,
      'surface': surface,
      'nombrePieces': nombrePieces,
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'localisation': localisation,
      'photos': photos,
      'equipements': equipements,
      'estDisponible': estDisponible,
      'nombreVues': nombreVues,
      'nombreFavoris': nombreFavoris,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
      'datePublication': Timestamp.fromDate(datePublication),
      'dateMiseAJour': Timestamp.fromDate(dateMiseAJour),
    };
  }
}
