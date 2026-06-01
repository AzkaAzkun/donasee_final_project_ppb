import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final _col = FirebaseFirestore.instance.collection('campaigns');

  // CREATE — admin buat kampanye baru
  Future<void> createCampaign(CampaignModel c) async {
    await _col.add(c.toFirestore());
  }

  // READ — stream semua kampanye aktif (real-time)
  Stream<List<CampaignModel>> getCampaignsStream() {
    return _col
        .where('status', isEqualTo: 'aktif')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => CampaignModel.fromFirestore(d.data(), d.id))
            .toList());
  }

  // READ — stream 1 kampanye by ID (untuk halaman detail)
  Stream<CampaignModel?> getCampaignByIdStream(String id) {
    return _col.doc(id).snapshots().map((s) =>
        s.exists ? CampaignModel.fromFirestore(s.data()!, s.id) : null);
  }

  // UPDATE — edit deskripsi / perpanjang batas tanggal
  Future<void> updateCampaign(String id, Map<String, dynamic> fields) async {
    await _col.doc(id).update(fields);
  }

  // DELETE — hapus kampanye
  Future<void> deleteCampaign(String id) async {
    await _col.doc(id).delete();
  }

  // Dipanggil oleh DonationService setelah konfirmasi berhasil
  Future<void> checkAndClose(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return;
    final d = doc.data()!;
    if ((d['terkumpul'] as int) >= (d['targetDana'] as int)) {
      await _col.doc(id).update({'status': 'selesai'});
    }
  }
}
