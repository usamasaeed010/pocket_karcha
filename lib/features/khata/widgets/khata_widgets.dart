import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Green "add" button at the bottom right of a Khata view.
class KhataAddButton extends StatelessWidget {
  const KhataAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      // Several views live in one IndexedStack, so no hero animation.
      heroTag: null,
      onPressed: onTap,
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// One entry row: coloured icon, title, subtitle and amount.
class KhataEntryTile extends StatelessWidget {
  const KhataEntryTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.tag,
    this.tagColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String? tag;

  /// Tag text colour (soft background of the same colour). Grey when null.
  final Color? tagColor;

  /// Shown after the amount, e.g. a "mark paid" button.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        SoftChip(
                          label: tag!,
                          background: tagColor?.withValues(alpha: 0.13) ??
                              AppColors.creamDeep,
                          foreground: tagColor ?? AppColors.inkSoft,
                          fontSize: 10.5,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: amountColor,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Small round "✓ paid" button for a pending entry row.
class MarkPaidButton extends StatelessWidget {
  const MarkPaidButton({super.key, required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.brandSoft,
          foregroundColor: AppColors.brandDark,
        ),
        icon: const Icon(Icons.check_rounded, size: 18),
      ),
    );
  }
}

/// ‹ November 2026 ›
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrev,
    this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;

  /// Null on the current month (nothing to show ahead).
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Rows of entries in one card, with thin dividers.
class KhataEntryCard extends StatelessWidget {
  const KhataEntryCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CreamCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 64,
                  color: AppColors.creamBorder,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
