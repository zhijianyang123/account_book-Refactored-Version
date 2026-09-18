import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/settings_dao.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/utils/money.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsDao? dao})
      : _dao = dao ?? SettingsDao(AppDatabase.instance);

  final SettingsDao _dao;

  AppSettings _settings = AppSettings.fromMap(const {});
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await _dao.load();
    Money.defaultCurrency = _settings.currency;
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(Map<String, String> patch) async {
    await _dao.putAll(patch);
    _settings = _settings.copyWith(patch);
    Money.defaultCurrency = _settings.currency;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) => update({'theme_mode': mode});

  Future<void> setLocale(String locale) => update({'locale': locale});

  Future<void> setFirstWeekday(int weekday) =>
      update({'first_weekday': '$weekday'});

  Future<void> setDefaultTxType(String type) =>
      update({'default_tx_type': type});

  Future<void> setSaveAndContinue(bool value) =>
      update({'save_and_continue': value ? 'true' : 'false'});

  Future<void> setCalculatorEnabled(bool value) =>
      update({'calculator_enabled': value ? 'true' : 'false'});

  Future<void> setAutoZero(bool value) =>
      update({'auto_zero': value ? 'true' : 'false'});

  Future<void> setExpenseColor(int color) =>
      update({'expense_color': '$color'});

  Future<void> setIncomeColor(int color) => update({'income_color': '$color'});

  Future<void> replaceAll(Map<String, String> values) async {
    await _dao.putAll(values);
    _settings = AppSettings.fromMap(values);
    Money.defaultCurrency = _settings.currency;
    notifyListeners();
  }
}
