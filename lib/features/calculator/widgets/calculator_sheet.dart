import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/core/l10n/store_strings.dart';
import 'package:pocket_karcha/features/calculator/calc_engine.dart';
import 'package:pocket_karcha/features/calculator/widgets/calc_keypad.dart';
import 'package:pocket_karcha/providers/store_providers.dart';
import 'package:pocket_karcha/shared/widgets/store_ui.dart';

/// Calculator in a sheet for an amount field. Returns the amount to use,
/// or null when closed.
Future<double?> showCalculatorSheet(BuildContext context, {double? initial}) {
  return showCreamSheet<double>(
    context,
    builder: (_) => _CalculatorSheet(initial: initial),
  );
}

class _CalculatorSheet extends ConsumerStatefulWidget {
  const _CalculatorSheet({this.initial});

  final double? initial;

  @override
  ConsumerState<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends ConsumerState<_CalculatorSheet> {
  final _input = CalcInput();

  @override
  void initState() {
    super.initState();
    final start = widget.initial;
    if (start != null && start > 0) _input.setValue(start);
  }

  void _press(String key) {
    if (key == CalcKeypad.equals) {
      final r = _input.result;
      if (r != null) setState(() => _input.setValue(r));
      return;
    }
    setState(() => _input.press(key));
  }

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(storeStringsProvider);
    final money = ref.watch(moneyProvider);
    final raw = _input.result;
    final value = raw == null ? null : CalcEngine.roundMoney(raw);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalcDisplay(input: _input, money: money),
          const SizedBox(height: 12),
          CalcKeypad(onKey: _press, keyHeight: 50),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: value == null || value <= 0
                ? null
                : () => Navigator.of(context).pop(value),
            child: Text(
              value == null || value <= 0
                  ? ss.enterAmount
                  : ss.useAmount(money(value)),
            ),
          ),
        ],
      ),
    );
  }
}
