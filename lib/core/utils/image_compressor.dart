import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

enum ImageCompressPreset { avatar, receipt }

abstract final class ImageCompressor {
  static Future<File> compress(
    File file, {
    required ImageCompressPreset preset,
  }) async {
    if (kIsWeb) return file;

    final settings = switch (preset) {
      ImageCompressPreset.avatar => (maxSide: 512, quality: 78),
      ImageCompressPreset.receipt => (maxSide: 1200, quality: 75),
    };

    final dir = Directory.systemTemp;
    final targetPath = p.join(
      dir.path,
      'pk_${preset.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: settings.quality,
      minWidth: settings.maxSide,
      minHeight: settings.maxSide,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    return result != null ? File(result.path) : file;
  }
}
