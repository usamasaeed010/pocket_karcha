import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

/// Five-tab bottom bar: Home · History · Reports · People · More.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.strings,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final items = [
      (ShellTabs.home, Icons.home_outlined, Icons.home_rounded, strings.home),
      (
        ShellTabs.history,
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        strings.history,
      ),
      (
        ShellTabs.reports,
        Icons.insights_outlined,
        Icons.insights_rounded,
        strings.reports,
      ),
      (
        ShellTabs.people,
        Icons.people_outline_rounded,
        Icons.people_alt_rounded,
        strings.people,
      ),
      (
        ShellTabs.more,
        Icons.grid_view_outlined,
        Icons.grid_view_rounded,
        strings.more,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              for (final (index, icon, activeIcon, label) in items)
                Expanded(
                  child: _NavItem(
                    icon: icon,
                    activeIcon: activeIcon,
                    label: label,
                    selected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navActive : AppColors.navInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 18 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.navActive.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(selected ? activeIcon : icon, size: 24, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
