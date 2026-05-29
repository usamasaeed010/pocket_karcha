export 'package:pocket_karcha/features/calculators/presentation/sip_calculator_screen.dart'
    show MarkupCalculatorScreen, BreakEvenCalculatorScreen, ProfitMarginCalculatorScreen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/features/calculators/presentation/sip_calculator_screen.dart';
import 'package:pocket_karcha/features/settings/widgets/menu_tile.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

class BusinessCalculatorsScreen extends ConsumerWidget {
  const BusinessCalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return AppPage(
      title: s.businessCalculators,
      subtitle: s.businessCalculatorsDesc,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MenuTile(
            icon: Icons.price_change_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: s.markupCalculator,
            subtitle: s.markupCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const MarkupCalculatorScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuTile(
            icon: Icons.balance_outlined,
            iconColor: const Color(0xFF7C3AED),
            title: s.breakEvenCalculator,
            subtitle: s.breakEvenCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BreakEvenCalculatorScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MenuTile(
            icon: Icons.pie_chart_outline_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: s.profitMarginCalculator,
            subtitle: s.profitMarginCalculatorDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ProfitMarginCalculatorScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
