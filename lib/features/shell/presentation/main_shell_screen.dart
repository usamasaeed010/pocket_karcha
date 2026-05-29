import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/history/presentation/history_screen.dart';
import 'package:pocket_karcha/features/home/presentation/dashboard_screen.dart';
import 'package:pocket_karcha/features/more/presentation/more_screen.dart';
import 'package:pocket_karcha/features/people/presentation/people_screen.dart';
import 'package:pocket_karcha/features/shell/widgets/add_transaction_sheet.dart';
import 'package:pocket_karcha/features/shell/widgets/app_bottom_nav.dart';
import 'package:pocket_karcha/features/shell/widgets/shell_header.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/app_snackbar.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  DateTime? _lastBackOnHome;

  static const _exitWindow = Duration(seconds: 2);

  void _onBackInvoked() {
    final index = ref.read(mainTabIndexProvider);

    if (index != 0) {
      ref.read(mainTabIndexProvider.notifier).state = 0;
      _lastBackOnHome = null;
      return;
    }

    final now = DateTime.now();
    final s = ref.read(appStringsProvider);

    if (_lastBackOnHome != null &&
        now.difference(_lastBackOnHome!) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }

    _lastBackOnHome = now;
    context.showInfoSnack(s.pressBackAgainToExit);
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(mainTabIndexProvider);
    final s = ref.watch(appStringsProvider);
    final showFab = index == 0 || index == 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackInvoked();
      },
      child: Scaffold(
        backgroundColor: AppColors.dashboardSurface,
        body: Column(
          children: [
            const ShellHeader(),
            Expanded(child: _TabBody(index: index)),
          ],
        ),
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                onPressed: () => showAddTransactionSheet(context, strings: s),
                backgroundColor: AppColors.navActive,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  s.add,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : null,
        bottomNavigationBar: AppBottomNav(
          currentIndex: index,
          strings: s,
          onTap: (i) {
            ref.read(mainTabIndexProvider.notifier).state = i;
            if (i != 0) _lastBackOnHome = null;
          },
        ),
      ),
    );
  }
}

/// Builds only the visible tab so Home does not mount History/More/People at once.
class _TabBody extends StatelessWidget {
  const _TabBody({required this.index});

  final int index;

  static const _tabKeys = [
    ValueKey<String>('shell_tab_home'),
    ValueKey<String>('shell_tab_history'),
    ValueKey<String>('shell_tab_people'),
    ValueKey<String>('shell_tab_more'),
  ];

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => DashboardScreen(key: _tabKeys[0]),
      1 => HistoryScreen(key: _tabKeys[1]),
      2 => PeopleScreen(key: _tabKeys[2]),
      3 => MoreScreen(key: _tabKeys[3]),
      _ => const SizedBox.shrink(),
    };
  }
}
