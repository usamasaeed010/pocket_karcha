import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/expenses/widgets/transaction_type_theme.dart';

enum TransactionTypeSelectorLayout { segmented, cards }

/// Professional You Gave / You Got picker — segmented tabs or large cards.
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
      child: layout == TransactionTypeSelectorLayout.segmented
          ? _SegmentedTrack(
              selected: selected,
              strings: strings,
              onChanged: onChanged,
            )
          : _CardRow(
              selected: selected,
              strings: strings,
              onChanged: onChanged,
            ),
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({
    required this.selected,
    required this.strings,
    required this.onChanged,
  });

  final TransactionType selected;
  final AppStrings strings;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: TransactionType.values.map((type) {
          final look = lookFor(type, strings);
          final active = selected == type;
          return Expanded(
            child: _SegmentOption(
              look: look,
              active: active,
              onTap: () => onChanged(type),
            ),
          );
        }).toList(),
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
        color: active ? look.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active ? look.border : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: look.color.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconBadge(
                  look: look,
                  filled: active,
                  size: 32,
                  iconSize: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        look.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: active ? look.color : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        look.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? look.color.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.selected,
    required this.strings,
    required this.onChanged,
  });

  final TransactionType selected;
  final AppStrings strings;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TransactionType.values.map((type) {
        final look = lookFor(type, strings);
        final active = selected == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == TransactionType.gave ? 6 : 0,
              left: type == TransactionType.got ? 6 : 0,
            ),
            child: _TypeCard(
              look: look,
              active: active,
              onTap: () => onChanged(type),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
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
        color: active ? look.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? look.color : const Color(0xFFE2E8F0),
          width: active ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (active ? look.color : Colors.black).withValues(alpha: 0.08),
            blurRadius: active ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(
                      look: look,
                      filled: true,
                      size: 44,
                      iconSize: 22,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: active ? look.color : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  look.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: active ? look.color : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  look.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.look,
    required this.filled,
    required this.size,
    required this.iconSize,
  });

  final TransactionTypeLook look;
  final bool filled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? look.color : look.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        look.icon,
        size: iconSize,
        color: filled ? look.onColor : look.color,
      ),
    );
  }
}

/// Dashboard quick-action row using the same visual language.
class TransactionTypeQuickActions extends StatelessWidget {
  const TransactionTypeQuickActions({
    super.key,
    required this.strings,
    required this.onGave,
    required this.onGot,
  });

  final AppStrings strings;
  final VoidCallback onGave;
  final VoidCallback onGot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickTile(
              look: lookFor(TransactionType.gave, strings),
              onTap: onGave,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickTile(
              look: lookFor(TransactionType.got, strings),
              onTap: onGot,
            ),
          ),
        ],
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
    return Material(
      color: look.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: look.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _IconBadge(
                  look: look,
                  filled: true,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        look.title,
                        style: TextStyle(
                          color: look.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        look.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline, color: look.color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
