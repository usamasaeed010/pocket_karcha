import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Image attachments are disabled for now.
// import 'package:image_picker_android/image_picker_android.dart';
// import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:pocket_karcha/app.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/services/preferences_service.dart';
import 'package:pocket_karcha/services/push_service.dart';
import 'package:pocket_karcha/services/supabase_service.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // _enableAndroidPhotoPicker(); // Image attachments are disabled for now.

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };
      // Bundled for PDF reports (SIL Open Font License).
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(
          const ['Noto Naskh Arabic'],
          await rootBundle.loadString('assets/fonts/NotoNaskhArabic-LICENSE.txt'),
        );
      });

      final prefs = await PreferencesService.create();
      await Future.wait([
        FirebaseService.initialize(),
        SupabaseService.initialize(),
      ]);
      // Notification taps (incl. the one that opened the app) → open order.
      await PushService.instance.init().timeout(
            const Duration(seconds: 3),
            onTimeout: () {},
          );

      runApp(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const PocketKarchaApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

// Image attachments are disabled for now.
// /// Gallery picks are one image at a time. Android Photo Picker grants that
// /// single selection without READ_MEDIA_IMAGES. The plugin flag defaults to
// /// false, which falls back to ACTION_GET_CONTENT.
// void _enableAndroidPhotoPicker() {
//   if (defaultTargetPlatform != TargetPlatform.android) return;
//   final picker = ImagePickerPlatform.instance;
//   if (picker is ImagePickerAndroid) {
//     picker.useAndroidPhotoPicker = true;
//   }
// }
