import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// The app ships only English and Simplified Chinese, so this file intentionally
// references only those two generated translation bundles. Because the default
// [GlobalMaterialLocalizations] / [GlobalWidgetsLocalizations] delegates keep a
// reference to *every* language bundle, the Dart AOT compiler cannot drop the
// ~110 unused ones. Referencing just en/zh here lets the tree shaker remove
// them, shrinking the release APK without changing behaviour for the locales
// the app actually supports.
// ignore: implementation_imports
import 'package:flutter_localizations/src/utils/date_localizations.dart'
    as flutter_date;
import 'package:intl/intl.dart' as intl;

/// [MaterialLocalizations] limited to the app's supported locales (en, zh).
///
/// Drop-in replacement for [GlobalMaterialLocalizations.delegate] that keeps
/// only the English and Simplified Chinese bundles.
class AppMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AppMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    flutter_date.loadDateIntlDataIfNotLoaded();

    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    intl.DateFormat fullYearFormat;
    intl.DateFormat compactDateFormat;
    intl.DateFormat shortDateFormat;
    intl.DateFormat mediumDateFormat;
    intl.DateFormat longDateFormat;
    intl.DateFormat yearMonthFormat;
    intl.DateFormat shortMonthDayFormat;
    if (intl.DateFormat.localeExists(localeName)) {
      fullYearFormat = intl.DateFormat.y(localeName);
      compactDateFormat = intl.DateFormat.yMd(localeName);
      shortDateFormat = intl.DateFormat.yMMMd(localeName);
      mediumDateFormat = intl.DateFormat.MMMEd(localeName);
      longDateFormat = intl.DateFormat.yMMMMEEEEd(localeName);
      yearMonthFormat = intl.DateFormat.yMMMM(localeName);
      shortMonthDayFormat = intl.DateFormat.MMMd(localeName);
    } else if (intl.DateFormat.localeExists(locale.languageCode)) {
      fullYearFormat = intl.DateFormat.y(locale.languageCode);
      compactDateFormat = intl.DateFormat.yMd(locale.languageCode);
      shortDateFormat = intl.DateFormat.yMMMd(locale.languageCode);
      mediumDateFormat = intl.DateFormat.MMMEd(locale.languageCode);
      longDateFormat = intl.DateFormat.yMMMMEEEEd(locale.languageCode);
      yearMonthFormat = intl.DateFormat.yMMMM(locale.languageCode);
      shortMonthDayFormat = intl.DateFormat.MMMd(locale.languageCode);
    } else {
      fullYearFormat = intl.DateFormat.y();
      compactDateFormat = intl.DateFormat.yMd();
      shortDateFormat = intl.DateFormat.yMMMd();
      mediumDateFormat = intl.DateFormat.MMMEd();
      longDateFormat = intl.DateFormat.yMMMMEEEEd();
      yearMonthFormat = intl.DateFormat.yMMMM();
      shortMonthDayFormat = intl.DateFormat.MMMd();
    }

    intl.NumberFormat decimalFormat;
    intl.NumberFormat twoDigitZeroPaddedFormat;
    if (intl.NumberFormat.localeExists(localeName)) {
      decimalFormat = intl.NumberFormat.decimalPattern(localeName);
      twoDigitZeroPaddedFormat = intl.NumberFormat('00', localeName);
    } else if (intl.NumberFormat.localeExists(locale.languageCode)) {
      decimalFormat = intl.NumberFormat.decimalPattern(locale.languageCode);
      twoDigitZeroPaddedFormat =
          intl.NumberFormat('00', locale.languageCode);
    } else {
      decimalFormat = intl.NumberFormat.decimalPattern();
      twoDigitZeroPaddedFormat = intl.NumberFormat('00');
    }

    final MaterialLocalizations bundle = locale.languageCode == 'zh'
        ? MaterialLocalizationZh(
            localeName: localeName,
            fullYearFormat: fullYearFormat,
            compactDateFormat: compactDateFormat,
            shortDateFormat: shortDateFormat,
            mediumDateFormat: mediumDateFormat,
            longDateFormat: longDateFormat,
            yearMonthFormat: yearMonthFormat,
            shortMonthDayFormat: shortMonthDayFormat,
            decimalFormat: decimalFormat,
            twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat,
          )
        : MaterialLocalizationEn(
            localeName: localeName,
            fullYearFormat: fullYearFormat,
            compactDateFormat: compactDateFormat,
            shortDateFormat: shortDateFormat,
            mediumDateFormat: mediumDateFormat,
            longDateFormat: longDateFormat,
            yearMonthFormat: yearMonthFormat,
            shortMonthDayFormat: shortMonthDayFormat,
            decimalFormat: decimalFormat,
            twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat,
          );

    return SynchronousFuture<MaterialLocalizations>(bundle);
  }

  @override
  bool shouldReload(AppMaterialLocalizationsDelegate old) => false;
}

/// [WidgetsLocalizations] limited to the app's supported locales (en, zh).
class AppWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const AppWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' ||
      locale.languageCode == 'zh';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(
        locale.languageCode == 'zh'
            ? const WidgetsLocalizationZh()
            : const WidgetsLocalizationEn(),
      );

  @override
  bool shouldReload(AppWidgetsLocalizationsDelegate old) => false;
}

/// [CupertinoLocalizations] limited to the app's supported locales (en, zh).
///
/// The app is Material-only, but `MaterialApp` still resolves
/// [CupertinoLocalizations] and warns when no delegate supports the locale, so
/// this provides the same en/zh-only bundle.
class AppCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const AppCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' ||
      locale.languageCode == 'zh';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    flutter_date.loadDateIntlDataIfNotLoaded();

    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());

    late intl.DateFormat fullYearFormat;
    late intl.DateFormat dayFormat;
    late intl.DateFormat weekdayFormat;
    late intl.DateFormat mediumDateFormat;
    late intl.DateFormat singleDigitHourFormat;
    late intl.DateFormat singleDigitMinuteFormat;
    late intl.DateFormat doubleDigitMinuteFormat;
    late intl.DateFormat singleDigitSecondFormat;
    late intl.NumberFormat decimalFormat;

    void loadFormats(String? locale) {
      fullYearFormat = intl.DateFormat.y(locale);
      dayFormat = intl.DateFormat.d(locale);
      weekdayFormat = intl.DateFormat.E(locale);
      mediumDateFormat = intl.DateFormat.MMMEd(locale);
      // Round hour numbers are handled by the date picker, so no AM/PM here.
      singleDigitHourFormat = intl.DateFormat('HH', locale);
      singleDigitMinuteFormat = intl.DateFormat.m(locale);
      doubleDigitMinuteFormat = intl.DateFormat('mm', locale);
      singleDigitSecondFormat = intl.DateFormat.s(locale);
      decimalFormat = intl.NumberFormat.decimalPattern(locale);
    }

    if (intl.DateFormat.localeExists(localeName)) {
      loadFormats(localeName);
    } else if (intl.DateFormat.localeExists(locale.languageCode)) {
      loadFormats(locale.languageCode);
    } else {
      loadFormats(null);
    }

    final CupertinoLocalizations bundle = locale.languageCode == 'zh'
        ? CupertinoLocalizationZh(
            localeName: localeName,
            fullYearFormat: fullYearFormat,
            dayFormat: dayFormat,
            weekdayFormat: weekdayFormat,
            mediumDateFormat: mediumDateFormat,
            singleDigitHourFormat: singleDigitHourFormat,
            singleDigitMinuteFormat: singleDigitMinuteFormat,
            doubleDigitMinuteFormat: doubleDigitMinuteFormat,
            singleDigitSecondFormat: singleDigitSecondFormat,
            decimalFormat: decimalFormat,
          )
        : CupertinoLocalizationEn(
            localeName: localeName,
            fullYearFormat: fullYearFormat,
            dayFormat: dayFormat,
            weekdayFormat: weekdayFormat,
            mediumDateFormat: mediumDateFormat,
            singleDigitHourFormat: singleDigitHourFormat,
            singleDigitMinuteFormat: singleDigitMinuteFormat,
            doubleDigitMinuteFormat: doubleDigitMinuteFormat,
            singleDigitSecondFormat: singleDigitSecondFormat,
            decimalFormat: decimalFormat,
          );

    return SynchronousFuture<CupertinoLocalizations>(bundle);
  }

  @override
  bool shouldReload(AppCupertinoLocalizationsDelegate old) => false;
}
