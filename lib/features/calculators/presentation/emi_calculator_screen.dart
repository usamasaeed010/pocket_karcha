import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/calculators/widgets/calculator_widgets.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';

class EmiCalculatorScreen extends ConsumerStatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  ConsumerState<EmiCalculatorScreen> createState() =>
      _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends ConsumerState<EmiCalculatorScreen> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _tenure = TextEditingController();
  double _emi = 0;
  double _total = 0;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _tenure.dispose();
    super.dispose();
  }

  void _calc() {
    final p = double.tryParse(_principal.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final m = int.tryParse(_tenure.text) ?? 0;
    setState(() {
      _emi = calculateEmi(p, r, m);
      _total = _emi * m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return CalculatorDetailScaffold(
      title: s.emiCalculator,
      child: Column(
        children: [
          CalculatorField(
            label: s.loanAmount,
            controller: _principal,
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.annualInterestRate,
            controller: _rate,
            suffix: '%',
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.tenureMonths,
            controller: _tenure,
            suffix: s.monthsShort,
            hint: s.enterValue,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calc,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navActive,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(s.calculate),
          ),
          const SizedBox(height: 24),
          CalculatorResultCard(
            label: s.monthlyEmi,
            value: _emi,
            currencyCode: currency,
            highlight: true,
          ),
          const SizedBox(height: 12),
          CalculatorResultCard(
            label: s.totalPayment,
            value: _total,
            currencyCode: currency,
          ),
        ],
      ),
    );
  }
}

class FlatLoanCalculatorScreen extends ConsumerStatefulWidget {
  const FlatLoanCalculatorScreen({super.key});

  @override
  ConsumerState<FlatLoanCalculatorScreen> createState() =>
      _FlatLoanCalculatorScreenState();
}

class _FlatLoanCalculatorScreenState
    extends ConsumerState<FlatLoanCalculatorScreen> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _tenure = TextEditingController();
  double _interest = 0;
  double _total = 0;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _tenure.dispose();
    super.dispose();
  }

  void _calc() {
    final p = double.tryParse(_principal.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final y = double.tryParse(_tenure.text) ?? 0;
    setState(() {
      _interest = p * r / 100 * y;
      _total = p + _interest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return CalculatorDetailScaffold(
      title: s.flatRateLoan,
      child: Column(
        children: [
          CalculatorField(
            label: s.loanAmount,
            controller: _principal,
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.annualInterestRate,
            controller: _rate,
            suffix: '%',
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.tenureYears,
            controller: _tenure,
            suffix: s.yearsShort,
            hint: s.enterValue,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calc,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navActive,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(s.calculate),
          ),
          const SizedBox(height: 24),
          CalculatorResultCard(label: s.totalInterest, value: _interest, currencyCode: currency),
          const SizedBox(height: 12),
          CalculatorResultCard(label: s.totalPayment, value: _total, currencyCode: currency, highlight: true),
        ],
      ),
    );
  }
}

class ReducingLoanCalculatorScreen extends ConsumerStatefulWidget {
  const ReducingLoanCalculatorScreen({super.key});

  @override
  ConsumerState<ReducingLoanCalculatorScreen> createState() =>
      _ReducingLoanCalculatorScreenState();
}

class _ReducingLoanCalculatorScreenState
    extends ConsumerState<ReducingLoanCalculatorScreen> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _tenure = TextEditingController();
  double _emi = 0;
  double _interest = 0;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _tenure.dispose();
    super.dispose();
  }

  void _calc() {
    final p = double.tryParse(_principal.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final m = int.tryParse(_tenure.text) ?? 0;
    final emi = calculateEmi(p, r, m);
    setState(() {
      _emi = emi;
      _interest = emi * m - p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currency = ref.watch(selectedCurrencyProvider);

    return CalculatorDetailScaffold(
      title: s.reducingBalanceLoan,
      child: Column(
        children: [
          CalculatorField(
            label: s.loanAmount,
            controller: _principal,
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.annualInterestRate,
            controller: _rate,
            suffix: '%',
            hint: s.enterValue,
          ),
          const SizedBox(height: 16),
          CalculatorField(
            label: s.tenureMonths,
            controller: _tenure,
            suffix: s.monthsShort,
            hint: s.enterValue,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calc, style: FilledButton.styleFrom(backgroundColor: AppColors.navActive, minimumSize: const Size(double.infinity, 50)), child: Text(s.calculate)),
          const SizedBox(height: 24),
          CalculatorResultCard(label: s.monthlyEmi, value: _emi, currencyCode: currency, highlight: true),
          const SizedBox(height: 12),
          CalculatorResultCard(label: s.totalInterest, value: _interest, currencyCode: currency),
        ],
      ),
    );
  }
}
