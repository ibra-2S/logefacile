/**
 * Script à exécuter UNE SEULE FOIS pour remplir `properties_public` avec
 * les biens déjà publiés avant la mise en place du miroir automatique
 * (fonction `miroirBienPublic` dans index.js).
 *
 * Sans ce script, les annonces existantes qui ne reçoivent plus aucune
 * écriture (pas de nouvelle vue, pas de modification) resteraient invisibles
 * pour les visiteurs sans compte tant qu'elles ne sont pas re-sauvegardées.
 *
 * Utilisation :
 *   1. Firebase Console → Paramètres du projet → Comptes de service
 *      → « Générer une nouvelle clé privée » → enregistrer le fichier
 *      sous functions/serviceAccountKey.json (déjà ignoré par git).
 *   2. npm --prefix functions install
 *   3. node functions/backfill-public-properties.js
 */
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const CHAMPS_PUBLICS = [
  "titre", "type", "statut", "prix", "ville", "commune", "quartier",
  "photos", "estDisponible", "nombreVues", "nombreChambres",
  "nombrePieces", "nombreToilettes", "nombreCuisines", "surface",
  "datePublication", "dateMiseAJour",
];

async function backfill() {
  const snap = await db.collection("properties").get();
  console.log(`${snap.size} bien(s) trouvé(s) dans "properties".`);

  let batch = db.batch();
  let compteur = 0;

  for (const doc of snap.docs) {
    const donnees = doc.data();
    const vitrine = {};
    for (const champ of CHAMPS_PUBLICS) {
      if (donnees[champ] !== undefined) vitrine[champ] = donnees[champ];
    }
    batch.set(db.collection("properties_public").doc(doc.id), vitrine);
    compteur++;

    // Firestore limite un batch à 500 écritures
    if (compteur % 450 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  await batch.commit();

  console.log(`Terminé : ${compteur} fiche(s) publique(s) créée(s)/mise(s) à jour.`);
}

backfill().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
