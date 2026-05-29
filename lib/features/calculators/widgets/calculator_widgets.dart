import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class CalculatorField extends StatelessWidget {
  const CalculatorField({
    super.key,
    required this.label,
    required this.controller,
    this.suffix,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.55),
            ),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

class CalculatorResultCard extends StatelessWidget {
  const CalculatorResultCard({
    super.key,
    required this.label,
    required this.value,
    this.currencyCode = 'PKR',
    this.highlight = false,
  });

  final String label;
  final double value;
  final String currencyCode;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? AppColors.dashboardGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.dashboardGreen : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(value, currencyCode: currencyCode),
            style: TextStyle(
              color: highlight ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// EMI = P × r × (1+r)^n / ((1+r)^n − 1)
double calculateEmi(double principal, double annualRate, int months) {
  if (principal <= 0 || months <= 0) return 0;
  if (annualRate <= 0) return principal / months;
  final r = annualRate / 12 / 100;
  final pow = math.pow(1 + r, months).toDouble();
  return principal * r * pow / (pow - 1);
}

double calculateSipFutureValue(
  double monthly,
  double annualReturn,
  int months,
) {
  if (monthly <= 0 || months <= 0) return 0;
  if (annualReturn <= 0) return monthly * months;
  final r = annualReturn / 12 / 100;
  return monthly * ((math.pow(1 + r, months) - 1) / r) * (1 + r);
}

double calculateFdMaturity(double principal, double rate, int months) {
  if (principal <= 0) return 0;
  return principal * math.pow(1 + rate / 100 / 12, months).toDouble();
}

double calculateMarkup(double cost, double markupPercent) {
  return cost * (1 + markupPercent / 100);
}

double calculateBreakEven(double fixedCost, double price, double variableCost) {
  if (price <= variableCost) return 0;
  return fixedCost / (price - variableCost);
}

double calculateProfitMargin(double revenue, double cost) {
  if (revenue <= 0) return 0;
  return (revenue - cost) / revenue * 100;
}

class CalculatorDetailScaffold extends StatelessWidget {
  const CalculatorDetailScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
