import 'package:account_new/utils/constants.dart';

/// Typed, immutable view over the `settings` key/value table.
class AppSettings {
  const AppSettings(this._values);

  final Map<String, String> _values;

  static AppSettings fromMap(Map<String, String> values) {
    final merged = Map<String, String>.from(Defaults.defaultSettings)
      ..addAll(values);
    return AppSettings(merged);
  }

  Map<String, String> toMap() => Map<String, String>.from(_values);

  String get themeMode => _values['theme_mode'] ?? 'system';

  String get locale => _values['locale'] ?? 'zh';

  /// The app records in CNY only.
  String get currency => 'CNY';

  int get firstWeekday => int.tryParse(_values['first_weekday'] ?? '1') ?? 1;

  String get defaultTxType => _values['default_tx_type'] ?? TxType.expense;

  bool get saveAndContinue => _values['save_and_continue'] == 'true';

  bool get calculatorEnabled => _values['calculator_enabled'] != 'false';

  bool get autoZero => _values['auto_zero'] == 'true';

  int get expenseColor =>
      int.tryParse(_values['expense_color'] ?? '') ?? Defaults.expenseColor;

  int get incomeColor =>
      int.tryParse(_values['income_color'] ?? '') ?? Defaults.incomeColor;

  AppSettings copyWith(Map<String, String> patch) {
    final next = Map<String, String>.from(_values)..addAll(patch);
    return AppSettings(next);
  }
}
