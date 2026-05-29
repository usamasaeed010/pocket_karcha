import 'dart:io';

import 'package:pocket_karcha/core/constants/supabase_config.dart';
import 'package:pocket_karcha/core/errors/storage_upload_exception.dart';
import 'package:pocket_karcha/core/utils/image_compressor.dart';
import 'package:pocket_karcha/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  StorageFileApi get _bucket =>
      _client.storage.from(SupabaseConfig.mediaBucket);

  Future<String> uploadReceipt({
    required String uid,
    required String expenseId,
    required File file,
  }) async {
    final compressed = await ImageCompressor.compress(
      file,
      preset: ImageCompressPreset.receipt,
    );
    final path = 'receipts/$uid/$expenseId.jpg';
    await _uploadJpeg(path, compressed);
    return _bucket.getPublicUrl(path);
  }

  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final compressed = await ImageCompressor.compress(
      file,
      preset: ImageCompressPreset.avatar,
    );
    final path = 'avatars/$uid/profile.jpg';
    await _uploadJpeg(path, compressed);
    return _bucket.getPublicUrl(path);
  }

  Future<void> _uploadJpeg(String path, File file) async {
    try {
      await _bucket.upload(
        path,
        file,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
    } on StorageException catch (e) {
      throw StorageUploadException.fromStorageException(e);
    }
  }

  static StorageService? create() {
    if (!SupabaseService.isReady) return null;
    return StorageService(SupabaseService.client);
  }
}
