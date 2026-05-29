import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/features/settings/presentation/manage_account_screen.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/history_provider.dart';
import 'package:pocket_karcha/providers/people_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/providers/session_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';
import 'package:pocket_karcha/shared/widgets/period_segment_bar.dart';

/// Single shell toolbar — title, actions & period bar per tab.
class ShellHeader extends ConsumerWidget {
  const ShellHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(mainTabIndexProvider);
    final s = ref.watch(appStringsProvider);
    final showPeriod = tab == 0 || tab == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShellAppBar(tab: tab, strings: s),
        if (showPeriod)
          PeriodSegmentBar(
            period: ref.watch(dashboardPeriodProvider),
            strings: s,
            onChanged: (p) =>
                ref.read(dashboardPeriodProvider.notifier).state = p,
          ),
      ],
    );
  }
}

class _ShellAppBar extends ConsumerWidget {
  const _ShellAppBar({required this.tab, required this.strings});

  final int tab;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final name = session.displayName?.split(' ').first ??
        session.email?.split('@').first ??
        'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    switch (tab) {
      case 0:
        final balance =
            ref.watch(periodIncomeProvider) - ref.watch(periodTotalProvider);
        final currency = ref.watch(selectedCurrencyProvider);
        final balanceText =
            CurrencyFormatter.format(balance, currencyCode: currency);
        void openEditProfile() {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ManageAccountScreen(),
            ),
          );
        }

        return AppToolbarBar(
          leading: GestureDetector(
            onTap: openEditProfile,
            child: AppToolbarAvatar(
              initial: initial,
              imageUrl: session.avatarUrl,
            ),
          ),
          title: strings.greeting(name),
          subtitle: balanceText,
          actions: [
            AppToolbarIconAction(
              icon: Icons.edit_outlined,
              onPressed: openEditProfile,
            ),
          ],
        );
      case 1:
        final count = ref.watch(filteredHistoryExpensesProvider).length;
        return AppToolbarBar(
          title: strings.history,
          subtitle: strings.periodTransactionCount(
            count,
            ref.watch(dashboardPeriodProvider),
          ),
          largeTitle: true,
        );
      case 2:
        final peopleCount = ref.watch(peopleListProvider).length;
        return AppToolbarBar(
          title: strings.people,
          subtitle: peopleCount == 0
              ? strings.addPeopleDesc
              : strings.peopleCount(peopleCount),
          largeTitle: true,
        );
      case 3:
        return AppToolbarBar(
          title: strings.more,
          subtitle: strings.toolsAndCategories,
          largeTitle: true,
          actions: [
            AppToolbarIconAction(
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ManageAccountScreen(),
                ),
              ),
            ),
          ],
        );
      default:
        return AppToolbarBar(title: strings.appTitle);
    }
  }
}
