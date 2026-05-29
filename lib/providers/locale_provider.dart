import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';

/// Urdu when true — synced with persisted [appSettingsProvider].
final localeUrduProvider = Provider<bool>(
  (ref) => ref.watch(appSettingsProvider).urdu,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return AppStrings(settings.urdu, terminologyMode: settings.terminology);
});
