const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendAllocationNotifications = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { kampanyeId, kampanyeJudul } = req.body || {};
  if (!kampanyeId) {
    res.status(400).send({ error: 'Missing kampanyeId' });
    return;
  }

  try {
    const donationsSnap = await admin.firestore()
      .collection('donations')
      .where('kampanyeId', '==', kampanyeId)
      .where('status', '==', 'berhasil')
      .get();

    const donaturIds = Array.from(
      new Set(
        donationsSnap.docs
          .map((d) => d.data()?.donaturId)
          .filter((v) => typeof v === 'string')
      )
    );

    const tokens = [];
    for (const uid of donaturIds) {
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      const t = userDoc.data()?.fcmToken;
      if (t) tokens.push(t);
    }

    if (tokens.length === 0) {
      res.status(200).send({ sent: 0, message: 'No tokens found' });
      return;
    }

    const messages = tokens.map((token) => ({
      token,
      notification: {
        title: `Kabar Donasi Anda! 🎉`,
        body: `Dana di "${kampanyeJudul || 'kampanye'}" telah dialokasikan. Cek laporannya!`,
      },
      data: { screen: 'kabar_baik' },
    }));

    const chunkSize = 500; // FCM limit for sendAll
    let sent = 0;
    for (let i = 0; i < messages.length; i += chunkSize) {
      const chunk = messages.slice(i, i + chunkSize);
      const resp = await admin.messaging().sendAll(chunk);
      sent += resp.successCount || 0;
    }

    res.status(200).send({ sent });
  } catch (err) {
    console.error('Error sending allocation notifications', err);
    res.status(500).send({ error: String(err) });
  }
});
