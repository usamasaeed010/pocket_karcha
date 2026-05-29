import 'package:supabase_flutter/supabase_flutter.dart';

class StorageUploadException implements Exception {
  StorageUploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  factory StorageUploadException.fromStorageException(StorageException e) {
    final msg = e.message.toLowerCase();
    final code = e.statusCode ?? '';
    if (code == '404' || msg.contains('bucket not found')) {
      return StorageUploadException(
        'Supabase bucket "pocket-karcha" not found. '
        'Open Supabase Dashboard → SQL Editor and run supabase/setup_storage.sql',
        statusCode: 404,
      );
    }
    if (code == '403' || msg.contains('policy') || msg.contains('denied')) {
      return StorageUploadException(
        'Storage permission denied. Run supabase/setup_storage.sql in Supabase SQL Editor.',
        statusCode: 403,
      );
    }
    return StorageUploadException(e.message);
  }
}
