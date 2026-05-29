import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

class SettingsExpansion extends StatefulWidget {
  const SettingsExpansion({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<SettingsExpansion> createState() => _SettingsExpansionState();
}

class _SettingsExpansionState extends State<SettingsExpansion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dashboardGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.dashboardGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          ...widget.children,
        ],
      ],
    );
  }
}
