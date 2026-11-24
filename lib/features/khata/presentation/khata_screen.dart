import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/features/calculator/presentation/expense_calculator_screen.dart';
import 'package:pocket_karcha/features/khata/presentation/people_ledger_view.dart';
import 'package:pocket_karcha/features/khata/presentation/personal_khata_view.dart';
import 'package:pocket_karcha/features/khata/presentation/shop_khata_view.dart';
import 'package:pocket_karcha/features/voice/voice_entry_sheet.dart';
import 'package:pocket_karcha/providers/khata_providers.dart';

/// Khata tab: Shop · Personal · Lena-dena, with voice entry and the expense
/// calculator one tap away.
class KhataScreen extends ConsumerWidget {
  const KhataScreen({super.key});

  void _openCalculator(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExpenseCalculatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ss = ref.watch(storeStringsProvider);
    final segment = ref.watch(khataSegmentProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 8, 6),
            child: Row(
              children: [
                Text(ss.khataTitle, style: AppFonts.display(size: 26)),
                const Spacer(),
                IconButton(
                  tooltip: ss.voiceEntry,
                  onPressed: () => showVoiceEntrySheet(context),
                  icon: const Icon(Icons.mic_none_rounded),
                  color: AppColors.brand,
                ),
                TextButton.icon(
                  onPressed: () => _openCalculator(context),
                  icon: const Icon(Icons.calculate_outlined, size: 20),
                  label: Text(ss.calculator),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: _Segments(
              labels: [ss.segShop, ss.segPersonal, ss.segPeople],
              index: segment,
              onChanged: (i) =>
                  ref.read(khataSegmentProvider.notifier).state = i,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: segment,
              children: const [
                ShopKhataView(),
                PersonalKhataView(),
                PeopleLedgerView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width segmented control.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.creamBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: i == index ? Colors.white : AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
