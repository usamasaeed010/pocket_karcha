import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_spacing.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/data/models/category_model.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/data/models/expense_suggestion.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/providers/add_expense_form_provider.dart';
import 'package:pocket_karcha/features/expenses/widgets/category_bottom_sheet.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_form_field.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_tabs.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';
import 'package:pocket_karcha/providers/categories_provider.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    super.key,
    this.prefill,
    this.initialType = TransactionType.gave,
    this.personId,
  });

  final ExpenseSuggestion? prefill;
  final TransactionType initialType;
  final String? personId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;

  static final _dateFormat = DateFormat('d-MMM-yyyy');

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _amount = TextEditingController(
      text: p != null ? p.amount.toStringAsFixed(0) : '',
    );
    _note = TextEditingController(text: p?.titleEn ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addExpenseFormProvider.notifier).reset(
            categoryId: p?.categoryId,
            transactionType: widget.initialType,
            personId: widget.personId,
          );
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

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
    final scope = form.transactionType == TransactionType.gave
        ? CategoryScope.gave
        : CategoryScope.got;

    final picked = await showCategoryBottomSheet(
      context,
      ref,
      selectedId: form.categoryId,
      scope: scope,
    );

    if (picked != null) {
      ref.read(addExpenseFormProvider.notifier).setCategory(picked);
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
              subtitle: p.displayPhone.isNotEmpty
                  ? Text(p.displayPhone)
                  : null,
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

  Future<void> _pickFile() async {
    final s = ref.read(appStringsProvider);
    final source = await showAppOptionsBottomSheet<ImageSource>(
      context: context,
      title: s.attachFile,
      subtitle: s.uploadFile,
      options: [
        AppBottomSheetOption(
          value: ImageSource.camera,
          label: s.takePhoto,
          leading: const Icon(Icons.camera_alt_outlined,
              color: AppColors.dashboardGreen),
        ),
        AppBottomSheetOption(
          value: ImageSource.gallery,
          label: s.chooseGallery,
          leading: const Icon(Icons.photo_library_outlined,
              color: AppColors.dashboardGreen),
        ),
      ],
    );
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) {
      ref.read(addExpenseFormProvider.notifier).setReceipt(File(file.path));
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    final s = ref.read(appStringsProvider);
    final formNotifier = ref.read(addExpenseFormProvider.notifier);

    if (amount == null || amount <= 0) {
      context.showErrorSnack(s.invalidAmount);
      return;
    }

    final form = ref.read(addExpenseFormProvider);
    if (form.categoryId.isEmpty) {
      context.showErrorSnack(s.selectCategory);
      return;
    }

    formNotifier.setSaving(true);

    try {
      final expense = ExpenseModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        categoryId: form.categoryId,
        note: _note.text.trim(),
        date: form.date,
        type: form.transactionType.isIncome
            ? ExpenseRecordType.income
            : ExpenseRecordType.expense,
        personId: form.personId,
      );
      await ref.read(expenseActionsProvider).add(
            expense,
            receiptFile: form.receiptFile,
          );
      if (mounted) {
        context.showSuccessSnack(s.snackTransactionAdded);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnack(e.toString());
    } finally {
      formNotifier.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urdu = ref.watch(localeUrduProvider);
    final s = ref.watch(appStringsProvider);
    final form = ref.watch(addExpenseFormProvider);
    final cat = ref.watch(categoryByIdProvider(form.categoryId));
    final categoryLabel = cat.label(urdu);
    final receiptName = form.receiptFile?.path.split('/').last;
    final typeLook = lookFor(form.transactionType, s);

    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: s.addTransaction,
        showBack: true,
      ),
      body: Column(
        children: [
          TransactionTypeTabs(
            selected: form.transactionType,
            strings: s,
            onChanged: (t) {
              ref.read(addExpenseFormProvider.notifier).setTransactionType(t);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TypeContextBanner(look: typeLook, caption: s.recordingLabel(form.transactionType)),
                  const SizedBox(height: AppSpacing.lg),
                  TransactionFormField(
                    label: s.amount,
                    controller: _amount,
                    hint: s.enterAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\d.,]'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 340;
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
                      final categoryField = TransactionPickerField(
                        label: s.category,
                        value: categoryLabel,
                        hint: s.select,
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
                            const SizedBox(height: AppSpacing.lg),
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
                  if (ref.watch(peopleListProvider).isNotEmpty ||
                      form.personId != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TransactionPickerField(
                      label: s.linkedPerson,
                      value: form.personId == null
                          ? null
                          : ref
                                  .watch(personByIdProvider(form.personId!))
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
                  const SizedBox(height: AppSpacing.lg),
                  TransactionPickerField(
                    label: s.attachFile,
                    value: receiptName,
                    hint: s.uploadFile,
                    suffixIcon: const Icon(
                      Icons.attach_file,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                    onTap: _pickFile,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TransactionFormField(
                    label: s.note,
                    controller: _note,
                    hint: s.enterNote,
                    maxLines: 4,
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
                  background: const Color(0xFFE2E8F0),
                  foreground: AppColors.textPrimary,
                  onPressed: form.saving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BottomButton(
                  label: s.save,
                  background: typeLook.color,
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

class _TypeContextBanner extends StatelessWidget {
  const _TypeContextBanner({required this.look, required this.caption});

  final TransactionTypeLook look;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: look.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: look.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: look.color,
              shape: BoxShape.circle,
            ),
            child: Icon(look.icon, color: look.onColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: look.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 48,
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
                : Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
