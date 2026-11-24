import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

/// Human message for a Firestore / network failure.
String friendlyError(Object error, StoreStrings ss) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return ss.noAccess;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return ss.checkInternet;
    }
  }
  if (error is TimeoutException) return ss.checkInternet;
  return ss.somethingWrong;
}

/// Fire-and-forget write: Firestore's local cache updates the UI at once
/// (works offline); if the server later rejects it, a snack explains why.
void backgroundWrite(Future<void> write, StoreStrings ss) {
  write.catchError((Object e, StackTrace st) {
    debugPrint('Background write failed: $e');
    showRootSnack(message: friendlyError(e, ss), type: AppSnackType.error);
  });
}
