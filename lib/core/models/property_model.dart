import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeBien { maison, appartement, chambre, studio }

enum StatutBien { disponible, loue, suspendu }

class PropertyModel {
  final String id;
  final String proprietaireId;
  final String proprietaireRole;
  final String? nomProprietaireReel;
  final String titre;
  final String description;
  final TypeBien type;
  final StatutBien statut;
  final double prix;
  final double? surface;
  final int? nombrePieces;
  final int? nombreChambres;
  final int? nombreToilettes;
  final int? nombreCuisines;
  final String adresse;
  final String ville;
  final String? quartier;
  final GeoPoint localisation;
  final List<String> photos;
  final List<String> equipements;
  final bool estDisponible;
  final int nombreVues;
  final int nombreFavoris;
  final Map<String, int> statsVues; // 'yyyy-MM-dd' -> nombre de vues ce jour
  final double? noteMoyenne;
  final int nombreAvis;
  // conditions financières en nombre de mois
  final int? moisCaution; // ex: 2 = 2 mois de caution
  final int? moisAvance; // ex: 3 = 3 mois d'avance
  final double? fraisAgence; // montant fixe pour les agents
  final DateTime datePublication;
  final DateTime dateMiseAJour;

  PropertyModel({
    required this.id,
    required this.proprietaireId,
    required this.proprietaireRole,
    this.nomProprietaireReel,
    required this.titre,
    required this.description,
    required this.type,
    required this.statut,
    required this.prix,
    this.surface,
    this.nombrePieces,
    this.nombreChambres,
    this.nombreToilettes,
    this.nombreCuisines,
    required this.adresse,
    required this.ville,
    this.quartier,
    required this.localisation,
    this.photos = const [],
    this.equipements = const [],
    this.estDisponible = true,
    this.nombreVues = 0,
    this.nombreFavoris = 0,
    this.statsVues = const {},
    this.noteMoyenne,
    this.nombreAvis = 0,
    this.moisCaution,
    this.moisAvance,
    this.fraisAgence,
    required this.datePublication,
    required this.dateMiseAJour,
  });

  // convertit une valeur Firestore en DateTime sans planter si le champ
  // est absent ou d'un type inattendu (anciennes annonces)
  static DateTime _lireDate(dynamic valeur) {
    if (valeur is Timestamp) return valeur.toDate();
    if (valeur is DateTime) return valeur;
    if (valeur is String) return DateTime.tryParse(valeur) ?? DateTime.now();
    return DateTime.now();
  }

  // convertit une valeur Firestore en GeoPoint (GeoPoint direct ou map
  // {latitude, longitude} des anciennes annonces)
  static GeoPoint _lireGeoPoint(dynamic valeur) {
    if (valeur is GeoPoint) return valeur;
    if (valeur is Map) {
      final lat = (valeur['latitude'] ?? valeur['lat'] ?? 0).toDouble();
      final lng = (valeur['longitude'] ?? valeur['lng'] ?? 0).toDouble();
      return GeoPoint(lat, lng);
    }
    return const GeoPoint(0, 0);
  }

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return PropertyModel(
      id: doc.id,
      proprietaireId: d['proprietaireId'] ?? '',
      proprietaireRole: d['proprietaireRole'] ?? '',
      nomProprietaireReel: d['nomProprietaireReel'],
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
      nombreChambres: d['nombreChambres'],
      nombreToilettes: d['nombreToilettes'],
      nombreCuisines: d['nombreCuisines'],
      adresse: d['adresse'] ?? '',
      ville: d['ville'] ?? '',
      quartier: d['quartier'],
      localisation: _lireGeoPoint(d['localisation']),
      photos: List<String>.from(d['photos'] ?? []),
      equipements: List<String>.from(d['equipements'] ?? []),
      estDisponible: d['estDisponible'] ?? true,
      nombreVues: d['nombreVues'] ?? 0,
      nombreFavoris: d['nombreFavoris'] ?? 0,
      statsVues: (d['statsVues'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          const {},
      noteMoyenne: d['noteMoyenne']?.toDouble(),
      nombreAvis: d['nombreAvis'] ?? 0,
      moisCaution: d['moisCaution'],
      moisAvance: d['moisAvance'],
      fraisAgence: d['fraisAgence']?.toDouble(),
      datePublication: _lireDate(d['datePublication'] ?? d['dateCreation']),
      dateMiseAJour: _lireDate(
        d['dateMiseAJour'] ?? d['datePublication'] ?? d['dateCreation'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proprietaireId': proprietaireId,
      'proprietaireRole': proprietaireRole,
      'nomProprietaireReel': nomProprietaireReel,
      'titre': titre,
      'description': description,
      'type': type.name,
      'statut': statut.name,
      'prix': prix,
      'surface': surface,
      'nombrePieces': nombrePieces,
      'nombreChambres': nombreChambres,
      'nombreToilettes': nombreToilettes,
      'nombreCuisines': nombreCuisines,
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'localisation': localisation,
      'photos': photos,
      'equipements': equipements,
      'estDisponible': estDisponible,
      'nombreVues': nombreVues,
      'nombreFavoris': nombreFavoris,
      'statsVues': statsVues,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
      'moisCaution': moisCaution,
      'moisAvance': moisAvance,
      'fraisAgence': fraisAgence,
      'datePublication': Timestamp.fromDate(datePublication),
      'dateMiseAJour': Timestamp.fromDate(dateMiseAJour),
    };
  }
}
