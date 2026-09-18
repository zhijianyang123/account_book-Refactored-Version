import 'package:account_new/utils/calculator.dart';
import 'package:flutter/material.dart';

/// 4×4 amount keypad with live calculation.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    this.calculatorEnabled = true,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final bool calculatorEnabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget cell(String label, {VoidCallback? onTap, bool isOperator = false}) {
      final enabled = !isOperator || calculatorEnabled;
      return Expanded(
        child: InkWell(
          onTap: enabled ? (onTap ?? () => onKey(label)) : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isOperator ? 22 : 23,
                  fontWeight: isOperator ? FontWeight.w600 : FontWeight.w400,
                  color: isOperator
                      ? (enabled ? scheme.primary : scheme.outline)
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) => Row(children: children);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            row([
              cell('7'),
              cell('8'),
              cell('9'),
              Expanded(
                child: InkWell(
                  onTap: onBackspace,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 54,
                    child: Icon(Icons.backspace_outlined,
                        size: 21, color: scheme.outline),
                  ),
                ),
              ),
            ]),
            row([
              cell('4'),
              cell('5'),
              cell('6'),
              cell('+', isOperator: true),
            ]),
            row([
              cell('1'),
              cell('2'),
              cell('3'),
              cell('-', isOperator: true),
            ]),
            row([
              cell('.'),
              cell('0'),
              cell(Calculator.multiply, isOperator: true),
              cell(Calculator.divide, isOperator: true),
            ]),
          ],
        ),
      ),
    );
  }
}
