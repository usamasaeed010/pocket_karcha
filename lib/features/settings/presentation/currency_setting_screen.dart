import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/features/settings/widgets/settings_option_page.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class CurrencySettingScreen extends ConsumerWidget {
  const CurrencySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);
    final current = ref.watch(selectedCurrencyProvider);

    return SettingsOptionPage<String>(
      title: s.currencySymbol,
      subtitle: s.selectCurrencyHint,
      options: AppCurrencies.all.map((c) => c.code).toList(),
      selected: current,
      labelOf: (code) {
        final c = AppCurrencies.byCode(code);
        return '${c.flag} ${c.code} · ${c.symbol} — ${c.name(urdu)}';
      },
      onSelected: (v) => ref.read(appSettingsProvider.notifier).setCurrency(v),
    );
  }
}
