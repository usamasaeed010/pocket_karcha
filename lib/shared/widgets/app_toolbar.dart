import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/shared/widgets/profile_avatar.dart';

/// Toolbar typography — uses app theme fonts (Inter / Noto Nastaliq Urdu).
abstract final class AppToolbarStyle {
  static const Color background = AppColors.dashboardGreen;
  static const Color titleColor = Colors.white;
  static const Color subtitleColor = Color(0xCCFFFFFF);
  static const Color actionColor = Colors.white;
  static const Color iconColor = Colors.white;

  static const double toolbarMinHeight = 56;
  static const double toolbarWithSubtitleHeight = 72;

  static TextStyle titleStyle(BuildContext context, {bool large = false}) {
    final theme = Theme.of(context).textTheme;
    return (large ? theme.headlineSmall : theme.titleLarge)?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w700,
          fontSize: large ? 24 : 18,
          height: 1.15,
          letterSpacing: large ? -0.3 : 0,
        ) ??
        TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w700,
          fontSize: large ? 24 : 18,
          height: 1.15,
          fontFamily: AppFonts.family,
        );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: subtitleColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          height: 1.25,
        ) ??
        const TextStyle(
          color: subtitleColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          height: 1.25,
        );
  }

  static TextStyle actionStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: actionColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ) ??
        const TextStyle(
          color: actionColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );
  }

  static TextStyle chipStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
          color: subtitleColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 1.2,
        ) ??
        const TextStyle(
          color: subtitleColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
  }
}

/// Core toolbar content — used in shell and pushed screens.
class AppToolbarBar extends StatelessWidget {
  const AppToolbarBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.leading,
    this.actions = const [],
    this.largeTitle = false,
    this.onBack,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final Widget? leading;
  final List<Widget> actions;
  final bool largeTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final minHeight = hasSubtitle
        ? AppToolbarStyle.toolbarWithSubtitleHeight
        : AppToolbarStyle.toolbarMinHeight;

    return Material(
      color: AppToolbarStyle.background,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, 6, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBack)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppToolbarStyle.iconColor,
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  )
                else if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: leading!,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: showBack ? 4 : 0,
                      right: 8,
                    ),
                    child: title == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title!,
                                style: AppToolbarStyle.titleStyle(
                                  context,
                                  large: largeTitle,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasSubtitle) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  style: AppToolbarStyle.subtitleStyle(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold appBar wrapper.
class AppToolbar extends StatelessWidget implements PreferredSizeWidget {
  const AppToolbar({
    super.key,
    this.title,
    this.subtitle,
    this.showBack = false,
    this.leading,
    this.actions = const [],
    this.largeTitle = false,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final Widget? leading;
  final List<Widget> actions;
  final bool largeTitle;

  @override
  Size get preferredSize {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    return Size.fromHeight(
      hasSubtitle
          ? AppToolbarStyle.toolbarWithSubtitleHeight
          : AppToolbarStyle.toolbarMinHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppToolbarBar(
      title: title,
      subtitle: subtitle,
      showBack: showBack,
      leading: leading,
      actions: actions,
      largeTitle: largeTitle,
    );
  }
}

class AppToolbarTextButton extends StatelessWidget {
  const AppToolbarTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label, style: AppToolbarStyle.actionStyle(context)),
    );
  }
}

class AppToolbarIconAction extends StatelessWidget {
  const AppToolbarIconAction({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: onPressed,
      icon: Icon(icon, color: AppToolbarStyle.iconColor, size: 22),
    );
  }
}

/// Compact avatar for green toolbar — white ring, photo or initial.
class AppToolbarAvatar extends StatefulWidget {
  const AppToolbarAvatar({
    super.key,
    required this.initial,
    this.imageUrl,
  });

  final String initial;
  final String? imageUrl;

  @override
  State<AppToolbarAvatar> createState() => _AppToolbarAvatarState();
}

class _AppToolbarAvatarState extends State<AppToolbarAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant AppToolbarAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFailed = false;
    }
  }

  bool get _showImage {
    final url = widget.imageUrl?.trim();
    return !_imageFailed && url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 2,
        ),
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: ClipOval(
        child: _showImage
            ? Image.network(
                widget.imageUrl!.trim(),
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _imageFailed = true);
                  });
                  return _initials();
                },
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        widget.initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class AppToolbarChip extends StatelessWidget {
  const AppToolbarChip({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppToolbarStyle.subtitleColor),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: AppToolbarStyle.chipStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.largeTitle = false,
    this.floatingActionButton,
    this.body,
    this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final bool largeTitle;
  final Widget? floatingActionButton;
  final Widget? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppToolbar(
        title: title,
        subtitle: subtitle,
        showBack: showBack,
        actions: actions,
        largeTitle: largeTitle,
      ),
      body: body ?? child,
      floatingActionButton: floatingActionButton,
    );
  }
}
