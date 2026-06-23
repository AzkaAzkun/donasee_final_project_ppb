# DonaSee — Final Project PPB

**DonaSee** adalah aplikasi donasi digital berbasis Flutter yang menghubungkan **donatur** dengan **organisasi/admin** pengelola kampanye sosial. Dibangun menggunakan Firebase sebagai backend utama dan Supabase Storage untuk penyimpanan berkas bukti.

Aplikasi ini dikembangkan sebagai **Final Project mata kuliah Pemrograman Perangkat Bergerak (PPB)**.

---

## 🏗️ Teknologi yang Digunakan

| Teknologi | Kegunaan |
|-----------|----------|
| Flutter | Framework utama (Android) |
| Firebase Authentication | Login & Register (role: admin / donatur) |
| Cloud Firestore | Database real-time (CRUD kampanye, donasi, alokasi) |
| Firebase Cloud Messaging | Push notification ke donatur |
| Supabase Storage | Upload bukti donasi & bukti alokasi |
| Exchange Rate API | Konversi nominal donasi ke USD secara real-time |

---

## ✨ Fitur Utama

### Sebagai Donatur
- Register & login sebagai donatur
- Jelajahi kampanye aktif dengan progress bar donasi
- Donasi ke kampanye dengan input nominal + estimasi USD real-time
- Upload foto/dokumen bukti pembayaran
- Pantau status donasi di tab **Donasiku** (Pending → Menunggu Verifikasi → Berhasil)
- Terima push notification saat admin mengalokasikan dana
- Lihat laporan alokasi dana di tab **Kabar Baik**

### Sebagai Admin
- Register & login sebagai admin
- Buat, edit, dan hapus kampanye donasi
- Konfirmasi donasi masuk dari donatur
- Buat, edit, dan hapus catatan alokasi dana
- Notifikasi otomatis terkirim ke seluruh donatur berhasil saat alokasi baru dibuat

---

## 🔄 Alur Demo Aplikasi

```
1.  Register akun ADMIN  → masuk app sebagai admin
2.  Admin buat kampanye  → Rp 5.000.000, batas 30 hari
3.  Kampanye muncul di tab Jelajah dengan progress bar 0%

4.  Register akun DONATUR → masuk app sebagai donatur
5.  Donatur lihat kampanye → buka detail
6.  Donatur klik "Donasi" → input Rp 50.000
7.  Estimasi USD muncul real-time dari Exchange Rate API  ← External API ✓
8.  Donasi tersimpan → status: Pending di tab Donasiku

9.  Donatur upload foto bukti → status: Menunggu Verifikasi

10. Login sebagai ADMIN → konfirmasi donasi
11. Status → Berhasil, terkumpul kampanye +Rp 50.000  ← FieldValue.increment ✓

12. Admin buat catatan alokasi: "20 nasi kotak Rp 400.000"
13. Notif masuk di HP donatur  ← FCM Push Notification ✓
14. Donatur buka tab Kabar Baik → laporan alokasi tampil

15. Admin edit / hapus catatan alokasi  ← Update & Delete ✓
16. Admin hapus kampanye  ← Delete ✓
```

---

## 📲 Setup & Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (≥ 3.11.4)
- Android device atau emulator
- Koneksi internet aktif

### Langkah Setup

```bash
# 1. Clone repository
git clone https://github.com/AzkaAzkun/donasee_final_project_ppb.git
cd donasee_final_project_ppb

# 2. Install Flutter dependencies
flutter pub get

# 3. Jalankan di Android device
flutter run
```

---

## 📲 Tutorial Push Notification (FCM)

Aplikasi ini menggunakan **Firebase Cloud Messaging (FCM) HTTP v1** untuk mengirim push notification ke device Android.

### Cara Kerja

```
1. User login → FCM token disimpan ke Firestore
2. Flutter app menerima notifikasi (foreground, background, terminated)
3. Pengiriman notifikasi dilakukan via backend script (Node.js + Firebase Admin SDK)
```

---

### 🔧 Setup Awal (Untuk Semua Anggota)

#### 1. Pull project & install dependencies

```bash
git pull origin feature/transparansi
flutter pub get
```

#### 2. Jalankan app di Android device/emulator

```bash
flutter run
```

#### 3. Izinkan notifikasi

Saat app pertama kali dijalankan, akan muncul **permission dialog** untuk notifikasi. Tekan **"Allow"**.

#### 4. Copy FCM Token

Lihat di **debug console** (terminal tempat `flutter run` berjalan), cari output seperti ini:

```
========================================
🔑 FCM DEVICE TOKEN:
dK3x8f9abc123xyz456...  ← ini token kamu
========================================
📋 Copy token di atas untuk testing via backend.
```

**Copy token panjang tersebut** — kamu butuh ini untuk langkah selanjutnya.

---

### 📤 Cara Kirim Test Notification

Ada **2 cara** untuk mengirim notifikasi ke device kamu:

#### Cara 1: Via Script Node.js (Butuh serviceAccountKey.json)

1. **Download Service Account Key** dari Firebase Console:
   - Buka [Firebase Console](https://console.firebase.google.com)
   - Pilih project **`final-project-ppb-35cb4`**
   - Buka **Project Settings** → tab **Service accounts**
   - Klik **"Generate new private key"** → Download file JSON
   - **Rename** file menjadi `serviceAccountKey.json`
   - **Pindahkan** ke folder `fcm-backend/`

2. **Install dependencies backend:**
   ```bash
   cd fcm-backend
   npm install
   ```

3. **Edit file `fcm-backend/send-notification.js`:**
   - Buka file tersebut
   - Cari baris:
     ```js
     const FCM_TOKEN = "ISI_DENGAN_FCM_TOKEN_DARI_FLUTTER_DEBUG_CONSOLE";
     ```
   - Ganti dengan token yang kamu copy dari debug console

4. **Kirim notifikasi:**
   ```bash
   node send-notification.js
   ```

5. **Hasil yang diharapkan:**
   ```
   📤 Mengirim notifikasi...
   ✅ Berhasil kirim notifikasi!
      Message ID: projects/final-project-ppb-35cb4/messages/xxx
   ```
   Dan HP kamu akan menerima push notification! 🎉

#### Cara 2: Via Firebase Console (Tanpa serviceAccountKey.json)

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **`final-project-ppb-35cb4`**
3. Di sidebar, klik **Cloud Messaging** (atau **Engage → Messaging**)
4. Klik **"Send your first message"** atau **"New campaign"**
5. Isi:
   - **Title:** `Test Notifikasi`
   - **Body:** `Ini test notification dari Firebase Console`
6. Klik **"Send test message"**
7. **Paste FCM token** yang kamu copy dari debug console
8. Klik **"Test"**

---

### 📱 Skenario Notifikasi

| Kondisi App | Apa yang Terjadi |
|------------|------------------|
| **Foreground** (app terbuka) | Notifikasi muncul sebagai heads-up + log di debug console |
| **Background** (app minimize) | Notifikasi muncul di notification tray |
| **Terminated** (app ditutup) | Notifikasi muncul di notification tray |
| **Tap notifikasi** | App terbuka + log "NOTIFICATION TAPPED" di console |

---

### ⚠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Token tidak muncul di console | Pastikan sudah **Allow** permission notifikasi |
| `serviceAccountKey.json tidak ditemukan` | Download dari Firebase Console (lihat Cara 1 step 1) |
| `registration-token-not-registered` | Token expired — restart Flutter app, copy token baru |
| `invalid-argument` | Pastikan FCM_TOKEN sudah diganti dari placeholder |
| Notifikasi tidak muncul di foreground | Pastikan Android sudah membuat channel `high_importance_channel` |
| Permission dialog tidak muncul | Uninstall app dari device, lalu `flutter run` ulang |

---

### 🔒 Keamanan

> **JANGAN commit `serviceAccountKey.json` ke GitHub!**
>
> File ini sudah ditambahkan ke `.gitignore`. Setiap anggota yang butuh harus download sendiri dari Firebase Console.

---

### 📁 Struktur File Terkait FCM

```
├── lib/
│   ├── main.dart                          # FCM init + background handler
│   └── services/
│       └── notification_service.dart      # FCM service (permission, token, handlers)
├── android/app/src/main/
│   └── AndroidManifest.xml                # POST_NOTIFICATIONS + channel config
├── fcm-backend/                           # Backend test (lokal)
│   ├── package.json
│   ├── send-notification.js               # Script kirim notifikasi
│   ├── serviceAccountKey.json             # ⚠️ JANGAN commit! (gitignored)
│   └── README.md                          # Dokumentasi backend
└── functions/                             # Cloud Functions (untuk Blaze plan)
    ├── index.js                           # Auto-trigger saat alokasi baru
    └── package.json
```

---

## ⚠️ Penting: Setup `serviceAccountKey.json` untuk Fitur Notifikasi Otomatis

File `assets/serviceAccountKey.json` **tidak ikut di-push ke GitHub** karena masuk `.gitignore` — ini disengaja demi keamanan, karena service account key memiliki akses penuh ke project Firebase dan tidak boleh tersebar di repository publik.

### Langkah yang harus dilakukan setelah `git pull` / merge ke `main`:

1. Ambil file `serviceAccountKey.json` dari anggota tim (share via grup/WA/drive).  
   *(File yang sama ada di folder `fcm-backend/serviceAccountKey.json` milik anggota yang sudah punya)*

2. **Salin manual** file tersebut ke folder `assets/` di root project:
   ```
   donasee_final_project_ppb/
   └── assets/
       └── serviceAccountKey.json  ← letakkan di sini
   ```

3. Jalankan ulang aplikasi:
   ```bash
   flutter run
   ```

Tanpa file ini di folder `assets/`, fitur **push notification otomatis** (saat admin buat alokasi) tidak akan berfungsi.


---

## 📲 Tutorial Push Notification (FCM)

Aplikasi ini menggunakan **Firebase Cloud Messaging (FCM) HTTP v1** untuk mengirim push notification ke device Android.

### Cara Kerja

```
1. User login → FCM token disimpan ke Firestore
2. Flutter app menerima notifikasi (foreground, background, terminated)
3. Pengiriman notifikasi dilakukan via backend script (Node.js + Firebase Admin SDK)
```

---

### 🔧 Setup Awal (Untuk Semua Anggota)

#### 1. Pull project & install dependencies

```bash
git pull origin feature/transparansi
flutter pub get
```

#### 2. Jalankan app di Android device/emulator

```bash
flutter run
```

#### 3. Izinkan notifikasi

Saat app pertama kali dijalankan, akan muncul **permission dialog** untuk notifikasi. Tekan **"Allow"**.

#### 4. Copy FCM Token

Lihat di **debug console** (terminal tempat `flutter run` berjalan), cari output seperti ini:

```
========================================
🔑 FCM DEVICE TOKEN:
dK3x8f9abc123xyz456...  ← ini token kamu
========================================
📋 Copy token di atas untuk testing via backend.
```

**Copy token panjang tersebut** — kamu butuh ini untuk langkah selanjutnya.

---

### 📤 Cara Kirim Test Notification

Ada **2 cara** untuk mengirim notifikasi ke device kamu:

#### Cara 1: Via Script Node.js (Butuh serviceAccountKey.json)

1. **Download Service Account Key** dari Firebase Console:
   - Buka [Firebase Console](https://console.firebase.google.com)
   - Pilih project **`final-project-ppb-35cb4`**
   - Buka **Project Settings** → tab **Service accounts**
   - Klik **"Generate new private key"** → Download file JSON
   - **Rename** file menjadi `serviceAccountKey.json`
   - **Pindahkan** ke folder `fcm-backend/`

2. **Install dependencies backend:**
   ```bash
   cd fcm-backend
   npm install
   ```

3. **Edit file `fcm-backend/send-notification.js`:**
   - Buka file tersebut
   - Cari baris:
     ```js
     const FCM_TOKEN = "ISI_DENGAN_FCM_TOKEN_DARI_FLUTTER_DEBUG_CONSOLE";
     ```
   - Ganti dengan token yang kamu copy dari debug console

4. **Kirim notifikasi:**
   ```bash
   node send-notification.js
   ```

5. **Hasil yang diharapkan:**
   ```
   📤 Mengirim notifikasi...
   ✅ Berhasil kirim notifikasi!
      Message ID: projects/final-project-ppb-35cb4/messages/xxx
   ```
   Dan HP kamu akan menerima push notification! 🎉

#### Cara 2: Via Firebase Console (Tanpa serviceAccountKey.json)

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project **`final-project-ppb-35cb4`**
3. Di sidebar, klik **Cloud Messaging** (atau **Engage → Messaging**)
4. Klik **"Send your first message"** atau **"New campaign"**
5. Isi:
   - **Title:** `Test Notifikasi`
   - **Body:** `Ini test notification dari Firebase Console`
6. Klik **"Send test message"**
7. **Paste FCM token** yang kamu copy dari debug console
8. Klik **"Test"**

---

### 📱 Skenario Notifikasi

| Kondisi App | Apa yang Terjadi |
|------------|------------------|
| **Foreground** (app terbuka) | Notifikasi muncul sebagai heads-up + log di debug console |
| **Background** (app minimize) | Notifikasi muncul di notification tray |
| **Terminated** (app ditutup) | Notifikasi muncul di notification tray |
| **Tap notifikasi** | App terbuka + log "NOTIFICATION TAPPED" di console |

---

### ⚠️ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Token tidak muncul di console | Pastikan sudah **Allow** permission notifikasi |
| `serviceAccountKey.json tidak ditemukan` | Download dari Firebase Console (lihat Cara 1 step 1) |
| `registration-token-not-registered` | Token expired — restart Flutter app, copy token baru |
| `invalid-argument` | Pastikan FCM_TOKEN sudah diganti dari placeholder |
| Notifikasi tidak muncul di foreground | Pastikan Android sudah membuat channel `high_importance_channel` |
| Permission dialog tidak muncul | Uninstall app dari device, lalu `flutter run` ulang |

---

### 🔒 Keamanan

> **JANGAN commit `serviceAccountKey.json` ke GitHub!**
>
> File ini sudah ditambahkan ke `.gitignore`. Setiap anggota yang butuh harus download sendiri dari Firebase Console.

---

### 📁 Struktur File Terkait FCM

```
├── lib/
│   ├── main.dart                          # FCM init + background handler
│   └── services/
│       └── notification_service.dart      # FCM service (permission, token, handlers)
├── android/app/src/main/
│   └── AndroidManifest.xml                # POST_NOTIFICATIONS + channel config
├── fcm-backend/                           # Backend test (lokal)
│   ├── package.json
│   ├── send-notification.js               # Script kirim notifikasi
│   ├── serviceAccountKey.json             # ⚠️ JANGAN commit! (gitignored)
│   └── README.md                          # Dokumentasi backend
└── functions/                             # Cloud Functions (untuk Blaze plan)
    ├── index.js                           # Auto-trigger saat alokasi baru
    └── package.json
```
