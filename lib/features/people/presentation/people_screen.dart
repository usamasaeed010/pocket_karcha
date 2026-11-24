import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/khata/presentation/people_ledger_view.dart';

/// People tab of the full khata. Same lena-dena list as the Khata tab.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.cream,
      child: Padding(
        padding: EdgeInsets.only(top: 12),
        child: PeopleLedgerView(),
      ),
    );
  }
}
