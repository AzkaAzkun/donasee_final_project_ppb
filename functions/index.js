/**
 * Firebase Cloud Functions — DonaSee
 *
 * Auto-kirim push notification ke donatur saat alokasi baru dibuat.
 * Berjalan di server Firebase, TIDAK perlu serviceAccountKey.json.
 *
 * DEPLOY:
 *   firebase login
 *   firebase deploy --only functions
 *
 * CATATAN:
 *   - Memerlukan Blaze plan (pay-as-you-go) untuk Cloud Functions
 *   - Gratis untuk penggunaan kecil (2 juta invocation/bulan)
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin (otomatis tanpa service account saat deploy)
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Trigger: Saat dokumen baru dibuat di collection "allocations"
 *
 * Flow:
 * 1. Ambil kampanyeId dan kampanyeJudul dari dokumen alokasi baru
 * 2. Query semua donasi berhasil untuk kampanye tersebut
 * 3. Kumpulkan FCM token dari setiap donatur
 * 4. Kirim push notification ke semua donatur
 */
exports.onAllocationCreated = onDocumentCreated(
  "allocations/{allocationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Tidak ada data di dokumen alokasi baru.");
      return;
    }

    const allocationData = snapshot.data();
    const kampanyeId = allocationData.kampanyeId;
    const kampanyeJudul = allocationData.kampanyeJudul || "Kampanye";
    const judulAlokasi = allocationData.judulAlokasi || "";

    logger.info(
      `Alokasi baru untuk kampanye "${kampanyeJudul}" (${kampanyeId})`,
    );

    try {
      // 1. Query semua donasi berhasil untuk kampanye ini
      const donationsSnapshot = await db
        .collection("donations")
        .where("kampanyeId", "==", kampanyeId)
        .where("status", "==", "berhasil")
        .get();

      if (donationsSnapshot.empty) {
        logger.info("Tidak ada donasi berhasil untuk kampanye ini.");
        return;
      }

      // 2. Kumpulkan unique donatur IDs
      const donaturIds = [
        ...new Set(
          donationsSnapshot.docs
            .map((doc) => doc.data().donaturId)
            .filter(Boolean),
        ),
      ];

      logger.info(`Ditemukan ${donaturIds.length} donatur unik.`);

      // 3. Ambil FCM token untuk setiap donatur
      const tokens = [];
      for (const uid of donaturIds) {
        const userDoc = await db.collection("users").doc(uid).get();
        const token = userDoc.data()?.fcmToken;
        if (token && token.length > 0) {
          tokens.push(token);
        }
      }

      if (tokens.length === 0) {
        logger.info("Tidak ada donatur dengan FCM token.");
        return;
      }

      logger.info(`Mengirim notifikasi ke ${tokens.length} device.`);

      // 4. Kirim notifikasi ke semua token
      const message = {
        notification: {
          title: "Kabar Donasi Anda! 🎉",
          body: `Dana di "${kampanyeJudul}" telah dialokasikan${judulAlokasi ? `: ${judulAlokasi}` : ""}. Cek laporannya!`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
            defaultSound: true,
          },
        },
        data: {
          screen: "kabar_baik",
          kampanyeId: kampanyeId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Kirim ke setiap token (sendEach lebih reliable dari sendMulticast)
      const sendPromises = tokens.map((token) =>
        messaging.send({ ...message, token }).catch((error) => {
          logger.warn(`Gagal kirim ke token ${token.substring(0, 20)}...`, error.message);
          // Hapus token yang invalid dari Firestore
          if (
            error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token"
          ) {
            return cleanupInvalidToken(token);
          }
          return null;
        }),
      );

      const results = await Promise.all(sendPromises);
      const successCount = results.filter(
        (r) => r && typeof r === "string",
      ).length;

      logger.info(
        `Notifikasi terkirim: ${successCount}/${tokens.length} berhasil.`,
      );
    } catch (error) {
      logger.error("Gagal mengirim notifikasi alokasi:", error);
    }
  },
);

/**
 * Bersihkan token yang sudah tidak valid dari Firestore.
 */
async function cleanupInvalidToken(invalidToken) {
  try {
    const usersSnapshot = await db
      .collection("users")
      .where("fcmToken", "==", invalidToken)
      .get();

    const batch = db.batch();
    usersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { fcmToken: "" });
    });
    await batch.commit();

    logger.info(`Token invalid dibersihkan untuk ${usersSnapshot.size} user.`);
  } catch (error) {
    logger.warn("Gagal membersihkan token invalid:", error);
  }
}
