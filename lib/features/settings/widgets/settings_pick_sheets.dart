import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/settings/models/app_terminology.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

Future<T?> showSettingsRadioSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppBottomSheetOption<T>> options,
}) {
  return showAppBottomSheet<T>(
    context: context,
    title: title,
    maxHeightFraction: 0.5,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (ctx, i) {
        final opt = options[i];
        return Material(
          color: opt.selected
              ? const Color(0xFFF1F5F9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              opt.label,
              style: TextStyle(
                fontWeight:
                    opt.selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: Icon(
              opt.selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: opt.selected
                  ? AppColors.navActive
                  : AppColors.textSecondary,
            ),
            onTap: () => Navigator.pop(ctx, opt.value),
          ),
        );
      },
    ),
  );
}

Future<DashboardPeriod?> pickDefaultPeriod(
  BuildContext context,
  AppStrings s,
  DashboardPeriod current,
) {
  return showSettingsRadioSheet<DashboardPeriod>(
    context: context,
    title: s.timePeriod,
    options: DashboardPeriod.values
        .map(
          (p) => AppBottomSheetOption(
            value: p,
            label: s.periodLabel(p),
            selected: p == current,
          ),
        )
        .toList(),
  );
}

Future<String?> pickCurrency(
  BuildContext context,
  AppStrings s,
  String current,
  bool urdu,
) {
  return showAppBottomSheet<String>(
    context: context,
    title: s.currencySymbol,
    subtitle: s.selectCurrencyHint,
    maxHeightFraction: 0.55,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: AppCurrencies.all.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (ctx, i) {
        final c = AppCurrencies.all[i];
        final selected = c.code == current;
        return ListTile(
          leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
          title: Text('${c.code} - ${c.symbol}'),
          subtitle: Text(c.name(urdu)),
          trailing: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.navActive : AppColors.textSecondary,
          ),
          onTap: () => Navigator.pop(ctx, c.code),
        );
      },
    ),
  );
}

Future<AppTerminology?> pickTerminology(
  BuildContext context,
  AppStrings s,
  AppTerminology current,
) {
  return showSettingsRadioSheet<AppTerminology>(
    context: context,
    title: s.terminology,
    options: AppTerminology.values
        .map(
          (t) => AppBottomSheetOption(
            value: t,
            label: t.label(s.isUrdu),
            selected: t == current,
          ),
        )
        .toList(),
  );
}

Future<bool?> pickLanguage(
  BuildContext context,
  AppStrings s,
  bool urdu,
) {
  return showSettingsRadioSheet<bool>(
    context: context,
    title: s.selectLanguage,
    options: [
      AppBottomSheetOption(
        value: false,
        label: s.english,
        selected: !urdu,
      ),
      AppBottomSheetOption(
        value: true,
        label: s.urdu,
        selected: urdu,
      ),
    ],
  );
}
