import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

Future<String?> showCategoryBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required String selectedId,
  required CategoryScope scope,
}) {
  final s = ref.read(appStringsProvider);
  final urdu = ref.read(localeUrduProvider);
  final categories = scope == CategoryScope.gave
      ? ref.read(gaveCategoriesProvider)
      : ref.read(gotCategoriesProvider);

  return showAppBottomSheet<String>(
    context: context,
    title: s.category,
    maxHeightFraction: 0.6,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 56,
        color: Color(0xFFF1F5F9),
      ),
      itemBuilder: (ctx, index) {
        final cat = categories[index];
        final selected = cat.id == selectedId;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: cat.color.withValues(alpha: 0.15),
            child: Icon(cat.icon, color: cat.color, size: 22),
          ),
          title: Text(
            cat.label(urdu),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppColors.navActive, size: 24)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => Navigator.pop(ctx, cat.id),
        );
      },
    ),
  );
}
