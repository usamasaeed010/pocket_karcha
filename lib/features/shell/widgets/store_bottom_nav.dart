import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

/// Five tabs with a soft pill behind the active icon.
class StoreBottomNav extends StatelessWidget {
  const StoreBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    this.ordersBadge = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final int ordersBadge;

  static const _icons = [
    (Icons.storefront_outlined, Icons.storefront_rounded),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    (Icons.list_alt_outlined, Icons.list_alt_rounded),
    (Icons.menu_book_outlined, Icons.menu_book_rounded),
    (Icons.tune_outlined, Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.creamCard,
        border: Border(top: BorderSide(color: AppColors.creamBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _icons[i].$1,
                    activeIcon: _icons[i].$2,
                    label: labels[i],
                    selected: currentIndex == i,
                    badge: i == 1 ? ordersBadge : 0,
                    onTap: () => onTap(i),
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
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandDark : AppColors.navInactive;
    return InkResponse(
      onTap: onTap,
      highlightShape: BoxShape.rectangle,
      radius: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brandSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    selected ? activeIcon : icon,
                    size: 22,
                    color: color,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 8,
                    top: -2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.pending,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.creamCard, width: 2),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
