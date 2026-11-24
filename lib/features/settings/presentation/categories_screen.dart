import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_tabs.dart';
import 'package:pocket_karcha/features/settings/presentation/category_form_screen.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  TransactionType _type = TransactionType.purchase;

  CategoryScope get _scope => _type.categoryScope;

  void _openForm({CategoryModel? category}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryFormScreen(
          scope: _scope,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final urdu = ref.watch(localeUrduProvider);
    final categories = ref.watch(categoriesForScopeProvider(_scope));

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: AppToolbarBar(
          title: s.categories,
          subtitle: s.categoriesDesc,
          showBack: true,
          actions: [
            AppToolbarIconAction(
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TransactionTypeTabs(
            selected: _type,
            strings: s,
            onChanged: (t) => setState(() => _type = t),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: categories.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return AnimatedListItem(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                      color: AppColors.dashboardGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _openForm(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.dashboardGreen
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.dashboardGreen
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.dashboardGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.addCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dashboardGreen,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.dashboardGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                }

                final cat = categories[i - 1];
                return AnimatedListItem(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      onTap: () => _openForm(category: cat),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.color),
                      ),
                      title: Text(
                        cat.label(urdu),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
