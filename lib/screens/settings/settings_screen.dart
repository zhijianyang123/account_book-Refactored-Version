import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/screens/settings/about_screen.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<T?> _pickOption<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T current,
  }) {
    return showImmersiveSheet<T>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf(option)),
                trailing: option == current
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickColor(BuildContext context, int current) {
    return showImmersiveSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).t('settings_color_scheme'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final raw in Defaults.colorPalette)
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () =>
                          Navigator.of(sheetContext).pop(int.parse(raw)),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse(raw)),
                          shape: BoxShape.circle,
                          border: current == int.parse(raw)
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  width: 3)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          _section(t.t('settings_general'), scheme),
          _card([
            _optionRow(context, t.t('settings_theme'),
                _themeLabel(t, settings.themeMode), () async {
              final value = await _pickOption<String>(
                context,
                title: t.t('settings_theme'),
                options: const ['system', 'light', 'dark'],
                labelOf: (e) => _themeLabel(t, e),
                current: settings.themeMode,
              );
              if (value != null) await provider.setThemeMode(value);
            }),
            _optionRow(context, t.t('settings_language'),
                _localeLabel(t, settings.locale), () async {
              final value = await _pickOption<String>(
                context,
                title: t.t('settings_language'),
                options: const ['zh', 'en'],
                labelOf: (e) => _localeLabel(t, e),
                current: settings.locale,
              );
              if (value != null) await provider.setLocale(value);
            }),
            _optionRow(
                context,
                t.t('settings_first_weekday'),
                settings.firstWeekday == 7
                    ? t.t('settings_weekday_sun')
                    : t.t('settings_weekday_mon'), () async {
              final value = await _pickOption<int>(
                context,
                title: t.t('settings_first_weekday'),
                options: const [1, 7],
                labelOf: (e) => e == 7
                    ? t.t('settings_weekday_sun')
                    : t.t('settings_weekday_mon'),
                current: settings.firstWeekday,
              );
              if (value != null) {
                await provider.setFirstWeekday(value);
                if (context.mounted) {
                  await context
                      .read<StatsProvider>()
                      .load(firstWeekday: value);
                }
              }
            }),
            _optionRow(
                context,
                t.t('settings_default_type'),
                settings.defaultTxType == TxType.income
                    ? t.t('type_income')
                    : t.t('type_expense'), () async {
              final value = await _pickOption<String>(
                context,
                title: t.t('settings_default_type'),
                options: const [TxType.expense, TxType.income],
                labelOf: (e) => e == TxType.income
                    ? t.t('type_income')
                    : t.t('type_expense'),
                current: settings.defaultTxType,
              );
              if (value != null) await provider.setDefaultTxType(value);
            }),
          ]),
          _section(t.t('settings_recording'), scheme),
          _card([
            _switchRow(context, t.t('settings_save_and_continue'),
                settings.saveAndContinue, provider.setSaveAndContinue),
            _switchRow(context, t.t('settings_calculator'),
                settings.calculatorEnabled, provider.setCalculatorEnabled),
            _switchRow(context, t.t('settings_auto_zero'), settings.autoZero,
                provider.setAutoZero),
          ]),
          _section(t.t('settings_color_scheme'), scheme),
          _card([
            _colorRow(context, t.t('settings_expense_color'),
                Color(settings.expenseColor), () async {
              final value = await _pickColor(context, settings.expenseColor);
              if (value != null) await provider.setExpenseColor(value);
            }),
            _colorRow(context, t.t('settings_income_color'),
                Color(settings.incomeColor), () async {
              final value = await _pickColor(context, settings.incomeColor);
              if (value != null) await provider.setIncomeColor(value);
            }),
          ]),
          _section(t.t('settings_about_group'), scheme),
          _card([
            ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: Text(t.t('settings_about_row')),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(left: 6, top: 16, bottom: 6),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant)),
      );

  Widget _card(List<Widget> children) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(indent: 16, endIndent: 16),
            ],
          ],
        ),
      );

  Widget _optionRow(
      BuildContext context, String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _switchRow(BuildContext context, String label, bool value,
      Future<void> Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (v) => onChanged(v),
    );
  }

  Widget _colorRow(BuildContext context, String label, Color color,
      VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  String _themeLabel(AppLocalizations t, String mode) {
    switch (mode) {
      case 'light':
        return t.t('settings_theme_light');
      case 'dark':
        return t.t('settings_theme_dark');
      default:
        return t.t('settings_theme_system');
    }
  }

  String _localeLabel(AppLocalizations t, String locale) =>
      locale == 'en' ? t.t('settings_lang_en') : t.t('settings_lang_zh');
}
