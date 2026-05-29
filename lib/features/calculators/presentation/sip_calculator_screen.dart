import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/calculators/widgets/calculator_widgets.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class SipCalculatorScreen extends ConsumerStatefulWidget {
  const SipCalculatorScreen({super.key});

  @override
  ConsumerState<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends ConsumerState<SipCalculatorScreen> {
  final _monthly = TextEditingController();
  final _return = TextEditingController();
  final _years = TextEditingController();
  double _future = 0;
  double _invested = 0;

  @override
  void dispose() {
    _monthly.dispose();
    _return.dispose();
    _years.dispose();
    super.dispose();
  }

  void _calc() {
    final m = double.tryParse(_monthly.text) ?? 0;
    final r = double.tryParse(_return.text) ?? 0;
    final y = int.tryParse(_years.text) ?? 0;
    final months = y * 12;
    setState(() {
      _future = calculateSipFutureValue(m, r, months);
      _invested = m * months;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return CalculatorDetailScaffold(
      title: s.sipCalculator,
      child: Column(
        children: [
          CalculatorField(hint: s.enterValue, label: s.monthlyInvestment, controller: _monthly),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.expectedReturn, controller: _return, suffix: '%'),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.tenureYears, controller: _years, suffix: s.yearsShort),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          CalculatorResultCard(label: s.totalInvested, value: _invested, currencyCode: currency),
          const SizedBox(height: 12),
          CalculatorResultCard(label: s.futureValue, value: _future, currencyCode: currency, highlight: true),
          const SizedBox(height: 12),
          CalculatorResultCard(label: s.estimatedGain, value: _future - _invested, currencyCode: currency),
        ],
      ),
    );
  }
}

class FdCalculatorScreen extends ConsumerStatefulWidget {
  const FdCalculatorScreen({super.key});

  @override
  ConsumerState<FdCalculatorScreen> createState() => _FdCalculatorScreenState();
}

class _FdCalculatorScreenState extends ConsumerState<FdCalculatorScreen> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();
  double _maturity = 0;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _months.dispose();
    super.dispose();
  }

  void _calc() {
    final p = double.tryParse(_principal.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final m = int.tryParse(_months.text) ?? 0;
    setState(() => _maturity = calculateFdMaturity(p, r, m));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    final p = double.tryParse(_principal.text) ?? 0;

    return CalculatorDetailScaffold(
      title: s.fdCalculator,
      child: Column(
        children: [
          CalculatorField(hint: s.enterValue, label: s.depositAmount, controller: _principal),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.annualInterestRate, controller: _rate, suffix: '%'),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.tenureMonths, controller: _months, suffix: s.monthsShort),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          CalculatorResultCard(label: s.maturityAmount, value: _maturity, currencyCode: currency, highlight: true),
          const SizedBox(height: 12),
          CalculatorResultCard(label: s.estimatedGain, value: _maturity - p, currencyCode: currency),
        ],
      ),
    );
  }
}

class MarkupCalculatorScreen extends ConsumerStatefulWidget {
  const MarkupCalculatorScreen({super.key});

  @override
  ConsumerState<MarkupCalculatorScreen> createState() =>
      _MarkupCalculatorScreenState();
}

class _MarkupCalculatorScreenState extends ConsumerState<MarkupCalculatorScreen> {
  final _cost = TextEditingController();
  final _markup = TextEditingController();
  double _selling = 0;

  @override
  void dispose() {
    _cost.dispose();
    _markup.dispose();
    super.dispose();
  }

  void _calc() {
    final c = double.tryParse(_cost.text) ?? 0;
    final m = double.tryParse(_markup.text) ?? 0;
    setState(() => _selling = calculateMarkup(c, m));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return CalculatorDetailScaffold(
      title: s.markupCalculator,
      child: Column(
        children: [
          CalculatorField(hint: s.enterValue, label: s.costPrice, controller: _cost),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.markupPercent, controller: _markup, suffix: '%'),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          CalculatorResultCard(label: s.sellingPrice, value: _selling, currencyCode: currency, highlight: true),
        ],
      ),
    );
  }
}

class BreakEvenCalculatorScreen extends ConsumerStatefulWidget {
  const BreakEvenCalculatorScreen({super.key});

  @override
  ConsumerState<BreakEvenCalculatorScreen> createState() =>
      _BreakEvenCalculatorScreenState();
}

class _BreakEvenCalculatorScreenState
    extends ConsumerState<BreakEvenCalculatorScreen> {
  final _fixed = TextEditingController();
  final _price = TextEditingController();
  final _variable = TextEditingController();
  double _units = 0;

  @override
  void dispose() {
    _fixed.dispose();
    _price.dispose();
    _variable.dispose();
    super.dispose();
  }

  void _calc() {
    final f = double.tryParse(_fixed.text) ?? 0;
    final p = double.tryParse(_price.text) ?? 0;
    final v = double.tryParse(_variable.text) ?? 0;
    setState(() => _units = calculateBreakEven(f, p, v));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return CalculatorDetailScaffold(
      title: s.breakEvenCalculator,
      child: Column(
        children: [
          CalculatorField(hint: s.enterValue, label: s.fixedCost, controller: _fixed),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.sellingPrice, controller: _price),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.variableCost, controller: _variable),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dashboardGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.breakEvenUnits, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  _units.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfitMarginCalculatorScreen extends ConsumerStatefulWidget {
  const ProfitMarginCalculatorScreen({super.key});

  @override
  ConsumerState<ProfitMarginCalculatorScreen> createState() =>
      _ProfitMarginCalculatorScreenState();
}

class _ProfitMarginCalculatorScreenState
    extends ConsumerState<ProfitMarginCalculatorScreen> {
  final _revenue = TextEditingController();
  final _cost = TextEditingController();
  double _margin = 0;

  @override
  void dispose() {
    _revenue.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _calc() {
    final r = double.tryParse(_revenue.text) ?? 0;
    final c = double.tryParse(_cost.text) ?? 0;
    setState(() => _margin = calculateProfitMargin(r, c));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return CalculatorDetailScaffold(
      title: s.profitMarginCalculator,
      child: Column(
        children: [
          CalculatorField(hint: s.enterValue, label: s.revenue, controller: _revenue),
          const SizedBox(height: 16),
          CalculatorField(hint: s.enterValue, label: s.totalCost, controller: _cost),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dashboardGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.profitMargin, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  '${_margin.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
