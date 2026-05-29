import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
/// Consistent modal bottom sheet used across the app.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
  double maxHeightFraction = 0.55,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AppBottomSheet(
      title: title,
      subtitle: subtitle,
      maxHeightFraction: maxHeightFraction,
      child: child,
    ),
  );
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.maxHeightFraction = 0.55,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.sizeOf(context).height * maxHeightFraction,
                  ),
                  child: child,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomSheetOption<T> {
  const AppBottomSheetOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.selected = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
}

Future<T?> showAppOptionsBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<AppBottomSheetOption<T>> options,
  double maxHeightFraction = 0.45,
}) {
  return showAppBottomSheet<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    maxHeightFraction: maxHeightFraction,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 56,
        color: Color(0xFFF1F5F9),
      ),
      itemBuilder: (ctx, index) {
        final opt = options[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: opt.leading,
          title: Text(
            opt.label,
            style: TextStyle(
              fontWeight: opt.selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: opt.subtitle != null
              ? Text(
                  opt.subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: opt.selected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppColors.navActive, size: 24)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => Navigator.pop(ctx, opt.value),
        );
      },
    ),
  );
}
