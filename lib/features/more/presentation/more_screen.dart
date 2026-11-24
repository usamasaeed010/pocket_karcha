import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/utils/currency_formatter.dart';
import 'package:pocket_karcha/features/calculators/presentation/business_calculators_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/investment_calculators_screen.dart';
import 'package:pocket_karcha/features/calculators/presentation/loan_calculators_screen.dart';
import 'package:pocket_karcha/features/home/widgets/budget_card.dart';
import 'package:pocket_karcha/features/settings/presentation/about_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/manage_account_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/privacy_policy_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/categories_screen.dart';
import 'package:pocket_karcha/features/settings/presentation/settings_hub_screen.dart';
import 'package:pocket_karcha/features/settings/widgets/logout_sheet.dart';
import 'package:pocket_karcha/features/settings/widgets/menu_tile.dart';
import 'package:pocket_karcha/providers/auth_provider.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';
import 'package:pocket_karcha/providers/locale_provider.dart';
import 'package:pocket_karcha/shared/widgets/animated_list_item.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final budget = ref.watch(budgetStatusProvider);
    final currency = ref.watch(selectedCurrencyProvider);
    String fmt(double v) => CurrencyFormatter.format(v, currencyCode: currency);
    var index = 0;

    Widget anim(Widget child) =>
        AnimatedListItem(index: index++, child: child);

    return ColoredBox(
      color: AppColors.dashboardSurface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          anim(MenuSectionTitle(title: s.myShop)),
          anim(MenuTile(
            icon: Icons.savings_rounded,
            iconColor: AppColors.primary,
            title: s.monthlyBudget,
            subtitle: budget.isSet
                ? s.spentOfBudget(fmt(budget.spent), fmt(budget.budget))
                : s.monthlyBudgetDesc,
            gradient: const [AppColors.primary, AppColors.primaryLight],
            onTap: () => showBudgetSheet(context, ref),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF6366F1),
            title: s.reports,
            subtitle: s.reportsDesc,
            gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
            onTap: () => ref.read(mainTabIndexProvider.notifier).state =
                ShellTabs.reports,
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.category_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: s.categories,
            subtitle: s.categoriesDesc,
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            onTap: () => _push(context, const CategoriesScreen()),
          )),
          const SizedBox(height: 28),
          anim(MenuSectionTitle(title: s.calculators)),
          anim(MenuTile(
            icon: Icons.storefront_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: s.businessCalculators,
            subtitle: s.businessCalculatorsDesc,
            gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            onTap: () => _push(context, const BusinessCalculatorsScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.percent_rounded,
            iconColor: const Color(0xFFF97316),
            title: s.loanCalculators,
            subtitle: s.loanCalculatorsDesc,
            gradient: const [Color(0xFFF97316), Color(0xFFFB923C)],
            onTap: () => _push(context, const LoanCalculatorsScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: s.investmentCalculators,
            subtitle: s.investmentCalculatorsDesc,
            gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            onTap: () => _push(context, const InvestmentCalculatorsScreen()),
          )),
          const SizedBox(height: 28),
          anim(MenuSectionTitle(title: s.general)),
          anim(MenuTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.dashboardGreen,
            title: s.editProfile,
            subtitle: s.editProfileDesc,
            onTap: () => _push(context, const ManageAccountScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.settings_outlined,
            iconColor: AppColors.primary,
            title: s.settings,
            subtitle: s.settingsDesc,
            onTap: () => _push(context, const SettingsHubScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF0EA5E9),
            title: s.privacyPolicy,
            subtitle: s.privacyPolicyDesc,
            onTap: () => _push(context, const PrivacyPolicyScreen()),
          )),
          const SizedBox(height: 12),
          anim(MenuTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.dashboardGreen,
            title: s.aboutUs,
            subtitle: s.aboutUsDesc,
            onTap: () => _push(context, const AboutScreen()),
          )),
          const SizedBox(height: 32),
          anim(
            Center(
              child: TextButton.icon(
                onPressed: () => showLogoutSheet(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
                label: Text(
                  s.logout,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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
