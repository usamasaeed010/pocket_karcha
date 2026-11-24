import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/core/utils/launch_utils.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';
import 'package:pocket_karcha/features/calculator/calc_engine.dart';
import 'package:pocket_karcha/features/calculator/widgets/calc_keypad.dart';
import 'package:pocket_karcha/features/calculators/presentation/business_calculators_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/investment_calculators_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/loan_calculators_screen.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/presentation/add_expense_screen.dart';
import 'package:pocket_karcha/features/khata/widgets/entry_editor_sheet.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// One line kept on the tape when = is pressed.
class _TapeLine {
  const _TapeLine(this.expression, this.result);

  final String expression;
  final double result;
}

/// Expense calculator: add up bills and items, keep a tape, split the total
/// between people, share it, or write it straight into the khata.
class ExpenseCalculatorScreen extends ConsumerStatefulWidget {
  const ExpenseCalculatorScreen({super.key});

  @override
  ConsumerState<ExpenseCalculatorScreen> createState() =>
      _ExpenseCalculatorScreenState();
}

class _ExpenseCalculatorScreenState
    extends ConsumerState<ExpenseCalculatorScreen> {
  final _input = CalcInput();
  final _tape = <_TapeLine>[];

  double? get _value {
    final r = _input.result;
    return r == null ? null : CalcEngine.roundMoney(r);
  }

  bool get _hasAmount => (_value ?? 0) > 0;

  void _press(String key) {
    if (key == CalcKeypad.equals) {
      final r = _value;
      if (r == null) return;
      setState(() {
        if (_input.hasOperation) _tape.add(_TapeLine(_input.text, r));
        _input.setValue(r);
      });
      return;
    }
    setState(() => _input.press(key));
  }

  void _reuse(_TapeLine line) {
    setState(() => _input.setValue(line.result));
  }

  void _share() {
    final money = ref.read(moneyProvider);
    final v = _value;
    if (v == null) return;
    final text = _input.hasOperation
        ? '${_input.text} = ${money(v)}'
        : money(v);
    LaunchUtils.shareText(text);
  }

  void _split() {
    final v = _value;
    if (v == null || v <= 0) return;
    showCreamSheet<void>(context, builder: (_) => _SplitSheet(total: v));
  }

  void _save() {
    final v = _value;
    if (v == null || v <= 0) return;
    final ss = ref.read(storeStringsProvider);
    showCreamSheet<void>(
      context,
      title: ss.saveWhere,
      builder: (sheetContext) {
        void pick(VoidCallback open) {
          Navigator.of(sheetContext).pop();
          open();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SaveOption(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.brand,
                label: ss.asPersonal,
                onTap: () => pick(
                  () => showEntryEditor(
                    context,
                    book: EntryBook.personal,
                    amount: v,
                  ),
                ),
              ),
              _SaveOption(
                icon: Icons.north_east_rounded,
                color: AppColors.expense,
                label: ss.asShopExpense,
                onTap: () => pick(() => _openShopEntry(TransactionType.gave, v)),
              ),
              _SaveOption(
                icon: Icons.inventory_2_outlined,
                color: AppColors.purchase,
                label: ss.asShopPurchase,
                onTap: () =>
                    pick(() => _openShopEntry(TransactionType.purchase, v)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openShopEntry(TransactionType type, double amount) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(
          initialType: type,
          initialAmount: amount,
        ),
      ),
    );
  }

  void _moreCalculators() {
    final ss = ref.read(storeStringsProvider);
    showCreamSheet<void>(
      context,
      title: ss.moreCalculators,
      builder: (sheetContext) {
        void open(Widget screen) {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => screen),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SaveOption(
                icon: Icons.sell_outlined,
                color: AppColors.brand,
                label: ss.calcPricing,
                subtitle: ss.calcPricingSub,
                onTap: () => open(const BusinessCalculatorsScreen()),
              ),
              _SaveOption(
                icon: Icons.account_balance_outlined,
                color: AppColors.purchase,
                label: ss.calcLoan,
                subtitle: ss.calcLoanSub,
                onTap: () => open(const LoanCalculatorsScreen()),
              ),
              _SaveOption(
                icon: Icons.savings_outlined,
                color: AppColors.sale,
                label: ss.calcSavings,
                subtitle: ss.calcSavingsSub,
                onTap: () => open(const InvestmentCalculatorsScreen()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final enabled = _hasAmount;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: Text(ss.calcTitle, style: AppFonts.display(size: 20)),
        actions: [
          IconButton(
            tooltip: ss.moreCalculators,
            onPressed: _moreCalculators,
            icon: const Icon(Icons.grid_view_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: CapsLabel(ss.calcHistory)),
                  if (_tape.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_tape.clear),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(ss.calcClear),
                    ),
                ],
              ),
              Expanded(
                child: _tape.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            ss.calcEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.inkFaint,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: _tape.length,
                        itemBuilder: (_, i) {
                          final line = _tape[_tape.length - 1 - i];
                          return InkWell(
                            onTap: () => _reuse(line),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.expression,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.inkSoft,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '= ${money(line.result)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              CalcDisplay(input: _input, money: money),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.call_split_rounded,
                    label: ss.calcSplit,
                    onTap: enabled ? _split : null,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.ios_share_rounded,
                    label: ss.calcShare,
                    onTap: enabled ? _share : null,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.edit_note_rounded,
                    label: ss.calcSave,
                    onTap: enabled ? _save : null,
                    primary: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CalcKeypad(onKey: _press, keyHeight: 54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return Expanded(
      child: primary
          ? FilledButton(onPressed: onTap, style: style, child: child)
          : OutlinedButton(onPressed: onTap, style: style, child: child),
    );
  }
}

class _SaveOption extends StatelessWidget {
  const _SaveOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
            ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
    );
  }
}

class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet({required this.total});

  final double total;

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  int _people = 2;

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final each = CalcEngine.roundMoney(widget.total / _people);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ss.splitTitle, style: AppFonts.display(size: 20)),
          const SizedBox(height: 4),
          Text(
            money(widget.total),
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(ss.splitPeople)),
              QtyStepper(
                qty: _people,
                onMinus: () {
                  if (_people > 2) setState(() => _people--);
                },
                onPlus: () {
                  if (_people < 50) setState(() => _people++);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          CreamCard(
            color: AppColors.brandSoft,
            borderColor: AppColors.brandSoftBorder,
            child: Text(
              ss.eachPays(money(each)),
              textAlign: TextAlign.center,
              style: AppFonts.display(size: 24, color: AppColors.brandDark),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              LaunchUtils.shareText(
                '${money(widget.total)} ÷ $_people = ${ss.eachPays(money(each))}',
              );
            },
            icon: const Icon(Icons.ios_share_rounded, size: 19),
            label: Text(ss.calcShare),
          ),
        ],
      ),
    );
  }
}
