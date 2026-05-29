import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

Future<String?> showCurrencyBottomSheet(
  BuildContext context, {
  required String selectedCode,
  required bool urdu,
}) {
  final s = AppStrings(urdu);

  return showAppBottomSheet<String>(
    context: context,
    title: s.selectCurrency,
    subtitle: s.selectCurrencyHint,
    maxHeightFraction: 0.55,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: AppCurrencies.all.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 56,
        color: Color(0xFFF1F5F9),
      ),
      itemBuilder: (ctx, index) {
        final c = AppCurrencies.all[index];
        final selected = c.code == selectedCode;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
          title: Text(
            c.name(urdu),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          subtitle: Text('${c.code} · ${c.symbol}'),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppColors.navActive, size: 24)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => Navigator.pop(ctx, c.code),
        );
      },
    ),
  );
}
