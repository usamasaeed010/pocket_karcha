import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/features/settings/presentation/currency_setting_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/language_setting_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/terminology_setting_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/time_period_setting_screen.dart';
import 'package:pocket_karcha/features/settings/widgets/delete_account_sheet.dart';
import 'package:pocket_karcha/features/settings/widgets/menu_tile.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final currency = AppCurrencies.byCode(currencyCode);

    var index = 0;
    Widget anim(Widget child) =>
        AnimatedListItem(index: index++, child: child);

    return AppPage(
      title: s.settings,
      subtitle: s.settingsDesc,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          anim(MenuTile(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primary,
            title: s.timePeriod,
            subtitle: s.periodLabel(settings.defaultPeriod),
            onTap: () => _push(context, const TimePeriodSettingScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF0D9488),
            title: s.currencySymbol,
            subtitle: '${currency.code} · ${currency.symbol}',
            onTap: () => _push(context, const CurrencySettingScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.swap_horiz_rounded,
            iconColor: const Color(0xFF6366F1),
            title: s.terminology,
            subtitle: settings.terminology.label(settings.urdu),
            onTap: () => _push(context, const TerminologySettingScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF2563EB),
            title: s.language,
            subtitle: settings.urdu ? s.urdu : s.english,
            onTap: () => _push(context, const LanguageSettingScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.expense,
            title: s.deleteAccount,
            subtitle: s.deleteAccountDesc,
            onTap: () => showDeleteAccountSheet(context, ref),
          )),
        ],
      ),
    );
  }
}
