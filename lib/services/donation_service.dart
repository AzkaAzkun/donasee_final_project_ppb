import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/donation_model.dart';
import 'campaign_service.dart';

class DonationService {
  final _col = FirebaseFirestore.instance.collection('donations');
  final _db = FirebaseFirestore.instance;
  final _campaignSvc = CampaignService();
  final _supabase = Supabase.instance.client;

  static const _bucket = 'bukti-transfer';

  Future<void> createDonation(DonationModel d) async {
    await _col.add(d.toFirestore());
  }

  Stream<List<DonationModel>> getDonationsByUserStream(String uid) {
    return _col
        .where('donaturId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => DonationModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<DonationModel>> getDonationsByCampaignStream(String campaignId) {
    return _col
        .where('kampanyeId', isEqualTo: campaignId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => DonationModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Future<bool> uploadBuktiFoto(String donationId) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 75,
      );
      if (file == null) return false;

      final ext = p.extension(file.name).toLowerCase(); // .jpg / .png
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final filePath = 'bukti/$donationId/$fileName';
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == '.png' ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(filePath);

      await _col.doc(donationId).update({
        'buktiFotoUrl': publicUrl,
        'status': DonationStatus.menungguVerifikasi,
      });

      return true;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> konfirmasiDonasi(
    String donationId,
    String campaignId,
    int nominal,
  ) async {
    final batch = _db.batch();

    batch.update(_col.doc(donationId), {'status': DonationStatus.berhasil});

    batch.update(_db.collection('campaigns').doc(campaignId), {
      'terkumpul': FieldValue.increment(nominal),
    });

    await batch.commit();

    await _campaignSvc.checkAndClose(campaignId);
  }

  Future<void> batalkanDonasi(String donationId) async {
    final doc = await _col.doc(donationId).get();
    if (!doc.exists) return;

    final status = doc.data()?['status'] as String?;
    if (status != DonationStatus.pending) {
      throw Exception('Hanya donasi berstatus Pending yang bisa dibatalkan');
    }

    await _col.doc(donationId).delete();
  }
}
