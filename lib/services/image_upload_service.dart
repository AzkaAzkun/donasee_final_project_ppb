import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final _storage = Supabase.instance.client.storage;
  static const _bucket = 'campaign-images';

  /// Upload file gambar ke Supabase Storage.
  /// Mengembalikan public URL gambar.
  Future<String> uploadCampaignImage(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'campaigns/$fileName';

    await _storage.from(_bucket).upload(
          path,
          imageFile,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false,
          ),
        );

    return _storage.from(_bucket).getPublicUrl(path);
  }

  /// Upload file gambar ke Supabase Storage (mendukung Web/bytes).
  Future<String> uploadCampaignImageBytes(Uint8List bytes, String ext) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'campaigns/$fileName';

    await _storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false,
          ),
        );

    return _storage.from(_bucket).getPublicUrl(path);
  }

  /// Hapus gambar lama dari Supabase Storage berdasarkan URL.
  Future<void> deleteByUrl(String url) async {
    try {
      // Ekstrak path dari URL public
      // Format: .../storage/v1/object/public/campaign-images/campaigns/xxx.jpg
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(_bucket);
      if (bucketIdx == -1) return;
      final path = segments.sublist(bucketIdx + 1).join('/');
      await _storage.from(_bucket).remove([path]);
    } catch (_) {
      // Abaikan error saat hapus gambar lama
    }
  }

  /// Upload surat resmi PDF (mendukung bytes untuk web/mobile dan File untuk mobile)
  Future<String> uploadSuratResmi({
    required String uid,
    Uint8List? bytes,
    File? file,
  }) async {
    final path = 'surat-resmi/$uid.pdf';

    if (bytes != null) {
      await _storage.from('surat-resmi').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    } else if (file != null) {
      await _storage.from('surat-resmi').upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
    } else {
      throw Exception('Data file atau bytes tidak boleh kosong');
    }

    // Kembalikan signed URL (berlaku 24 jam)
    return await _storage.from('surat-resmi').createSignedUrl(path, 60 * 60 * 24);
  }

  /// Hapus surat resmi dari Supabase Storage
  Future<void> deleteSuratResmi(String uid) async {
    try {
      await _storage.from('surat-resmi').remove(['surat-resmi/$uid.pdf']);
    } catch (_) {
      // Abaikan error saat hapus
    }
  }

  /// Upload foto profil ke Supabase Storage (bucket: 'user-profiles')
  Future<String> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final fileName = '$uid.$ext';
    final path = 'avatars/$fileName';

    await _storage.from('user-profiles').upload(
          path,
          imageFile,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );

    return _storage.from('user-profiles').getPublicUrl(path);
  }

  /// Hapus foto profil dari Supabase Storage
  Future<void> deleteProfilePicture(String uid, String ext) async {
    try {
      await _storage.from('user-profiles').remove(['avatars/$uid.$ext']);
    } catch (_) {
      // Abaikan error saat hapus
    }
  }

  /// Upload bukti alokasi (bisa gambar atau PDF/dokumen) ke bucket 'bukti-alokasi'
  Future<String> uploadBuktiAlokasi(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'bukti/$fileName';

    String contentType;
    if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'png') {
      contentType = 'image/png';
    } else {
      contentType = 'image/jpeg';
    }

    await _storage.from('bukti-alokasi').upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return _storage.from('bukti-alokasi').getPublicUrl(path);
  }

  /// Upload bukti alokasi (bisa gambar atau PDF/dokumen) ke bucket 'bukti-alokasi' (mendukung Web/bytes)
  Future<String> uploadBuktiAlokasiBytes(Uint8List bytes, String ext) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'bukti/$fileName';

    String contentType;
    if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'png') {
      contentType = 'image/png';
    } else {
      contentType = 'image/jpeg';
    }

    await _storage.from('bukti-alokasi').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return _storage.from('bukti-alokasi').getPublicUrl(path);
  }

  /// Hapus bukti alokasi dari Supabase Storage berdasarkan URL
  Future<void> deleteBuktiAlokasiByUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf('bukti-alokasi');
      if (bucketIdx == -1) return;
      final path = segments.sublist(bucketIdx + 1).join('/');
      await _storage.from('bukti-alokasi').remove([path]);
    } catch (_) {
      // Abaikan error saat hapus
    }
  }
}
