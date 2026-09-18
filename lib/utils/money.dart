import 'package:intl/intl.dart';

/// Money is always stored as integer cents. These helpers only format/parse.
class Money {
  Money._();

  static const Map<String, String> currencySymbols = {
    'CNY': '¥',
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'GBP': '£',
    'HKD': 'HK\$',
  };

  /// Kept in sync with the user's currency setting by [SettingsProvider].
  static String defaultCurrency = 'CNY';

  static String symbol(String currency) =>
      currencySymbols[currency] ?? currency;

  static final NumberFormat _grouped = NumberFormat('#,##0.00');

  /// 123456 -> "1,234.56"
  static String centsToPlain(int cents) =>
      _grouped.format(cents.abs() / 100.0);

  /// 123456 -> "¥1,234.56"
  static String format(int cents, {String? currency}) =>
      '${symbol(currency ?? defaultCurrency)}${centsToPlain(cents)}';

  /// Signed variant, useful for balances: 123456 -> "+¥1,234.56"
  static String formatSigned(int cents, {String? currency}) {
    final sign = cents > 0 ? '+' : (cents < 0 ? '-' : '');
    return '$sign${symbol(currency ?? defaultCurrency)}${centsToPlain(cents)}';
  }

  /// Negative-aware format for balances/assets: -123456 -> "-¥1,234.56".
  static String formatBalance(int cents, {String? currency}) {
    if (cents < 0) return '-${format(-cents, currency: currency)}';
    return format(cents, currency: currency);
  }

  /// Parses user input ("12.3", "12.30", "1,200") into cents.
  static int? parseToCents(String input) {
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return (value * 100).round();
  }

  static int centsFromAmount(double amount) => (amount * 100).round();

  static double centsToAmount(int cents) => cents / 100.0;
}
