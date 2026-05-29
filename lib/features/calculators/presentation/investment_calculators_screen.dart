import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/calculators/presentation/fd_calculator_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/sip_calculator_screen.dart';
import 'package:pocket_karcha/features/settings/widgets/menu_tile.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class InvestmentCalculatorsScreen extends ConsumerWidget {
  const InvestmentCalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return AppPage(
      title: s.investmentCalculators,
      subtitle: s.investmentCalculatorsDesc,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuTile(
            icon: Icons.savings_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: s.sipCalculator,
            subtitle: s.sipCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SipCalculatorScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuTile(
            icon: Icons.account_balance_outlined,
            iconColor: const Color(0xFF2563EB),
            title: s.fdCalculator,
            subtitle: s.fdCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const FdCalculatorScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
