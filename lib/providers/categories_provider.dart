import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/category_icons.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/data/repositories/categories_repository.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/providers/preferences_provider.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(preferencesServiceProvider));
});

final categoriesRefreshProvider = StateProvider<int>((ref) => 0);

final allCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  ref.watch(categoriesRefreshProvider);
  return ref.watch(categoriesRepositoryProvider).loadAll();
});

final gaveCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  ref.watch(categoriesRefreshProvider);
  return ref.watch(categoriesRepositoryProvider).forScope(CategoryScope.gave);
});

final gotCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  ref.watch(categoriesRefreshProvider);
  return ref.watch(categoriesRepositoryProvider).forScope(CategoryScope.got);
});

final categoryByIdProvider = Provider.family<CategoryModel, String>((ref, id) {
  ref.watch(categoriesRefreshProvider);
  return ref.watch(categoriesRepositoryProvider).byId(id);
});

final defaultCategoryIdProvider =
    Provider.family<String?, TransactionType>((ref, type) {
  ref.watch(categoriesRefreshProvider);
  final repo = ref.watch(categoriesRepositoryProvider);
  final scope = type == TransactionType.got ? CategoryScope.got : CategoryScope.gave;
  return repo.firstIdForScope(scope);
});

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});

class CategoryActions {
  CategoryActions(this._ref);
  final Ref _ref;

  Future<CategoryModel> save({
    String? id,
    required String name,
    required CategoryScope scope,
    required int iconCodePoint,
    int? colorValue,
  }) async {
    final repo = _ref.read(categoriesRepositoryProvider);
    if (id != null) {
      final existing = repo.byId(id);
      final updated = existing.copyWith(
        labelEn: name,
        labelUr: name,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue ?? CategoryIcons.colorForIcon(iconCodePoint),
        isCustom: true,
      );
      await repo.save(updated);
      _ref.read(categoriesRefreshProvider.notifier).state++;
      return updated;
    }
    final created = await repo.create(
      labelEn: name,
      labelUr: name,
      scope: scope,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
    );
    _ref.read(categoriesRefreshProvider.notifier).state++;
    return created;
  }
}

/// Bridge for legacy PkCategories.byId usage.
CategoryModel resolveCategory(WidgetRef ref, String id) {
  return ref.read(categoryByIdProvider(id));
}
