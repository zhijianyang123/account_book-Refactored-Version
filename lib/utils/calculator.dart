/// Tiny left-to-right expression evaluator for the amount keypad.
///
/// Supports `+ - * /` with `*` and `/` taking precedence over `+` and `-`.
/// Input is expected to come from button presses, so malformed expressions
/// simply return null instead of throwing.
class Calculator {
  Calculator._();

  static const String multiply = '×';
  static const String divide = '÷';

  static bool isOperator(String ch) =>
      ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == multiply || ch == divide;

  /// Evaluates [expression], returning null when incomplete or invalid.
  static double? evaluate(String expression) {
    final input = expression.trim();
    if (input.isEmpty) return null;
    if (isOperator(input[input.length - 1])) return null;

    final normalized =
        input.replaceAll(multiply, '*').replaceAll(divide, '/');

    final tokens = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      if (isOperator(ch)) {
        if (buffer.isEmpty) return null;
        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(ch);
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isEmpty) return null;
    tokens.add(buffer.toString());

    // First pass: * and /
    final reduced = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token == '*' || token == '/') {
        if (reduced.isEmpty) return null;
        final left = double.tryParse(reduced.removeLast());
        if (left == null || i + 1 >= tokens.length) return null;
        final right = double.tryParse(tokens[++i]);
        if (right == null) return null;
        if (token == '/' && right == 0) return null;
        reduced.add((token == '*' ? left * right : left / right).toString());
      } else {
        reduced.add(token);
      }
    }

    // Second pass: + and -
    var result = double.tryParse(reduced.first);
    if (result == null) return null;
    for (var i = 1; i < reduced.length; i += 2) {
      final op = reduced[i];
      if (i + 1 >= reduced.length) return null;
      final right = double.tryParse(reduced[i + 1]);
      if (right == null) return null;
      result = op == '+' ? result! + right : result! - right;
    }
    return result;
  }

  /// Formats a computed value without trailing zeros: 20.0 -> "20", 12.5 -> "12.5".
  static String format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    var text = value.toStringAsFixed(2);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    return text;
  }

  /// Converts an expression result into integer cents.
  static int? toCents(String expression) {
    final value = evaluate(expression);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return (value * 100).round();
  }
}
