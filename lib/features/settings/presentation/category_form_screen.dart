import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/constants/category_icons.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_button.dart';
import 'package:pocket_karcha/shared/widgets/app_text_field.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({
    super.key,
    required this.scope,
    this.category,
  });

  final CategoryScope scope;
  final CategoryModel? category;

  bool get isEditing => category != null;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  late final TextEditingController _name;
  late int _selectedIcon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.labelEn ?? '');
    _selectedIcon = widget.category?.iconCodePoint ??
        CategoryIcons.pickable.first.codePoint;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(appStringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.showErrorSnack(s.snackEnterCategoryName);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(categoryActionsProvider).save(
            id: widget.category?.id,
            name: name,
            scope: widget.scope,
            iconCodePoint: _selectedIcon,
          );
      if (mounted) {
        context.showSuccessSnack(s.snackCategorySaved);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) context.showErrorSnack(s.snackSomethingWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedColor = Color(CategoryIcons.colorForIcon(_selectedIcon));

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: widget.isEditing ? s.editCategory : s.addCategory,
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: selectedColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
                color: selectedColor,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _name,
            label: s.categoryName,
            hint: s.categoryName,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.selectIcon,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: CategoryIcons.pickable.length,
            itemBuilder: (ctx, i) {
              final icon = CategoryIcons.pickable[i];
              final selected = icon.codePoint == _selectedIcon;
              final color = CategoryIcons.colors[i % CategoryIcons.colors.length];
              return Material(
                color: selected
                    ? color.withValues(alpha: 0.18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _selectedIcon = icon.codePoint),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE2E8F0),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: widget.isEditing ? s.save : s.addCategory,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
