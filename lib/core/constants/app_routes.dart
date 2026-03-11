// toutes les routes de l'app
// ce fichier est le seul endroit où on définit les noms de routes
class AppRoutes {
  static const connexion = '/connexion';
  static const inscription = '/inscription';
  static const choixRole = '/choix-role';

  // propriétaire et agent
  static const tableauBordProprietaire = '/proprietaire';
  static const ajouterBien = '/proprietaire/ajouter-bien';
  static const mesBiens = '/proprietaire/mes-biens';
  static const demandesVisite = '/proprietaire/demandes-visite';

  // locataire
  static const rechercheLocataire = '/locataire';
  static const detailBien = '/locataire/bien/:id';
  static const mesFavoris = '/locataire/favoris';
  static const mesDemandesVisite = '/locataire/mes-demandes';
  static const mesAlertes = '/locataire/alertes';

  // commun
  static const conversations = '/conversations';
  static const profil = '/profil';

  // admin
  static const tableauBordAdmin = '/admin';
  static const gestionUtilisateurs = '/admin/utilisateurs';
  static const signalements = '/admin/signalements';
}
