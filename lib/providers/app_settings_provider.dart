import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/features/settings/models/app_terminology.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';
import 'package:pocket_karcha/services/preferences_service.dart';
import 'package:pocket_karcha/providers/session_provider.dart';

class AppSettings {
  const AppSettings({
    this.urdu = false,
    this.terminology = AppTerminology.gotGave,
    this.defaultPeriod = DashboardPeriod.week,
  });

  final bool urdu;
  final AppTerminology terminology;
  final DashboardPeriod defaultPeriod;

  AppSettings copyWith({
    bool? urdu,
    AppTerminology? terminology,
    DashboardPeriod? defaultPeriod,
  }) {
    return AppSettings(
      urdu: urdu ?? this.urdu,
      terminology: terminology ?? this.terminology,
      defaultPeriod: defaultPeriod ?? this.defaultPeriod,
    );
  }

  static AppSettings fromPrefs(PreferencesService prefs) {
    return AppSettings(
      urdu: prefs.localeUrdu,
      terminology: AppTerminology.fromKey(prefs.terminologyKey),
      defaultPeriod: _periodFromKey(prefs.defaultPeriodKey),
    );
  }

  static DashboardPeriod _periodFromKey(String? key) {
    return DashboardPeriod.values.firstWhere(
      (e) => e.name == key,
      orElse: () => DashboardPeriod.week,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return AppSettings.fromPrefs(ref.read(preferencesServiceProvider));
  }

  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  Future<void> setUrdu(bool value) async {
    state = state.copyWith(urdu: value);
    await _prefs.setLocaleUrdu(value);
  }

  Future<void> setTerminology(AppTerminology value) async {
    state = state.copyWith(terminology: value);
    await _prefs.setTerminology(value.storageKey);
  }

  Future<void> setDefaultPeriod(DashboardPeriod value) async {
    state = state.copyWith(defaultPeriod: value);
    await _prefs.setDefaultPeriod(value.name);
    ref.read(dashboardPeriodProvider.notifier).state = value;
  }

  Future<void> setCurrency(String code) async {
    await _prefs.setCurrencyCode(code);
    final session = ref.read(sessionProvider);
    if (session.userId != null) {
      await ref.read(sessionProvider.notifier).updateCurrency(code);
    } else {
      state = state;
    }
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
