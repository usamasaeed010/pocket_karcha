import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/navigation/app_navigator.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';

/// Decides where a signed-in owner goes: their store, or store setup.
abstract final class StoreGate {
  /// `true` = has a store, `false` = no store yet, `null` = could not tell
  /// (offline, timeout). Callers treat `null` as "go home" so an owner who
  /// has a store is never sent back into setup by a network blip — home
  /// shows a "create store" button if the store really is missing.
  static Future<bool?> hasStore(WidgetRef ref, String uid) async {
    final prefs = ref.read(preferencesServiceProvider);
    if (prefs.storeReady(uid)) return true;
    final repo = ref.read(storeRepositoryProvider);
    if (repo == null) return null;
    try {
      final store =
          await repo.fetchStore(uid).timeout(const Duration(seconds: 8));
      if (store == null) return false;
      await prefs.setStoreReady(uid, true);
      return true;
    } catch (e) {
      debugPrint('StoreGate: $e');
      return null;
    }
  }

  static Future<void> go(BuildContext context, WidgetRef ref, String uid) async {
    final has = await hasStore(ref, uid);
    if (!context.mounted) return;
    if (has == false) {
      AppNavigator.toStoreSetup(context);
    } else {
      AppNavigator.toHome(context);
    }
  }
}
