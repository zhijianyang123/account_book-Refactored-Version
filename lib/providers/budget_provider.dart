import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/budget_dao.dart';
import 'package:account_new/db/transaction_dao.dart';
import 'package:account_new/models/budget.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:flutter/foundation.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetProvider({BudgetDao? dao, TransactionDao? txDao})
      : _dao = dao ?? BudgetDao(AppDatabase.instance),
        _txDao = txDao ?? TransactionDao(AppDatabase.instance);

  final BudgetDao _dao;
  final TransactionDao _txDao;

  List<Budget> _budgets = const [];
  final Map<int, int> _usage = <int, int>{};
  bool _loading = false;

  List<Budget> get budgets => _budgets;
  bool get loading => _loading;

  int usageOf(Budget budget) => budget.id == null ? 0 : (_usage[budget.id] ?? 0);

  int remainingOf(Budget budget) => budget.amountCents - usageOf(budget);

  bool overspentOf(Budget budget) => remainingOf(budget) < 0;

  int dailyAvailableOf(Budget budget) {
    final end = DateX.parseDate(budget.endDate);
    final now = DateTime.now();
    if (now.isAfter(end)) return remainingOf(budget);
    final days = end.difference(DateX.startOfDay(now)).inDays + 1;
    if (days <= 0) return remainingOf(budget);
    return remainingOf(budget) ~/ days;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _budgets = await _dao.getAll();
    await _computeUsage();
    _loading = false;
    notifyListeners();
  }

  Future<void> _computeUsage() async {
    _usage.clear();
    for (final budget in _budgets) {
      final start = DateX.parseDate(budget.startDate);
      final end = DateX.parseDate(budget.endDate);
      final items = await _txDao.query(TxFilter(
        types: const {TxType.expense},
        startDate: DateX.toDateString(start),
        endDate: DateX.toDateString(end),
        categoryIds: budget.categoryId == null
            ? const <int>{}
            : {budget.categoryId!},
      ));
      final used = items.fold<int>(0, (sum, tx) => sum + tx.amountCents);
      _usage[budget.id!] = used;
    }
  }

  Future<int> add(Budget budget) async {
    final id = await _dao.insert(budget);
    await load();
    return id;
  }

  Future<void> update(Budget budget) async {
    await _dao.update(budget);
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    await load();
  }

  Budget? get currentMonthBudget => _firstWhereOrNull(
      (b) => b.categoryId == null && b.periodType == BudgetPeriod.month);

  Budget? get currentYearBudget => _firstWhereOrNull(
      (b) => b.categoryId == null && b.periodType == BudgetPeriod.year);

  List<Budget> get categoryBudgets =>
      _budgets.where((b) => b.categoryId != null).toList();

  Budget? _firstWhereOrNull(bool Function(Budget) test) {
    for (final budget in _budgets) {
      if (test(budget)) return budget;
    }
    return null;
  }
}
