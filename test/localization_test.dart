import 'package:account_new/l10n/app_localization_delegates.dart';
import 'package:account_new/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the slimmed-down localization delegates: they must resolve Material
/// and Widgets localizations for both supported locales and still format dates
/// (which relies on the initialized `intl` data).
void main() {
  Future<BuildContext> pumpApp(WidgetTester tester, String languageCode) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(languageCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          AppMaterialLocalizationsDelegate(),
          AppWidgetsLocalizationsDelegate(),
          AppCupertinoLocalizationsDelegate(),
        ],
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // AppLocalizations.delegate.load is async, so let the localizations
    // future resolve before reading it back.
    await tester.pump();
    return captured;
  }

  testWidgets('resolves material + widgets localizations for zh and en',
      (tester) async {
    for (final code in ['zh', 'en']) {
      final context = await pumpApp(tester, code);

      final material = MaterialLocalizations.of(context);
      final widgets = WidgetsLocalizations.of(context);

      expect(material.cancelButtonLabel, isNotEmpty);
      expect(material.okButtonLabel, isNotEmpty);
      expect(widgets.textDirection, TextDirection.ltr);

      // Date formatting must not throw, which proves the intl date data needed
      // by the trimmed delegate is initialized.
      expect(material.formatShortDate(DateTime(2026, 3, 4)), isNotEmpty);
      expect(material.formatMonthYear(DateTime(2026, 3, 4)), isNotEmpty);
    }
  });

  testWidgets('zh resolves to the Chinese bundle', (tester) async {
    final context = await pumpApp(tester, 'zh');
    expect(MaterialLocalizations.of(context), isA<MaterialLocalizationZh>());
  });

  testWidgets('en resolves to the English bundle', (tester) async {
    final context = await pumpApp(tester, 'en');
    expect(MaterialLocalizations.of(context), isA<MaterialLocalizationEn>());
  });

  test('delegates reject unsupported locales', () {
    const material = AppMaterialLocalizationsDelegate();
    const widgets = AppWidgetsLocalizationsDelegate();
    expect(material.isSupported(const Locale('zh')), isTrue);
    expect(material.isSupported(const Locale('en')), isTrue);
    expect(material.isSupported(const Locale('fr')), isFalse);
    expect(widgets.isSupported(const Locale('fr')), isFalse);
  });
}
