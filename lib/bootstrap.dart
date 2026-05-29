import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/app.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/firebase_service.dart';
import 'package:pocket_karcha/services/preferences_service.dart';
import 'package:pocket_karcha/services/supabase_service.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      final prefs = await PreferencesService.create();
      await Future.wait([
        FirebaseService.initialize(),
        SupabaseService.initialize(),
      ]);

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
