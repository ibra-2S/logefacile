import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // utilisateur connecté en ce moment
  User? get utilisateurActuel => _auth.currentUser;

  // flux de changement d'état de connexion
  Stream<User?> get etatConnexion => _auth.authStateChanges();

  // inscription d'un nouvel utilisateur
  Future<UserModel?> inscrire({
    required String email,
    required String motDePasse,
    required String nomComplet,
    required UserRole role,
    String? telephone,
  }) async {
    try {
      final resultat = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      final nouvelUtilisateur = UserModel(
        uid: resultat.user!.uid,
        email: email,
        nomComplet: nomComplet,
        role: role,
        telephone: telephone,
        dateCreation: DateTime.now(),
        derniereCo: DateTime.now(),
      );

      // sauvegarde dans Firestore
      await _db
          .collection('users')
          .doc(resultat.user!.uid)
          .set(nouvelUtilisateur.toMap());

      return nouvelUtilisateur;
    } catch (e) {
      throw _gererErreur(e);
    }
  }

  // connexion avec email et mot de passe
  Future<UserModel?> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final resultat = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );

      // mise à jour de la dernière connexion
      await _db.collection('users').doc(resultat.user!.uid).update({
        'derniereCo': Timestamp.fromDate(DateTime.now()),
      });

      return await recupererUtilisateur(resultat.user!.uid);
    } catch (e) {
      throw _gererErreur(e);
    }
  }

  // connexion avec Google
  Future<UserModel?> connecterAvecGoogle({
    UserRole role = UserRole.locataire,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final resultat = await _auth.signInWithCredential(credential);
      final uid = resultat.user!.uid;

      // vérifier si l'utilisateur existe déjà dans Firestore
      final docExistant = await _db.collection('users').doc(uid).get();

      if (!docExistant.exists) {
        // premier login Google — créer le profil
        final nouvelUtilisateur = UserModel(
          uid: uid,
          email: resultat.user!.email ?? '',
          nomComplet: resultat.user!.displayName ?? '',
          role: role,
          photoUrl: resultat.user!.photoURL,
          dateCreation: DateTime.now(),
          derniereCo: DateTime.now(),
        );
        await _db.collection('users').doc(uid).set(nouvelUtilisateur.toMap());
        return nouvelUtilisateur;
      } else {
        // utilisateur existant — mise à jour dernière connexion
        await _db.collection('users').doc(uid).update({
          'derniereCo': Timestamp.fromDate(DateTime.now()),
        });
        return await recupererUtilisateur(uid);
      }
    } catch (e) {
      throw _gererErreur(e);
    }
  }

  // déconnexion
  Future<void> deconnecter() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // récupérer les infos d'un utilisateur depuis Firestore
  Future<UserModel?> recupererUtilisateur(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      return null;
    }
  }

  // réinitialisation du mot de passe
  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _gererErreur(e);
    }
  }

  // traduction des erreurs Firebase en messages compréhensibles
  String _gererErreur(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé.';
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'weak-password':
          return 'Mot de passe trop faible (6 caractères minimum).';
        case 'user-not-found':
          return 'Aucun compte trouvé avec cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        default:
          return 'Une erreur est survenue. Réessayez.';
      }
    }
    return 'Erreur inattendue. Réessayez.';
  }
}
