# FCM Backend Test — DonaSee

Script Node.js untuk mengirim push notification ke app DonaSee menggunakan **Firebase Admin SDK (FCM HTTP v1)**.

> ⚠️ **JANGAN** commit `serviceAccountKey.json` ke GitHub!

## Setup

### 1. Download Service Account Key

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **`final-project-ppb-35cb4`**
3. Buka **Project Settings** → tab **Service accounts**
4. Klik **"Generate new private key"**
5. Simpan file sebagai `serviceAccountKey.json` di folder `fcm-backend/` ini

### 2. Install Dependencies

```bash
cd fcm-backend
npm install
```

### 3. Dapatkan FCM Token

1. Jalankan Flutter app di Android device/emulator:
   ```bash
   flutter run
   ```
2. Lihat di debug console, cari output:
   ```
   ========================================
   🔑 FCM DEVICE TOKEN:
   <token-mu ada di sini>
   ========================================
   ```
3. Copy token tersebut

### 4. Edit & Kirim Notification

1. Buka `send-notification.js`
2. Ganti value `FCM_TOKEN` dengan token dari step 3
3. Jalankan:
   ```bash
   node send-notification.js
   ```
   atau:
   ```bash
   npm run send
   ```

## Troubleshooting

| Error | Solusi |
|-------|--------|
| `serviceAccountKey.json tidak ditemukan` | Download dari Firebase Console (lihat step 1) |
| `registration-token-not-registered` | Token expired, restart Flutter app dan copy token baru |
| `invalid-argument` | Pastikan FCM_TOKEN sudah diganti dari placeholder |
| Notifikasi tidak muncul di foreground | Pastikan `high_importance_channel` sudah terdaftar |

## Alternatif: Test via Firebase Console

Jika tidak mau pakai script ini, bisa test langsung dari Firebase Console:

1. Buka [Firebase Console](https://console.firebase.google.com) → **Cloud Messaging**
2. Klik **"Send your first message"** atau **"New campaign"**
3. Isi judul & body
4. Target: **Single device** → paste FCM token
5. Klik **Send**
