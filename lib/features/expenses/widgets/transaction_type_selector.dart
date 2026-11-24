import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';

enum TransactionTypeSelectorLayout { segmented }

/// Sale / Purchase / Expense segmented picker.
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.strings,
    this.layout = TransactionTypeSelectorLayout.segmented,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final AppStrings strings;
  final TransactionTypeSelectorLayout layout;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            for (final type in TransactionType.values)
              Expanded(
                child: _SegmentOption(
                  look: lookFor(type, strings),
                  active: selected == type,
                  onTap: () => onChanged(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.look,
    required this.active,
    required this.onTap,
  });

  final TransactionTypeLook look;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: look.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: look.color.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  look.icon,
                  size: 22,
                  color: active ? Colors.white : look.color,
                ),
                const SizedBox(height: 4),
                Text(
                  look.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: active ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard quick-add row — one colourful tile per entry kind.
class TransactionTypeQuickActions extends StatelessWidget {
  const TransactionTypeQuickActions({
    super.key,
    required this.strings,
    required this.onSelected,
  });

  final AppStrings strings;
  final ValueChanged<TransactionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // Equal-height cards even when one subtitle wraps to two lines.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in TransactionType.values) ...[
              if (type != TransactionType.values.first)
                const SizedBox(width: 10),
              Expanded(
                child: _QuickTile(
                  look: lookFor(type, strings),
                  onTap: () => onSelected(type),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.look, required this.onTap});

  final TransactionTypeLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Shadow lives on the outer box so the Material does not clip it into
    // square corners.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: look.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: look.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: look.color.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(look.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  look.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: look.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  look.subtitle,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
