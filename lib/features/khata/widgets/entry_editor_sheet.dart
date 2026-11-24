import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/money.dart';
import 'package:pocket_karcha/core/utils/time_ago.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/calculator/calc_engine.dart';
import 'package:pocket_karcha/features/calculator/widgets/calculator_sheet.dart';
import 'package:pocket_karcha/features/khata/entry_status.dart';
import 'package:pocket_karcha/features/khata/personal_categories.dart';
import 'package:pocket_karcha/providers/expense_provider.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Category id saved on lena-dena entries.
const ledgerCategoryId = 'lena_dena';

/// Add or edit a personal expense ([EntryBook.personal]) or a lena-dena
/// entry with one person ([EntryBook.people]).
Future<void> showEntryEditor(
  BuildContext context, {
  required EntryBook book,
  ExpenseModel? existing,
  String? personId,
  String personName = '',
  bool gave = true,
  double? amount,
}) {
  return showCreamSheet<void>(
    context,
    builder: (_) => _EntryEditor(
      book: existing?.book ?? book,
      existing: existing,
      personId: existing?.personId ?? personId,
      personName: personName,
      gave: existing != null ? !existing.isIncome : gave,
      amount: amount,
    ),
  );
}

class _EntryEditor extends ConsumerStatefulWidget {
  const _EntryEditor({
    required this.book,
    required this.existing,
    required this.personId,
    required this.personName,
    required this.gave,
    required this.amount,
  });

  final EntryBook book;
  final ExpenseModel? existing;
  final String? personId;
  final String personName;
  final bool gave;
  final double? amount;

  @override
  ConsumerState<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<_EntryEditor> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _category;
  late bool _gave;
  late bool _pending;
  late DateTime _date;
  String? _error;

  bool get _isPersonal => widget.book == EntryBook.personal;
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final start = e?.amount ?? widget.amount;
    _amount = TextEditingController(
      text: start == null ? '' : formatPlainNumber(start),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.categoryId ?? PersonalCategories.all.first.id;
    _gave = widget.gave;
    _pending = e?.isPending ?? false;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _openCalculator() async {
    final value = await showCalculatorSheet(
      context,
      initial: parseAmount(_amount.text),
    );
    if (value == null || !mounted) return;
    setState(() {
      _amount.text = formatPlainNumber(value);
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  void _failed() {
    showRootSnack(
      message: ref.read(storeStringsProvider).somethingWrong,
      type: AppSnackType.error,
    );
  }

  void _save() {
    final ss = ref.read(storeStringsProvider);
    final value = parseAmount(_amount.text);
    if (value == null || value <= 0) {
      setState(() => _error = ss.enterAmount);
      return;
    }
    final e = widget.existing;
    final now = DateTime.now();
    final entry = ExpenseModel(
      id: e?.id ?? now.millisecondsSinceEpoch.toString(),
      amount: CalcEngine.roundMoney(value),
      categoryId: _isPersonal ? _category : (e?.categoryId ?? ledgerCategoryId),
      note: _note.text.trim(),
      date: _date,
      createdAt: e?.createdAt ?? now,
      type: _isPersonal || _gave
          ? ExpenseRecordType.expense
          : ExpenseRecordType.income,
      personId: _isPersonal ? null : widget.personId,
      book: widget.book,
      status: _isPersonal
          ? (_pending ? EntryStatus.pending : EntryStatus.paid)
          : e?.status,
    );
    final actions = ref.read(expenseActionsProvider);
    // Firestore shows the change on the phone at once (even offline), so the
    // sheet closes without waiting for the server.
    unawaited(
      (e == null ? actions.add(entry) : actions.update(entry))
          .catchError((Object _) => _failed()),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ss = ref.read(storeStringsProvider);
    final ok = await confirmAction(
      context,
      title: ss.deleteEntryTitle,
      body: ss.deleteEntryBody,
      confirmLabel: ss.delete,
      cancelLabel: ss.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    unawaited(
      ref
          .read(expenseActionsProvider)
          .delete(widget.existing!.id)
          .catchError((Object _) => _failed()),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final urdu = ss.isUrdu;
    final title = _isPersonal
        ? (_editing ? ss.editEntry : ss.personalExpense)
        : (_gave
            ? ss.youGaveTo(widget.personName)
            : ss.youGotFrom(widget.personName));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppFonts.display(size: 20)),
          const SizedBox(height: 14),
          if (!_isPersonal) ...[
            Row(
              children: [
                Expanded(
                  child: _SideButton(
                    label: ss.youGave,
                    icon: Icons.north_east_rounded,
                    selected: _gave,
                    color: AppColors.danger,
                    soft: AppColors.dangerSoft,
                    onTap: () => setState(() => _gave = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SideButton(
                    label: ss.youGot,
                    icon: Icons.south_west_rounded,
                    selected: !_gave,
                    color: AppColors.brand,
                    soft: AppColors.brandSoft,
                    onTap: () => setState(() => _gave = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          FieldLabel(ss.entryAmount),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: MoneyInput(
                  controller: _amount,
                  symbol: symbol,
                  autofocus: !_editing && widget.amount == null,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: ss.calculator,
                onPressed: _openCalculator,
                icon: const Icon(Icons.calculate_outlined),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
              ),
            ),
          if (_isPersonal) ...[
            const SizedBox(height: 14),
            FieldLabel(ss.entryCategory),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in PersonalCategories.all)
                  _CategoryChip(
                    category: c,
                    urdu: urdu,
                    selected: c.id == _category,
                    onTap: () => setState(() => _category = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FieldLabel(ss.recordStatus),
            const SizedBox(height: 8),
            PaidPendingToggle(
              pending: _pending,
              paidLabel: ss.statusPaid,
              pendingLabel: ss.statusPending,
              onChanged: (v) => setState(() => _pending = v),
            ),
            if (_pending)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  ss.hintPendingPersonal,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 12.5,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 14),
          FieldLabel(ss.entryNote),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _isPersonal ? ss.notePersonalHint : ss.noteLedgerHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 18,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                ss.entryDate,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
              const Spacer(),
              TextButton(
                onPressed: _pickDate,
                child: Text(TimeAgo.dayLabel(_date, urdu: urdu)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_editing) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(ss.delete),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  style: !_isPersonal && _gave
                      ? FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        )
                      : null,
                  child: Text(ss.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? soft : AppColors.creamCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.creamBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.inkSoft),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.urdu,
    required this.selected,
    required this.onTap,
  });

  final PersonalCategory category;
  final bool urdu;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.12)
              : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? category.color : AppColors.creamBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16, color: category.color),
            const SizedBox(width: 6),
            Text(
              category.label(urdu),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
