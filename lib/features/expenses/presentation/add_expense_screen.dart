// import 'dart:io'; // Image attachments are disabled for now.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart'; // Image attachments are disabled for now.
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/constants/stock_units.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/data/datasources/shop_item_suggestions.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';
import 'package:pocket_karcha/data/models/product_model.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/providers/add_expense_form_provider.dart';
import 'package:pocket_karcha/features/expenses/widgets/category_bottom_sheet.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_form_field.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_tabs.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/khata/personal_categories.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

/// Add / edit a shop entry — Sale, Purchase (stock) or Expense.
///
/// Sales and purchases can carry item name, quantity, unit and rate; the
/// total is calculated automatically from quantity × rate.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.prefill,
    this.editExpense,
    this.initialType = TransactionType.purchase,
    this.personId,
    this.initialAmount,
  });

  final ExpenseSuggestion? prefill;
  final ExpenseModel? editExpense;
  final TransactionType initialType;
  final String? personId;

  /// Amount to start with, e.g. from the expense calculator.
  final double? initialAmount;

  bool get isEditing => editExpense != null;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _item;
  late final TextEditingController _qty;
  late final TextEditingController _rate;
  final FocusNode _qtyFocus = FocusNode();

  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _numberInput = [
    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
  ];

  @override
  void initState() {
    super.initState();
    final editing = widget.editExpense;
    final p = widget.prefill;
    _amount = TextEditingController(
      text: editing != null
          ? _money(editing.amount)
          : p != null
              ? p.amount.toStringAsFixed(0)
              : widget.initialAmount != null
                  ? _money(widget.initialAmount!)
                  : '',
    );
    _note = TextEditingController(text: editing?.note ?? p?.titleEn ?? '');
    _item = TextEditingController(text: editing?.itemName ?? '');
    _qty = TextEditingController(
      text: editing?.quantity != null
          ? StockUnits.formatQty(editing!.quantity!)
          : '',
    );
    _rate = TextEditingController(
      text: editing?.unitPrice != null ? _money(editing!.unitPrice!) : '',
    );
    _qty.addListener(_recalculateTotal);
    _rate.addListener(_recalculateTotal);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(addExpenseFormProvider.notifier);
      if (editing != null) {
        notifier.loadFromExpense(editing);
      } else {
        notifier.reset(
          categoryId: p?.categoryId,
          transactionType: widget.initialType,
          personId: widget.personId,
        );
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _item.dispose();
    _qty.dispose();
    _rate.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static double? _parse(String text) =>
      double.tryParse(text.replaceAll(',', '').trim());

  /// Money without needless decimals: 1800 → "1800", 12.5 → "12.5".
  static String _money(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    var text = value.toStringAsFixed(2);
    if (text.endsWith('0')) text = text.substring(0, text.length - 1);
    return text;
  }

  double? get _qtyValue {
    final q = _parse(_qty.text);
    return q != null && q > 0 ? q : null;
  }

  double? get _rateValue {
    final r = _parse(_rate.text);
    return r != null && r > 0 ? r : null;
  }

  void _recalculateTotal() {
    final q = _qtyValue;
    final r = _rateValue;
    if (q != null && r != null) {
      final total = _money(q * r);
      if (_amount.text != total) _amount.text = total;
    }
    if (mounted) setState(() {});
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final form = ref.read(addExpenseFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(addExpenseFormProvider.notifier).setDate(picked);
    }
  }

  Future<void> _pickCategory() async {
    final form = ref.read(addExpenseFormProvider);
    final picked = await showCategoryBottomSheet(
      context,
      ref,
      selectedId: form.categoryId,
      scope: form.transactionType.categoryScope,
    );
    if (picked != null) {
      ref.read(addExpenseFormProvider.notifier).setCategory(picked);
    }
  }

  Future<void> _pickUnit() async {
    final s = ref.read(appStringsProvider);
    final urdu = ref.read(localeUrduProvider);
    final current = ref.read(addExpenseFormProvider).unit;
    final picked = await showAppBottomSheet<String>(
      context: context,
      title: s.selectUnit,
      maxHeightFraction: 0.6,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final unit in StockUnits.all)
              ChoiceChip(
                label: Text(unit.name(urdu)),
                selected: unit.key == current,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: unit.key == current
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
                onSelected: (_) => Navigator.pop(context, unit.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(addExpenseFormProvider.notifier).setUnit(picked);
    }
  }

  Future<void> _pickPersonalCategory() async {
    final s = ref.read(appStringsProvider);
    final urdu = ref.read(localeUrduProvider);
    final current = ref.read(addExpenseFormProvider).personalCategoryId;
    final picked = await showAppBottomSheet<String>(
      context: context,
      title: s.category,
      maxHeightFraction: 0.6,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in PersonalCategories.all)
              ChoiceChip(
                avatar: Icon(c.icon, size: 18, color: c.color),
                label: Text(c.label(urdu)),
                selected: c.id == current,
                selectedColor: c.color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: c.id == current ? c.color : AppColors.textPrimary,
                ),
                onSelected: (_) => Navigator.pop(context, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(addExpenseFormProvider.notifier).setPersonalCategory(picked);
    }
  }

  Future<void> _pickPerson() async {
    final s = ref.read(appStringsProvider);
    final people = ref.read(peopleListProvider);
    if (people.isEmpty) return;

    final picked = await showAppBottomSheet<String?>(
      context: context,
      title: s.selectPerson,
      maxHeightFraction: 0.55,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: Text(s.noPerson),
            onTap: () => Navigator.pop(context, ''),
          ),
          for (final p in people)
            ListTile(
              leading: CircleAvatar(
                child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
              ),
              title: Text(p.name),
              subtitle:
                  p.displayPhone.isNotEmpty ? Text(p.displayPhone) : null,
              onTap: () => Navigator.pop(context, p.id),
            ),
        ],
      ),
    );

    if (picked == null) return;
    ref.read(addExpenseFormProvider.notifier).setPerson(
          picked.isEmpty ? null : picked,
        );
  }

  // Image attachments are disabled for now.
  // Future<void> _pickFile() async {
  //   final s = ref.read(appStringsProvider);
  //   final source = await showAppOptionsBottomSheet<ImageSource>(
  //     context: context,
  //     title: s.attachFile,
  //     subtitle: s.uploadFile,
  //     options: [
  //       AppBottomSheetOption(
  //         value: ImageSource.camera,
  //         label: s.takePhoto,
  //         leading: const Icon(Icons.camera_alt_outlined,
  //             color: AppColors.dashboardGreen),
  //       ),
  //       AppBottomSheetOption(
  //         value: ImageSource.gallery,
  //         label: s.chooseGallery,
  //         leading: const Icon(Icons.photo_library_outlined,
  //             color: AppColors.dashboardGreen),
  //       ),
  //     ],
  //   );
  //   if (source == null) return;
  //
  //   final file = await ImagePicker().pickImage(
  //     source: source,
  //     maxWidth: 1600,
  //     imageQuality: 85,
  //   );
  //   if (file != null) {
  //     ref.read(addExpenseFormProvider.notifier).setReceipt(File(file.path));
  //   }
  // }

  /// Menu items as quick picks for a sale — each size is its own pick,
  /// e.g. "Dahi Bhalla (Half)" at the half price.
  static List<ShopItemSuggestion> _menuPicks(List<ProductModel> menu) => [
        for (final p in menu)
          if (p.inStock)
            if (p.hasVariants)
              for (final v in p.variants)
                ShopItemSuggestion(name: '${p.name} (${v.name})', rate: v.price)
            else
              ShopItemSuggestion(name: p.name, rate: p.price),
      ];

  void _applySuggestion(ShopItemSuggestion item) {
    final urdu = ref.read(localeUrduProvider);
    final form = ref.read(addExpenseFormProvider);
    final notifier = ref.read(addExpenseFormProvider.notifier);

    _item.text = item.label(urdu);
    if (item.unit != null) notifier.setUnit(item.unit!);
    final catId = item.categoryId;
    if (catId != null) {
      final cat = ref.read(categoryByIdProvider(catId));
      if (cat.id == catId && cat.scope == form.transactionType.categoryScope) {
        notifier.setCategory(catId);
      }
    }
    if (item.rate != null) _rate.text = _money(item.rate!);
    if (_qtyValue == null) _qty.text = '1';
    _recalculateTotal();

    _qtyFocus.requestFocus();
    _qty.selection = TextSelection(baseOffset: 0, extentOffset: _qty.text.length);
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  void _save() {
    final amount = _parse(_amount.text);
    final s = ref.read(appStringsProvider);

    if (amount == null || amount <= 0) {
      context.showErrorSnack(s.invalidAmount);
      return;
    }

    final form = ref.read(addExpenseFormProvider);
    final personal = form.isPersonal;
    if (!personal && form.categoryId.isEmpty) {
      context.showErrorSnack(s.selectCategory);
      return;
    }

    // Personal expenses go to the personal khata without item details.
    final withItems = form.showItems && !personal;
    final itemName = withItems ? _item.text.trim() : '';
    final qty = withItems ? _qtyValue : null;
    final rate = withItems ? _rateValue : null;

    final editing = widget.editExpense;
    final expense = ExpenseModel(
      id: editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      categoryId: personal ? form.personalCategoryId : form.categoryId,
      note: _note.text.trim(),
      date: form.date,
      createdAt: editing?.createdAt,
      // Image attachments are disabled for now — keep any old receipt URL.
      receiptUrl: editing?.receiptUrl,
      type: personal
          ? ExpenseRecordType.expense
          : form.transactionType.recordType,
      personId: personal ? null : (widget.personId ?? form.personId),
      itemName: itemName.isEmpty ? null : itemName,
      quantity: qty,
      unit: qty != null ? form.unit : null,
      unitPrice: rate,
      book: personal ? EntryBook.personal : EntryBook.shop,
      status: form.mode == RecordMode.pending
          ? EntryStatus.pending
          : EntryStatus.paid,
    );

    final actions = ref.read(expenseActionsProvider);
    // Firestore shows the entry on the phone at once (even offline) and
    // syncs it later, so the screen closes without waiting for the server.
    unawaited(
      (widget.isEditing ? actions.update(expense) : actions.add(expense))
          .catchError((Object e) {
        showRootSnack(message: e.toString(), type: AppSnackType.error);
      }),
    );
    context.showSuccessSnack(
      widget.isEditing ? s.snackTransactionUpdated : s.snackTransactionAdded,
    );
    Navigator.of(context).pop();
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final urdu = ref.watch(localeUrduProvider);
    final s = ref.watch(appStringsProvider);
    final ss = ref.watch(storeStringsProvider);
    final form = ref.watch(addExpenseFormProvider);
    final type = form.transactionType;
    final look = lookFor(type, s);
    final cat = ref.watch(categoryByIdProvider(form.categoryId));
    final personal = form.isPersonal;
    final personalCat = PersonalCategories.byId(form.personalCategoryId);
    final modeHint = switch (form.mode) {
      RecordMode.paid => type.isIncome ? ss.hintPaidIn : ss.hintPaidOut,
      RecordMode.pending =>
        type.isIncome ? ss.hintPendingIn : ss.hintPendingOut,
      RecordMode.personal => ss.hintPersonal,
    };
    final currencyCode = ref.watch(selectedCurrencyProvider);
    final currency = AppCurrencies.byCode(currencyCode);
    final unit = StockUnits.byKey(form.unit);
    final suggestions = form.showItems
        ? ref.watch(itemSuggestionsProvider(type))
        : const <ShopItemSuggestion>[];
    final menuPicks = form.showItems && type == TransactionType.got
        ? _menuPicks(ref.watch(productListProvider))
        : const <ShopItemSuggestion>[];
    // Image attachments are disabled for now.
    // final receiptName = form.receiptFile?.path.split('/').last ??
    //     (form.existingReceiptUrl != null ? s.receiptAttached : null);

    final q = _qtyValue;
    final r = _rateValue;
    final formula = form.showItems && q != null && r != null
        ? '${StockUnits.formatQty(q)} ${unit.short(urdu)} × '
            '${CurrencyFormatter.format(r, currencyCode: currencyCode)}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: widget.isEditing ? s.editTransaction : s.addTransaction,
        showBack: true,
      ),
      body: Column(
        children: [
          TransactionTypeTabs(
            selected: type,
            strings: s,
            onChanged: (t) =>
                ref.read(addExpenseFormProvider.notifier).setTransactionType(t),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountCard(
                    look: look,
                    caption: s.recordingLabel(type),
                    label: s.totalAmount,
                    controller: _amount,
                    currencySymbol: currency.symbol,
                    formula: formula,
                    formulaHint: s.autoCalculated,
                    inputFormatters: _numberInput,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: ss.recordStatus,
                    icon: Icons.payments_outlined,
                    color: look.color,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatusChoice(
                                label: ss.statusPaid,
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.brand,
                                selected: form.mode == RecordMode.paid,
                                onTap: () => ref
                                    .read(addExpenseFormProvider.notifier)
                                    .setMode(RecordMode.paid),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatusChoice(
                                label: ss.statusPending,
                                icon: Icons.schedule_rounded,
                                color: pendingColor,
                                selected: form.mode == RecordMode.pending,
                                onTap: () => ref
                                    .read(addExpenseFormProvider.notifier)
                                    .setMode(RecordMode.pending),
                              ),
                            ),
                            if (!type.isIncome) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: StatusChoice(
                                  label: ss.statusPersonal,
                                  icon: Icons.person_outline_rounded,
                                  color: AppColors.dispatched,
                                  selected: personal,
                                  onTap: () => ref
                                      .read(addExpenseFormProvider.notifier)
                                      .setMode(RecordMode.personal),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          modeHint,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (personal)
                    const SizedBox.shrink()
                  else if (form.showItems)
                    _SectionCard(
                      title: s.itemDetails,
                      icon: Icons.inventory_2_outlined,
                      color: look.color,
                      trailing: type.showsItemsByDefault
                          ? null
                          : IconButton(
                              tooltip: s.cancel,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => ref
                                  .read(addExpenseFormProvider.notifier)
                                  .setShowItems(false),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (menuPicks.isNotEmpty) ...[
                            Text(
                              ss.fromYourMenu,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 54,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: menuPicks.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => _ItemChip(
                                  item: menuPicks[i],
                                  urdu: urdu,
                                  color: look.color,
                                  currencyCode: currencyCode,
                                  onTap: () => _applySuggestion(menuPicks[i]),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (suggestions.isNotEmpty) ...[
                            Text(
                              s.recentItems,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 54,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: suggestions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => _ItemChip(
                                  item: suggestions[i],
                                  urdu: urdu,
                                  color: look.color,
                                  currencyCode: currencyCode,
                                  onTap: () => _applySuggestion(suggestions[i]),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          TransactionFormField(
                            label: s.itemName,
                            controller: _item,
                            hint: type == TransactionType.got
                                ? s.saleItemNameHint
                                : s.itemNameHint,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TransactionFormField(
                                  label: s.quantity,
                                  controller: _qty,
                                  focusNode: _qtyFocus,
                                  hint: '0',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: _numberInput,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TransactionPickerField(
                                  label: s.unit,
                                  value: unit.name(urdu),
                                  hint: s.selectUnit,
                                  suffixIcon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  onTap: _pickUnit,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TransactionFormField(
                            label: s.ratePer(unit.short(urdu)),
                            controller: _rate,
                            hint: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: _numberInput,
                            prefixText: '${currency.symbol} ',
                          ),
                        ],
                      ),
                    )
                  else
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => ref
                            .read(addExpenseFormProvider.notifier)
                            .setShowItems(true),
                        icon: Icon(Icons.add_circle_outline, color: look.color),
                        label: Text(
                          '${s.addQtyRate} (${s.optional})',
                          style: TextStyle(
                            color: look.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 320;
                            final dateField = TransactionPickerField(
                              label: s.date,
                              value: _dateFormat.format(form.date),
                              hint: s.date,
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onTap: _pickDate,
                            );
                            final categoryField = personal
                                ? TransactionPickerField(
                                    label: s.category,
                                    value: personalCat.label(urdu),
                                    hint: s.select,
                                    leading: Icon(
                                      personalCat.icon,
                                      color: personalCat.color,
                                      size: 20,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onTap: _pickPersonalCategory,
                                  )
                                : TransactionPickerField(
                                    label: s.category,
                                    value: cat.label(urdu),
                                    hint: s.select,
                                    leading: Icon(
                                      cat.icon,
                                      color: cat.color,
                                      size: 20,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onTap: _pickCategory,
                                  );
                            if (narrow) {
                              return Column(
                                children: [
                                  dateField,
                                  const SizedBox(height: AppSpacing.md),
                                  categoryField,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: dateField),
                                const SizedBox(width: 12),
                                Expanded(child: categoryField),
                              ],
                            );
                          },
                        ),
                        if (!personal &&
                            (ref.watch(peopleListProvider).isNotEmpty ||
                                form.personId != null)) ...[
                          const SizedBox(height: AppSpacing.md),
                          TransactionPickerField(
                            label: s.linkedPerson,
                            value: form.personId == null
                                ? null
                                : ref
                                        .watch(
                                          personByIdProvider(form.personId!),
                                        )
                                        ?.name ??
                                    s.selectPerson,
                            hint: s.selectPerson,
                            suffixIcon: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onTap: widget.personId == null ? _pickPerson : () {},
                          ),
                        ],
                        // Image attachments are disabled for now.
                        // const SizedBox(height: AppSpacing.lg),
                        // TransactionPickerField(
                        //   label: s.attachFile,
                        //   value: receiptName,
                        //   hint: s.uploadFile,
                        //   suffixIcon: const Icon(
                        //     Icons.attach_file,
                        //     size: 22,
                        //     color: AppColors.textSecondary,
                        //   ),
                        //   onTap: _pickFile,
                        // ),
                        const SizedBox(height: AppSpacing.md),
                        TransactionFormField(
                          label: s.note,
                          controller: _note,
                          hint: s.enterNote,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: _BottomButton(
                  label: s.cancel,
                  colors: const [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
                  foreground: AppColors.textPrimary,
                  onPressed:
                      form.saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _BottomButton(
                  label: s.save,
                  icon: Icons.check_rounded,
                  colors: look.gradient,
                  foreground: Colors.white,
                  loading: form.saving,
                  onPressed: form.saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big amount input at the top of the form.
class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.look,
    required this.caption,
    required this.label,
    required this.controller,
    required this.currencySymbol,
    required this.formulaHint,
    required this.inputFormatters,
    this.formula,
  });

  final TransactionTypeLook look;
  final String caption;
  final String label;
  final TextEditingController controller;
  final String currencySymbol;
  final String? formula;
  final String formulaHint;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: look.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: look.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: look.gradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(look.icon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    caption,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: look.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: look.color.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: inputFormatters,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: look.color,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFCBD5E1),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ),
                if (formula != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        size: 16,
                        color: look.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$formula  ·  $formulaHint',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.title,
    this.icon,
    this.color,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// One-tap recent / starter item with its last rate.
class _ItemChip extends StatelessWidget {
  const _ItemChip({
    required this.item,
    required this.urdu,
    required this.color,
    required this.currencyCode,
    required this.onTap,
  });

  final ShopItemSuggestion item;
  final bool urdu;
  final Color color;
  final String currencyCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unit = item.unit != null ? StockUnits.byKey(item.unit) : null;
    final detail = item.rate != null
        ? '${CurrencyFormatter.format(item.rate!, currencyCode: currencyCode)}'
            '${unit != null ? ' / ${unit.short(urdu)}' : ''}'
        : unit?.name(urdu);

    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label(urdu),
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              if (detail != null)
                Text(
                  detail,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.colors,
    required this.foreground,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final List<Color> colors;
  final Color foreground;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: foreground,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: foreground, size: 20),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
