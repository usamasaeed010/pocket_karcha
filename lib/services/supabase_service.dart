import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocket_karcha/core/constants/supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (_ready) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _ready = true;
  }
}
