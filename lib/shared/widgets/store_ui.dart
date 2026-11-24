import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/core/theme/app_fonts.dart';
import 'package:pocket_karcha/data/models/order_model.dart';

/// Cream card with a hairline border — the basic block of every screen.
class CreamCard extends StatelessWidget {
  const CreamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.creamCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? AppColors.creamBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small spaced capitals, e.g. "RECENT ORDERS".
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.color, this.trailing});

  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: color ?? AppColors.inkSoft,
      ),
    );
    if (trailing == null) return label;
    return Row(children: [Expanded(child: label), trailing!]);
  }
}

/// Tinted label chip ("Confirmed", "Payment pending").
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.fontSize = 11.5,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: foreground,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Colours per order status (left bar, chips, dots).
abstract final class OrderColors {
  static Color bar(OrderStatus s) => switch (s) {
        OrderStatus.pending => AppColors.pending,
        OrderStatus.confirmed => AppColors.brand,
        OrderStatus.dispatched => AppColors.dispatched,
        OrderStatus.delivered => const Color(0xFF6E8F7C),
        OrderStatus.cancelled => AppColors.inkFaint,
      };

  static Color chipBg(OrderStatus s) => switch (s) {
        OrderStatus.pending => AppColors.pendingSoft,
        OrderStatus.confirmed => AppColors.brandSoft,
        OrderStatus.dispatched => AppColors.dispatchedSoft,
        OrderStatus.delivered => const Color(0xFFE8EFEA),
        OrderStatus.cancelled => AppColors.creamDeep,
      };

  static Color chipFg(OrderStatus s) => switch (s) {
        OrderStatus.pending => const Color(0xFFB4650F),
        OrderStatus.confirmed => AppColors.brandDark,
        OrderStatus.dispatched => const Color(0xFF2257B3),
        OrderStatus.delivered => const Color(0xFF4C6B59),
        OrderStatus.cancelled => AppColors.inkSoft,
      };
}

/// Two-option segmented pill ("Orders | Customers").
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.creamBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == index ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: i == index ? Colors.white : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded search box.
class StoreSearchField extends StatelessWidget {
  const StoreSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.inkSoft,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

/// Green pill: − qty +
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => InkResponse(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          radius: 20,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 30,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          btn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

/// Outlined "Add" pill used in product pickers.
class AddPill extends StatelessWidget {
  const AddPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: AppColors.creamCard,
        side: const BorderSide(color: AppColors.creamBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Icon + title + body, for empty lists.
class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppColors.brand, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.display(size: 19),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Serif section heading with a tinted icon box ("How customers send").
class SerifSectionHeader extends StatelessWidget {
  const SerifSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.brandDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.display(size: 17.5)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Title + subtitle + switch row.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.brandDark),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Number field with the currency symbol in front.
class MoneyInput extends StatelessWidget {
  const MoneyInput({
    super.key,
    required this.controller,
    required this.symbol,
    this.hint,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.dense = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String symbol;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool dense;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: TextStyle(fontSize: dense ? 14 : 15.5, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        isDense: dense,
        prefixText: '$symbol ',
        prefixStyle: const TextStyle(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : null,
      ),
    );
  }
}

/// Small label above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: trailing == null
          ? label
          : Row(children: [Expanded(child: label), trailing!]),
    );
  }
}

/// Equal-width option buttons (Pickup | Delivery, Cash | Online | Other).
class ChoicePills<T> extends StatelessWidget {
  const ChoicePills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
    this.iconOf,
    this.dense = false,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: i == options.length - 1 ? 0 : 8,
              ),
              child: _pill(options[i]),
            ),
          ),
      ],
    );
  }

  Widget _pill(T option) {
    final sel = option == selected;
    final fg = sel ? AppColors.brandDark : AppColors.ink;
    return Material(
      color: sel ? AppColors.brandSoft : AppColors.creamCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: sel ? AppColors.brand : AppColors.creamBorder,
          width: sel ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onSelected(option),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 9 : 12, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconOf != null) ...[
                Icon(
                  iconOf!(option),
                  size: 18,
                  color: sel ? AppColors.brandDark : AppColors.inkSoft,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  labelOf(option),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dense ? 13 : 14,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-square initial for a person or store.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final initial = t.isEmpty ? '?' : t.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.brandDark,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D2C4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Cream bottom sheet with grabber + optional title; follows the keyboard.
Future<T?> showCreamSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Text(title, style: AppFonts.display(size: 20)),
              ),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

/// Yes / no sheet. Returns true when confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showCreamSheet<bool>(
    context,
    title: title,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            body,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        destructive ? AppColors.danger : AppColors.brand,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
