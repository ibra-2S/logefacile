/**
 * Cloud Function LogeFacile — envoi des notifications push.
 *
 * À chaque création d'un document dans `notifications/{id}`, on envoie une
 * notification FCM à tous les appareils (fcmTokens) du destinataire.
 *
 * Déploiement :
 *   npm --prefix functions install
 *   firebase deploy --only functions
 * (nécessite le plan Blaze pour les fonctions v2)
 */
const {onDocumentCreated, onDocumentWritten} =
    require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

/**
 * Miroir public d'un bien (collection `properties_public`).
 *
 * `properties/{id}` contient des champs sensibles (adresse exacte,
 * coordonnées GPS précises, nom réel du propriétaire, uid) qui ne doivent
 * pas être lisibles sans compte. Pour permettre au mode invité de parcourir
 * les annonces sans exposer ces champs, on ne rend public qu'un sous-
 * ensemble "vitrine" des données, recopié automatiquement ici à chaque
 * écriture — impossible à contourner ou désynchroniser côté client
 * puisque `properties_public` n'est jamais écrit directement par l'app
 * (voir les règles Firestore : write refusé, seul l'Admin SDK peut écrire).
 */
const CHAMPS_PUBLICS = [
  "titre", "type", "statut", "prix", "ville", "commune", "quartier",
  "photos", "estDisponible", "nombreVues", "nombreChambres",
  "nombrePieces", "nombreToilettes", "nombreCuisines", "surface",
  "datePublication", "dateMiseAJour",
];

exports.miroirBienPublic = onDocumentWritten(
    "properties/{id}",
    async (event) => {
      const id = event.params.id;
      const db = getFirestore();
      const apres = event.data.after.exists ? event.data.after.data() : null;

      if (!apres) {
        // bien supprimé : la fiche publique disparaît aussi
        await db.collection("properties_public").doc(id).delete()
            .catch(() => {});
        return;
      }

      const vitrine = {};
      for (const champ of CHAMPS_PUBLICS) {
        if (apres[champ] !== undefined) vitrine[champ] = apres[champ];
      }
      await db.collection("properties_public").doc(id).set(vitrine);
    },
);

/**
 * Alertes de recherche : à chaque nouveau bien publié (ou remis disponible),
 * on compare ses caractéristiques à chaque alerte active et on crée une
 * notification pour le locataire concerné si ça correspond. Cette
 * notification déclenche ensuite `envoiPushNotification` normalement.
 *
 * Règles de correspondance :
 *  - ville / commune / type : si l'alerte précise un critère, le bien doit
 *    le respecter exactement ; si le critère est vide, il n'est pas filtré.
 *  - prixMax : le prix du bien doit être inférieur ou égal.
 *  - equipements : le bien doit avoir AU MOINS UNE des commodités cochées
 *    dans l'alerte (correspondance en OU, pas en ET) ; si l'alerte n'a
 *    coché aucune commodité, ce critère n'est pas filtré.
 */
exports.notifierAlertesCorrespondantes = onDocumentWritten(
    "properties/{id}",
    async (event) => {
      const avant = event.data.before.exists ?
        event.data.before.data() : null;
      const apres = event.data.after.exists ? event.data.after.data() : null;
      if (!apres || apres.estDisponible !== true) return;

      const estNouveau = !avant;
      const redevientDisponible = avant && avant.estDisponible !== true;
      if (!estNouveau && !redevientDisponible) return;

      const db = getFirestore();
      const bienId = event.params.id;
      const equipementsBien = apres.equipements || [];

      const alertesSnap = await db.collection("searchAlerts")
          .where("active", "==", true)
          .get();

      for (const doc of alertesSnap.docs) {
        const alerte = doc.data();

        if (alerte.ville && apres.ville !== alerte.ville) continue;
        if (alerte.commune && apres.commune !== alerte.commune) continue;
        if (alerte.type && apres.type !== alerte.type) continue;
        if (typeof alerte.prixMax === "number" &&
            apres.prix > alerte.prixMax) continue;
        if (Array.isArray(alerte.equipements) &&
            alerte.equipements.length > 0) {
          const uneCorrespondance = alerte.equipements
              .some((e) => equipementsBien.includes(e));
          if (!uneCorrespondance) continue;
        }

        // id fixe = pas de doublon si le bien remonte plusieurs fois pour
        // la même alerte (ex: rendu disponible puis loué puis re-disponible)
        const idNotif = `alerte_${doc.id}_${bienId}`;
        await db.collection("notifications").doc(idNotif).create({
          destinataireId: alerte.locataireId,
          type: "alerteCorrespondante",
          titre: "🔔 Nouveau bien correspondant",
          corps: `« ${apres.titre || "Un bien"} » correspond à l'une de ` +
              "vos alertes.",
          lien: `/locataire/bien/${bienId}`,
          lu: false,
          dateCreation: FieldValue.serverTimestamp(),
        }).catch(() => {}); // déjà notifié pour ce couple alerte/bien
      }
    },
);

exports.envoiPushNotification = onDocumentCreated(
    "notifications/{id}",
    async (event) => {
      const data = event.data && event.data.data();
      if (!data || !data.destinataireId) return;

      const db = getFirestore();
      const userSnap = await db.collection("users")
          .doc(data.destinataireId).get();
      const tokens = (userSnap.get("fcmTokens") || []).filter(Boolean);
      if (tokens.length === 0) return;

      const message = {
        tokens: tokens,
        notification: {
          title: data.titre || "LogeFacile",
          body: data.corps || "",
        },
        data: {lien: data.lien || ""},
        android: {priority: "high", notification: {sound: "default"}},
      };

      const resp = await getMessaging().sendEachForMulticast(message);

      // retirer les tokens devenus invalides
      const invalides = [];
      resp.responses.forEach((r, i) => {
        if (!r.success) {
          const code = (r.error && r.error.code) || "";
          if (code.includes("registration-token-not-registered") ||
              code.includes("invalid-argument")) {
            invalides.push(tokens[i]);
          }
        }
      });
      if (invalides.length > 0) {
        await db.collection("users").doc(data.destinataireId).update({
          fcmTokens: FieldValue.arrayRemove(...invalides),
        });
      }
    },
);
