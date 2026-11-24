import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/constants/app_currencies.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_bottom_sheet.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

/// Monthly budget for stock + shop expenses with progress and daily allowance.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final status = ref.watch(budgetStatusProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    String fmt(double v) => CurrencyFormatter.format(v, currencyCode: currency);

    final Color barColor;
    if (status.isOver) {
      barColor = AppColors.expense;
    } else if (status.usedFraction >= 0.8) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.sale;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: !status.isSet
          ? Row(
              children: [
                const _BudgetIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.monthlyBudget,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.setBudgetCta,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => showBudgetSheet(context, ref),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(s.setBudget),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _BudgetIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.monthlyBudget,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            fmt(status.budget),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: s.editBudget,
                      onPressed: () => showBudgetSheet(context, ref),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: status.usedFraction.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.spentOfBudget(fmt(status.spent), fmt(status.budget)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      s.budgetUsed(status.usedPercent),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        status.isOver
                            ? Icons.warning_amber_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: barColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isOver
                                  ? '${s.overBudget}: ${fmt(-status.remaining)}'
                                  : '${s.remaining}: ${fmt(status.remaining)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: barColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status.isOver
                                  ? s.budgetExceededHint
                                  : s.perDayAllowance(
                                      fmt(status.perDayAllowance),
                                      status.daysLeft,
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

class _BudgetIcon extends StatelessWidget {
  const _BudgetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.savings_rounded, color: Colors.white, size: 24),
    );
  }
}

/// Bottom sheet to set, change or remove the monthly budget.
Future<void> showBudgetSheet(BuildContext context, WidgetRef ref) {
  final s = ref.read(appStringsProvider);
  return showAppBottomSheet<void>(
    context: context,
    title: s.monthlyBudget,
    subtitle: s.setBudgetHint,
    maxHeightFraction: 0.7,
    child: const _BudgetSheet(),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet();

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = ref.read(monthlyBudgetProvider);
    _controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(appStringsProvider);
    final value =
        double.tryParse(_controller.text.replaceAll(',', '').trim()) ?? 0;
    if (value <= 0) {
      context.showErrorSnack(s.invalidAmount);
      return;
    }
    await ref.read(monthlyBudgetProvider.notifier).set(value);
    if (!mounted) return;
    Navigator.of(context).pop();
    context.showSuccessSnack(s.snackBudgetSaved);
  }

  Future<void> _remove() async {
    final s = ref.read(appStringsProvider);
    await ref.read(monthlyBudgetProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pop();
    context.showInfoSnack(s.snackBudgetRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final hasBudget = ref.watch(monthlyBudgetProvider) > 0;
    final symbol =
        AppCurrencies.byCode(ref.watch(selectedCurrencyProvider)).symbol;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              labelText: s.budgetAmount,
              prefixText: '$symbol ',
              prefixStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(s.save),
            ),
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _remove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
              ),
              label: Text(
                s.removeBudget,
                style: const TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
