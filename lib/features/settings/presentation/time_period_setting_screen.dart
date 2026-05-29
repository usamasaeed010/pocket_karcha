import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_option_page.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class TimePeriodSettingScreen extends ConsumerWidget {
  const TimePeriodSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final current = ref.watch(appSettingsProvider).defaultPeriod;

    return SettingsOptionPage<DashboardPeriod>(
      title: s.timePeriod,
      subtitle: s.timePeriodDesc,
      options: DashboardPeriod.values,
      selected: current,
      labelOf: s.periodLabel,
      onSelected: (v) =>
          ref.read(appSettingsProvider.notifier).setDefaultPeriod(v),
    );
  }
}
