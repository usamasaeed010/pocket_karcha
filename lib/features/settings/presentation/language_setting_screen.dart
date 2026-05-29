import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_option_page.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class LanguageSettingScreen extends ConsumerWidget {
  const LanguageSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);

    return SettingsOptionPage<bool>(
      title: s.selectLanguage,
      subtitle: s.languageDesc,
      options: const [false, true],
      selected: urdu,
      labelOf: (v) => v ? s.urdu : s.english,
      onSelected: (v) => ref.read(appSettingsProvider.notifier).setUrdu(v),
    );
  }
}
