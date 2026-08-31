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
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

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
