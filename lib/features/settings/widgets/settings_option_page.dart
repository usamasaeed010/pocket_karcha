import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/l10n/app_strings.dart';
import 'package:pocket_karcha/shared/widgets/app_toolbar.dart';

/// Radio-list settings page with unified toolbar.
class SettingsOptionPage<T> extends StatelessWidget {
  const SettingsOptionPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      subtitle: subtitle,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final opt = options[i];
          final active = opt == selected;
          return Material(
            color: active ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                onSelected(opt);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppColors.navActive : const Color(0xFFE2E8F0),
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelOf(opt),
                        style: TextStyle(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      active
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: active
                          ? AppColors.navActive
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsTogglePage extends StatelessWidget {
  const SettingsTogglePage({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                activeColor: AppColors.navActive,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
