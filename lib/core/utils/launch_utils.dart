import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp, phone, browser, share sheet and clipboard helpers.
abstract final class LaunchUtils {
  /// Phone as typed by a customer → international digits for WhatsApp.
  /// "0300 1234567" + "+92" → "923001234567".
  static String toWhatsAppDigits(String raw, {required String dialCode}) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final dial = dialCode.replaceAll(RegExp(r'\D'), '');
    if (raw.trim().startsWith('+')) return digits;
    if (digits.startsWith('00')) return digits.substring(2);
    if (dial.isNotEmpty && digits.startsWith(dial) && digits.length > 10) {
      return digits;
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '$dial$digits';
  }

  /// Opens WhatsApp with [text]. Empty [phoneDigits] lets the user pick a chat.
  ///
  /// Uses api.whatsapp.com, not wa.me: the wa.me redirect turns emoji into
  /// "�" when it goes through a browser. Spaces go as %20 (the form WhatsApp
  /// documents), not the "+" that Uri.https writes.
  static Future<bool> openWhatsApp({
    String phoneDigits = '',
    required String text,
  }) {
    final phone = phoneDigits.isEmpty ? '' : 'phone=$phoneDigits&';
    final uri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send',
      query: '${phone}text=${Uri.encodeComponent(text)}',
    );
    return _launch(uri);
  }

  static Future<bool> call(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return _launch(Uri(scheme: 'tel', path: cleaned));
  }

  static Future<bool> openUrl(String url) => _launch(Uri.parse(url));

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('LaunchUtils: could not open $uri — $e');
      return false;
    }
  }

  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  /// Writes [bytes] to a temp file and opens the share sheet.
  static Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        text: text,
      ),
    );
  }

  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
