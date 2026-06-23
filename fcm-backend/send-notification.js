/**
 * send-notification.js
 *
 * Script untuk mengirim push notification ke device Android/iOS
 * menggunakan Firebase Admin SDK (FCM HTTP v1).
 *
 * CARA PAKAI:
 *   1. Download service account key dari Firebase Console:
 *      Project Settings → Service accounts → Generate new private key
 *   2. Simpan sebagai "serviceAccountKey.json" di folder ini (fcm-backend/)
 *   3. Jalankan: npm install && node send-notification.js
 *
 * PENTING:
 *   - JANGAN commit serviceAccountKey.json ke GitHub!
 *   - File sudah ditambahkan ke .gitignore
 */

const admin = require("firebase-admin");
const path = require("path");

// ─── Load Service Account ────────────────────────────────────────────────────
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

let serviceAccount;
try {
  serviceAccount = require(serviceAccountPath);
} catch (error) {
  console.error("❌ File serviceAccountKey.json tidak ditemukan!");
  console.error("");
  console.error("   Cara mendapatkan:");
  console.error("   1. Buka https://console.firebase.google.com");
  console.error("   2. Pilih project 'final-project-ppb-35cb4'");
  console.error("   3. Project Settings → Service accounts");
  console.error("   4. Klik 'Generate new private key'");
  console.error("   5. Simpan file sebagai 'serviceAccountKey.json' di folder fcm-backend/");
  console.error("");
  process.exit(1);
}

// ─── Initialize Firebase Admin ───────────────────────────────────────────────
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ─── Konfigurasi Notifikasi ──────────────────────────────────────────────────
// Ganti FCM_TOKEN di bawah dengan token dari Flutter debug console.
// Token akan terprint saat app dijalankan:
//   ========================================
//   🔑 FCM DEVICE TOKEN:
//   <token ada di sini>
//   ========================================

const FCM_TOKEN = "danozC1cR6izYeagQGeVQH:APA91bGwZT_AzgRt8L389V12XeFenDP1b2ByyJkhb4tBj5fAw-0lNrRXhNVU_0FlAiHLRZcUlpRSSnh9qpr00KA4PQn61ykEaYMURQJO_866xHi27iiXiHk";

const message = {
  token: FCM_TOKEN,
  notification: {
    title: "Test Notifikasi DonaSee 🎉",
    body: "Notifikasi berhasil dikirim dari Firebase Admin SDK!",
  },
  android: {
    priority: "high",
    notification: {
      channelId: "high_importance_channel",
      priority: "high",
      defaultSound: true,
      defaultVibrateTimings: true,
    },
  },
  data: {
    screen: "kabar_baik",
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  },
};

// ─── Kirim Notifikasi ────────────────────────────────────────────────────────
console.log("📤 Mengirim notifikasi...");
console.log(`   Project : final-project-ppb-35cb4`);
console.log(`   Token   : ${FCM_TOKEN.substring(0, 20)}...`);
console.log("");

admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log("✅ Berhasil kirim notifikasi!");
    console.log(`   Message ID: ${response}`);
  })
  .catch((error) => {
    console.error("❌ Gagal kirim notifikasi:");
    console.error(`   Code   : ${error.code}`);
    console.error(`   Message: ${error.message}`);

    if (error.code === "messaging/registration-token-not-registered") {
      console.error("");
      console.error("   💡 Token sudah expired. Jalankan ulang Flutter app");
      console.error("      dan copy token baru dari debug console.");
    }

    if (error.code === "messaging/invalid-argument") {
      console.error("");
      console.error("   💡 Pastikan FCM_TOKEN sudah diganti dengan token");
      console.error("      yang valid dari Flutter debug console.");
    }
  });
