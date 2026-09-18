import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/budget_dao.dart';
import 'package:account_new/db/category_dao.dart';
import 'package:account_new/db/transaction_dao.dart';
import 'package:account_new/models/budget.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/stats_calculator.dart';
import 'package:flutter/foundation.dart';

class StatsProvider extends ChangeNotifier {
  StatsProvider({
    TransactionDao? txDao,
    CategoryDao? categoryDao,
    BudgetDao? budgetDao,
  })  : _txDao = txDao ?? TransactionDao(AppDatabase.instance),
        _categoryDao = categoryDao ?? CategoryDao(AppDatabase.instance),
        _budgetDao = budgetDao ?? BudgetDao(AppDatabase.instance);

  final TransactionDao _txDao;
  final CategoryDao _categoryDao;
  final BudgetDao _budgetDao;

  static const String week = 'week';
  static const String month = 'month';
  static const String year = 'year';

  String _rangeType = month;
  DateTime _anchor = DateTime.now();
  String _amountType = TxType.expense;
  int _firstWeekday = 1;
  bool _loading = false;
  bool _hasData = false;

  int _incomeCents = 0;
  int _expenseCents = 0;
  List<CategoryStat> _expenseCategories = const [];
  List<CategoryStat> _incomeCategories = const [];
  List<TrendPoint> _trend = const [];
  Budget? _activeBudget;
  int _budgetUsedCents = 0;
  int _currentMonthIncomeCents = 0;
  int _currentMonthExpenseCents = 0;

  String get rangeType => _rangeType;
  DateTime get anchor => _anchor;
  String get amountType => _amountType;
  bool get loading => _loading;

  /// Whether at least one load has completed. Used to avoid replacing the
  /// whole page with a spinner while switching periods.
  bool get hasData => _hasData;

  int get incomeCents => _incomeCents;
  int get expenseCents => _expenseCents;
  int get totalCents =>
      _amountType == TxType.expense ? _expenseCents : _incomeCents;
  List<CategoryStat> get expenseCategories => _expenseCategories;
  List<CategoryStat> get incomeCategories => _incomeCategories;
  List<TrendPoint> get trend => _trend;
  Budget? get activeBudget => _activeBudget;
  int get budgetUsedCents => _budgetUsedCents;
  int get budgetRemainingCents =>
      (_activeBudget?.amountCents ?? 0) - _budgetUsedCents;
  bool get budgetOverspent => _activeBudget != null && budgetRemainingCents < 0;

  int get budgetDailyAvailableCents {
    final budget = _activeBudget;
    if (budget == null) return 0;
    final end = DateX.parseDate(budget.endDate);
    final now = DateTime.now();
    final remainingDays = end.difference(DateX.startOfDay(now)).inDays + 1;
    if (remainingDays <= 0) return budgetRemainingCents;
    return budgetRemainingCents ~/ remainingDays;
  }

  int get currentMonthIncomeCents => _currentMonthIncomeCents;
  int get currentMonthExpenseCents => _currentMonthExpenseCents;
  int get currentMonthBalanceCents =>
      _currentMonthIncomeCents - _currentMonthExpenseCents;

  DateTime get rangeStart {
    switch (_rangeType) {
      case week:
        return DateX.startOfWeek(_anchor, firstWeekday: _firstWeekday);
      case year:
        return DateX.startOfYear(_anchor);
      default:
        return DateX.startOfMonth(_anchor);
    }
  }

  DateTime get rangeEndExclusive {
    switch (_rangeType) {
      case week:
        return rangeStart.add(const Duration(days: 7));
      case year:
        return DateX.endOfYearExclusive(_anchor);
      default:
        return DateX.endOfMonthExclusive(_anchor);
    }
  }

  String get rangeLabel {
    switch (_rangeType) {
      case week:
        final end = rangeEndExclusive.subtract(const Duration(days: 1));
        return '${DateX.toDateString(rangeStart)} ~ ${DateX.toDateString(end)}';
      case year:
        return '${_anchor.year}';
      default:
        return '${_anchor.year}-${_anchor.month.toString().padLeft(2, '0')}';
    }
  }

  List<StatsBucket> get buckets {
    final result = <StatsBucket>[];
    if (_rangeType == year) {
      for (var m = 1; m <= 12; m++) {
        result.add(StatsBucket(
          start: DateTime(_anchor.year, m, 1),
          endExclusive: DateTime(_anchor.year, m + 1, 1),
          label: '$m',
        ));
      }
    } else {
      final end = rangeEndExclusive;
      var cursor = rangeStart;
      while (cursor.isBefore(end)) {
        final next = cursor.add(const Duration(days: 1));
        result.add(StatsBucket(
          start: cursor,
          endExclusive: next,
          label: '${cursor.day}',
        ));
        cursor = next;
      }
    }
    return result;
  }

  Future<void> setRangeType(String type) async {
    _rangeType = type;
    await load();
  }

  Future<void> setAnchor(DateTime anchor) async {
    _anchor = anchor;
    await load();
  }

  Future<void> setAmountType(String type) async {
    if (_amountType == type) return;
    _amountType = type;
    notifyListeners();
  }

  Future<void> previous() async {
    _anchor = _shiftAnchor(-1);
    await load();
  }

  Future<void> next() async {
    _anchor = _shiftAnchor(1);
    await load();
  }

  DateTime _shiftAnchor(int delta) {
    switch (_rangeType) {
      case week:
        return _anchor.add(Duration(days: 7 * delta));
      case year:
        return DateTime(_anchor.year + delta, _anchor.month, 1);
      default:
        return DateTime(_anchor.year, _anchor.month + delta, 1);
    }
  }

  bool get isCurrentPeriod {
    final now = DateTime.now();
    return !now.isBefore(rangeStart) && now.isBefore(rangeEndExclusive);
  }

  Future<void> load({int? firstWeekday}) async {
    if (firstWeekday != null) _firstWeekday = firstWeekday;
    _loading = true;
    notifyListeners();

    final start = rangeStart;
    final end = rangeEndExclusive;
    final endInclusive = end.subtract(const Duration(days: 1));

    final transactions = await _txDao.query(TxFilter(
      startDate: DateX.toDateString(start),
      endDate: DateX.toDateString(endInclusive),
    ));

    var income = 0;
    var expense = 0;
    final expenseTotals = <int?, int>{};
    final incomeTotals = <int?, int>{};

    for (final tx in transactions) {
      if (tx.type == TxType.expense) {
        expense += tx.amountCents;
        expenseTotals.update(tx.categoryId, (v) => v + tx.amountCents,
            ifAbsent: () => tx.amountCents);
      } else {
        income += tx.amountCents;
        incomeTotals.update(tx.categoryId, (v) => v + tx.amountCents,
            ifAbsent: () => tx.amountCents);
      }
    }

    _incomeCents = income;
    _expenseCents = expense;

    final categoryNames = {
      for (final c in await _categoryDao.getAll()) c.id!: c.name,
    };
    _expenseCategories = _toSortedStats(expenseTotals, categoryNames);
    _incomeCategories = _toSortedStats(incomeTotals, categoryNames);

    _trend = _buildTrend(transactions);
    await _loadBudgetUsage();
    await _loadCurrentMonth();

    _loading = false;
    _hasData = true;
    notifyListeners();
  }

  List<CategoryStat> _toSortedStats(
    Map<int?, int> totals,
    Map<int, String> names,
  ) {
    final list = totals.entries
        .map((e) => CategoryStat(
              id: e.key,
              name: e.key == null ? '' : (names[e.key] ?? ''),
              amountCents: e.value,
            ))
        .toList()
      ..sort((a, b) => b.amountCents.compareTo(a.amountCents));
    return list;
  }

  List<TrendPoint> _buildTrend(List<TxRecord> transactions) {
    final result = <TrendPoint>[];
    for (final bucket in buckets) {
      var income = 0;
      var expense = 0;
      for (final tx in transactions) {
        final date = DateX.parseDate(tx.date);
        if (date.isBefore(bucket.start) || !date.isBefore(bucket.endExclusive)) {
          continue;
        }
        if (tx.type == TxType.expense) {
          expense += tx.amountCents;
        } else {
          income += tx.amountCents;
        }
      }
      result.add(TrendPoint(
        start: bucket.start,
        label: bucket.label,
        incomeCents: income,
        expenseCents: expense,
      ));
    }
    return result;
  }

  Future<void> _loadBudgetUsage() async {
    final budgets = await _budgetDao.getAll();
    final today = DateX.startOfDay(DateTime.now());

    bool covers(Budget budget) {
      final start = DateX.startOfDay(DateX.parseDate(budget.startDate));
      final end = DateX.startOfDay(DateX.parseDate(budget.endDate));
      return !today.isBefore(start) && !today.isAfter(end);
    }

    Budget? selected;
    for (final budget in budgets) {
      if (budget.categoryId == null &&
          budget.periodType == BudgetPeriod.month &&
          covers(budget)) {
        selected = budget;
        break;
      }
    }
    if (selected == null) {
      for (final budget in budgets) {
        if (budget.categoryId == null &&
            budget.periodType == BudgetPeriod.year &&
            covers(budget)) {
          selected = budget;
          break;
        }
      }
    }

    _activeBudget = selected;
    if (selected == null) {
      _budgetUsedCents = 0;
      return;
    }

    final start = DateX.parseDate(selected.startDate);
    final end = DateX.parseDate(selected.endDate).add(const Duration(days: 1));
    final items = await _txDao.query(TxFilter(
      types: const {TxType.expense},
      startDate: DateX.toDateString(start),
      endDate: DateX.toDateString(end.subtract(const Duration(days: 1))),
    ));
    _budgetUsedCents = items.fold<int>(0, (sum, tx) => sum + tx.amountCents);
  }

  Future<void> _loadCurrentMonth() async {
    final start = DateX.startOfMonth(DateTime.now());
    final end = DateX.endOfMonthExclusive(start);
    final items = await _txDao.query(TxFilter(
      startDate: DateX.toDateString(start),
      endDate: DateX.toDateString(end.subtract(const Duration(days: 1))),
    ));
    var income = 0;
    var expense = 0;
    for (final tx in items) {
      if (tx.type == TxType.expense) {
        expense += tx.amountCents;
      } else {
        income += tx.amountCents;
      }
    }
    _currentMonthIncomeCents = income;
    _currentMonthExpenseCents = expense;
  }
}
