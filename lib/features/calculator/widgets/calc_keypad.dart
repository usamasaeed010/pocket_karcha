import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/calculator/calc_engine.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// 5 × 4 calculator keypad. Sends the key text ('7', '+', '⌫', '=', …).
/// Long-press ⌫ clears everything.
class CalcKeypad extends StatelessWidget {
  const CalcKeypad({super.key, required this.onKey, this.keyHeight = 56});

  final ValueChanged<String> onKey;
  final double keyHeight;

  static const equals = '=';

  static const _rows = [
    [CalcInput.clear, CalcInput.backspace, CalcEngine.percent, CalcEngine.divide],
    ['7', '8', '9', CalcEngine.times],
    ['4', '5', '6', CalcEngine.minus],
    ['1', '2', '3', CalcEngine.plus],
    [CalcInput.doubleZero, '0', CalcInput.dot, equals],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Key(label: row[i], height: keyHeight, onKey: onKey),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.height, required this.onKey});

  final String label;
  final double height;
  final ValueChanged<String> onKey;

  bool get _isOp =>
      CalcEngine.isOperator(label) || label == CalcEngine.percent;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (label) {
      CalcKeypad.equals => (AppColors.brand, Colors.white, AppColors.brand),
      CalcInput.clear ||
      CalcInput.backspace =>
        (AppColors.creamDeep, AppColors.ink, AppColors.creamDeep),
      _ when _isOp =>
        (AppColors.brandSoft, AppColors.brandDark, AppColors.brandSoftBorder),
      _ => (AppColors.creamCard, AppColors.ink, AppColors.creamBorder),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: border),
    );
    return Material(
      color: bg,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () {
          HapticFeedback.selectionClick();
          onKey(label);
        },
        onLongPress: label == CalcInput.backspace
            ? () => onKey(CalcInput.clear)
            : null,
        child: SizedBox(
          height: height,
          child: Center(
            child: label == CalcInput.backspace
                ? Icon(Icons.backspace_outlined, color: fg, size: 21)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: _isOp || label == CalcKeypad.equals ? 24 : 21,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// What the user typed, and the live result under it.
class CalcDisplay extends StatelessWidget {
  const CalcDisplay({super.key, required this.input, required this.money});

  final CalcInput input;
  final String Function(num) money;

  @override
  Widget build(BuildContext context) {
    final result = input.result;
    final showResult = input.hasOperation && result != null;
    return CreamCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              input.isEmpty ? '0' : input.text,
              maxLines: 1,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: input.isEmpty ? AppColors.inkFaint : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            showResult ? '= ${money(CalcEngine.roundMoney(result))}' : ' ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}
