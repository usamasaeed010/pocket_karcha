import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

/// Avatar for people / contacts — consistent brand colors.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.radius = 24,
  });

  final String name;
  final double radius;

  static const _palette = [
    Color(0xFF1B4332),
    Color(0xFF2D6A4F),
    Color(0xFF0D9488),
    Color(0xFF0F766E),
    Color(0xFF2E7D32),
  ];

  Color get _color {
    if (name.isEmpty) return AppColors.dashboardGreen;
    return _palette[name.codeUnitAt(0) % _palette.length];
  }

  String get _initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// Saved person row on People tab.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.name,
    required this.phone,
    required this.creditLabel,
    required this.creditValue,
    required this.debitLabel,
    required this.debitValue,
    required this.balanceLabel,
    required this.balanceValue,
    required this.balanceColor,
    required this.onTap,
  });

  final String name;
  final String phone;
  final String creditLabel;
  final String creditValue;
  final String debitLabel;
  final String debitValue;
  final String balanceLabel;
  final String balanceValue;
  final Color balanceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PersonAvatar(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _LedgerChip(
                            label: creditLabel,
                            value: creditValue,
                            color: AppColors.navActive,
                          ),
                          _LedgerChip(
                            label: debitLabel,
                            value: debitValue,
                            color: AppColors.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      balanceLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balanceValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: balanceColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.navInactive.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone contact row in picker list.
class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.name,
    required this.phone,
    required this.noNameLabel,
    required this.onTap,
  });

  final String name;
  final String phone;
  final String noNameLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? noNameLabel : name.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                PersonAvatar(name: displayName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: name.trim().isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 18,
                    color: AppColors.dashboardGreen,
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

class _LedgerChip extends StatelessWidget {
  const _LedgerChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.95),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
