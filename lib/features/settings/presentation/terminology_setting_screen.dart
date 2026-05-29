import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/features/settings/models/app_terminology.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_option_page.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class TerminologySettingScreen extends ConsumerWidget {
  const TerminologySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);

    return SettingsOptionPage<AppTerminology>(
      title: s.terminology,
      subtitle: s.terminologyDesc,
      options: AppTerminology.values,
      selected: settings.terminology,
      labelOf: (t) => t.label(settings.urdu),
      onSelected: (v) =>
          ref.read(appSettingsProvider.notifier).setTerminology(v),
    );
  }
}
