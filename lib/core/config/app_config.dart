import 'package:pocket_karcha/services/firebase_service.dart';

class AppConfig {
  AppConfig._();

  static bool get firebaseEnabled => FirebaseService.isReady;

  static const String appNameEn = 'Pocket Karcha';
  static const String appNameUr = 'پاکٹ خرچہ';
}
