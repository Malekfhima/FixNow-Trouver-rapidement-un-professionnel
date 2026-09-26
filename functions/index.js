/**
 * FixNow — Cloud Functions (Node.js).
 *
 * Envoie des notifications push (FCM) aux utilisateurs via le champ
 * `fcmToken` stocké dans `users/{uid}`.
 *
 * Triggers :
 *  - serviceRequests/{requestId} onCreate  → notifie le professionnel (proId)
 *  - chats/{chatId}/messages/{messageId} onCreate → notifie l'autre participant
 *
 * Déploiement (plan Blaze requis pour les Functions) :
 *   firebase deploy --only functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Limite le nombre de conteneurs simultanés (maîtrise des coûts).
setGlobalOptions({maxInstances: 10});

/**
 * Tronque un texte pour un corps de notification lisible.
 *
 * @param {string} text Texte brut à tronquer.
 * @param {number} max Longueur maximale souhaitée.
 * @return {string} Le texte nettoyé et tronqué.
 */
function preview(text, max = 120) {
  const clean = (text || "").trim().replace(/\s+/g, " ");
  if (!clean) return "";
  return clean.length > max ? `${clean.slice(0, max - 1)}…` : clean;
}

/** Codes d'erreur FCM signalant un jeton définitivement invalide. */
const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/**
 * Envoie une notification push à un utilisateur.
 *
 * Lit `users/{uid}.fcmToken` ; si le jeton est absent, ne fait rien.
 * Un jeton rejeté par FCM est supprimé du profil (best-effort).
 *
 * @param {string} uid Identifiant du destinataire.
 * @param {!Object} options Titre, corps et données de la notification.
 * @return {!Promise<void>} Résolue une fois l'envoi tenté.
 */
async function sendToUser(uid, options) {
  if (!uid) return;

  const {title, body, data = {}} = options;

  let token;
  try {
    const snap = await db.collection("users").doc(uid).get();
    token = snap.get("fcmToken");
  } catch (err) {
    logger.error("Lecture du fcmToken impossible", {uid, err: String(err)});
    return;
  }

  if (!token) {
    logger.info("Aucun fcmToken pour l'utilisateur — notification ignorée", {
      uid,
    });
    return;
  }

  try {
    await messaging.send({
      token,
      notification: {title, body},
      data,
      android: {
        priority: "high",
        notification: {channelId: "fixnow_default"},
      },
      apns: {
        payload: {aps: {sound: "default", badge: 1}},
      },
    });
    logger.info("Notification envoyée", {uid, type: data.type || null});
  } catch (err) {
    logger.error("Échec d'envoi FCM", {uid, err: String(err)});
    if (INVALID_TOKEN_CODES.has(err && err.code)) {
      await db
          .collection("users")
          .doc(uid)
          .update({fcmToken: admin.firestore.FieldValue.delete()})
          .catch(() => {});
    }
  }
}

/**
 * Nouvelle demande de service → notifie le professionnel assigné.
 */
exports.onServiceRequestCreated = onDocumentCreated(
    "serviceRequests/{requestId}",
    async (event) => {
      const data = event.data ? event.data.data() : null;
      if (!data) return;

      const proId = data.proId;
      const clientId = data.clientId;
      // Sans proId (demande ouverte) il n'y a pas de destinataire unique.
      if (!proId || proId === clientId) {
        logger.info("Demande sans professionnel assigné — pas de push", {
          requestId: event.params.requestId,
        });
        return;
      }

      const body =
        preview(data.description) ||
        "Un client vous a envoyé une demande de service.";

      await sendToUser(proId, {
        title: "Nouvelle demande de service",
        body,
        data: {
          type: "newRequest",
          requestId: event.params.requestId,
          categoryId: data.categoryId || "",
        },
      });
    },
);

/**
 * Nouveau message de chat → notifie l'autre participant.
 *
 * Le chat stocke `clientId` / `proId` (pas de tableau `participants`) :
 * le destinataire est celui qui n'est PAS l'expéditeur.
 */
exports.onChatMessageCreated = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const message = event.data ? event.data.data() : null;
      if (!message) return;

      const chatId = event.params.chatId;
      const senderId = message.senderId;

      const chatSnap = await db.collection("chats").doc(chatId).get();
      if (!chatSnap.exists) return;

      const chat = chatSnap.data() || {};
      const recipientId =
        chat.clientId === senderId ? chat.proId : chat.clientId;

      if (!recipientId || recipientId === senderId) {
        logger.info("Destinataire introuvable — pas de push", {chatId});
        return;
      }

      const body =
        preview(message.text) ||
        (message.imageUrl ? "📷 Photo" : "Nouveau message");

      await sendToUser(recipientId, {
        title: "Nouveau message",
        body,
        data: {
          type: "newMessage",
          chatId,
          senderId: senderId || "",
        },
      });
    },
);
