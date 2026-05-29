import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/calculators/presentation/emi_calculator_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/flat_loan_calculator_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/reducing_loan_calculator_screen.dart';
import 'package:pocket_karcha/features/settings/widgets/menu_tile.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class LoanCalculatorsScreen extends ConsumerWidget {
  const LoanCalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return AppPage(
      title: s.loanCalculators,
      subtitle: s.loanCalculatorsDesc,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuTile(
            icon: Icons.calculate_outlined,
            iconColor: const Color(0xFFF97316),
            title: s.emiCalculator,
            subtitle: s.emiCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const EmiCalculatorScreen()),
            ),
          ),
          const SizedBox(height: 12),
          MenuTile(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFFEA580C),
            title: s.flatRateLoan,
            subtitle: s.flatRateLoanDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const FlatLoanCalculatorScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuTile(
            icon: Icons.trending_down_rounded,
            iconColor: AppColors.expense,
            title: s.reducingBalanceLoan,
            subtitle: s.reducingBalanceLoanDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ReducingLoanCalculatorScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
