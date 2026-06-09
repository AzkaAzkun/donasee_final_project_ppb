import 'dart:io';
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
}
