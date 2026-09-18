import 'package:intl/intl.dart';

/// Date helpers. Dates are persisted as `yyyy-MM-dd`, times as `HH:mm`.
class DateX {
  DateX._();

  static final DateFormat dateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat timeFmt = DateFormat('HH:mm');
  static final DateFormat fileStampFmt = DateFormat('yyyyMMdd_HHmmss');

  static const List<String> _monthEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdayZh = ['一', '二', '三', '四', '五', '六', '日'];
  static const List<String> _weekdayEn = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static String toDateString(DateTime d) => dateFmt.format(d);
  static String toTimeString(DateTime d) => timeFmt.format(d);
  static String fileTimestamp(DateTime d) => fileStampFmt.format(d);

  static DateTime parseDate(String value) =>
      DateTime.tryParse(value) ?? DateTime(1970, 1, 1);

  static DateTime? tryParseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime endOfMonthExclusive(DateTime d) =>
      DateTime(d.year, d.month + 1, 1);

  static DateTime startOfWeek(DateTime d, {int firstWeekday = 1}) {
    final day = startOfDay(d);
    final delta = (day.weekday - firstWeekday + 7) % 7;
    return day.subtract(Duration(days: delta));
  }

  static DateTime startOfYear(DateTime d) => DateTime(d.year, 1, 1);

  static DateTime endOfYearExclusive(DateTime d) => DateTime(d.year + 1, 1, 1);

  /// Left-closed right-open [start, end) check.
  static bool inRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);

  static String monthLabel(DateTime d, String locale) => locale == 'en'
      ? '${_monthEn[d.month - 1]} ${d.year}'
      : '${d.year}年${d.month}月';

  static String dayLabel(DateTime d, String locale) => locale == 'en'
      ? '${_weekdayEn[d.weekday - 1]}, ${_monthEn[d.month - 1]} ${d.day}'
      : '${d.month}月${d.day}日 周${_weekdayZh[d.weekday - 1]}';

  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  static int remainingDaysInMonth(DateTime d) =>
      daysInMonth(d) - d.day + 1;
}
