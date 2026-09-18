import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/transaction_dao.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:flutter/foundation.dart';

/// Owns the 明细 tab state: selected month, active filter and the resulting
/// transaction list.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider({TransactionDao? dao})
      : _dao = dao ?? TransactionDao(AppDatabase.instance);

  final TransactionDao _dao;

  DateTime _selectedMonth = DateX.startOfMonth(DateTime.now());
  TxFilter _filter = const TxFilter();
  List<TxRecord> _monthRecords = const [];
  List<TxRecord> _records = const [];
  bool _loading = false;
  bool _selectionActive = false;

  DateTime get selectedMonth => _selectedMonth;
  TxFilter get filter => _filter;
  bool get loading => _loading;

  /// True while the detail list is in multi-select mode, so the shell can hide
  /// the floating action button.
  bool get selectionActive => _selectionActive;

  void setSelectionActive(bool value) {
    if (_selectionActive == value) return;
    _selectionActive = value;
    notifyListeners();
  }

  /// All entries of the selected month, ignoring the filter (overview cards).
  List<TxRecord> get monthRecords => _monthRecords;

  /// Entries of the selected month after applying the filter (list).
  List<TxRecord> get records => _records;

  DateTime get monthStart => _selectedMonth;
  DateTime get monthEndExclusive => DateX.endOfMonthExclusive(_selectedMonth);

  int get monthExpenseCents => _monthRecords
      .where((t) => t.type == TxType.expense)
      .fold(0, (sum, t) => sum + t.amountCents);

  int get monthIncomeCents => _monthRecords
      .where((t) => t.type == TxType.income)
      .fold(0, (sum, t) => sum + t.amountCents);

  int get monthBalanceCents => monthIncomeCents - monthExpenseCents;

  /// Date string -> records, preserving the DAO's date-descending order.
  Map<String, List<TxRecord>> get groupedByDate {
    final grouped = <String, List<TxRecord>>{};
    for (final record in _records) {
      grouped.putIfAbsent(record.date, () => []).add(record);
    }
    return grouped;
  }

  int dayExpenseCents(Iterable<TxRecord> items) => items
      .where((t) => t.type == TxType.expense)
      .fold(0, (sum, t) => sum + t.amountCents);

  int dayIncomeCents(Iterable<TxRecord> items) => items
      .where((t) => t.type == TxType.income)
      .fold(0, (sum, t) => sum + t.amountCents);

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final monthFilter = TxFilter(
      startDate: DateX.toDateString(monthStart),
      endDate: DateX.toDateString(
          DateTime(monthEndExclusive.year, monthEndExclusive.month, 0)),
    );
    _monthRecords = await _dao.query(monthFilter);

    final scoped = _filter.copyWith(
      startDate: monthFilter.startDate,
      endDate: monthFilter.endDate,
    );
    _records = await _dao.query(scoped);

    _loading = false;
    notifyListeners();
  }

  Future<void> setMonth(DateTime month) async {
    _selectedMonth = DateX.startOfMonth(month);
    await load();
  }

  Future<void> previousMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    await load();
  }

  Future<void> nextMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    await load();
  }

  Future<void> setFilter(TxFilter filter) async {
    _filter = filter;
    await load();
  }

  Future<void> clearFilter() async {
    _filter = const TxFilter();
    await load();
  }

  Future<int> save(TxRecord record) async {
    final id = await _dao.insert(record);
    await load();
    return id;
  }

  Future<void> update(TxRecord record) async {
    await _dao.update(record);
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.softDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _dao.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _dao.hardDelete(id);
    await load();
  }

  Future<void> deleteMany(Iterable<int> ids) async {
    await _dao.softDeleteMany(ids);
    await load();
  }

  Future<void> updateCategoryMany(Iterable<int> ids, int? categoryId) async {
    await _dao.updateCategoryMany(ids, categoryId);
    await load();
  }

  // ------------------------------------------------------------- statistics

  /// Runs an arbitrary query without mutating the detail-tab state.
  Future<List<TxRecord>> search(TxFilter filter,
      {bool includeDeleted = false}) {
    return _dao.query(filter, includeDeleted: includeDeleted);
  }

  Future<List<TxRecord>> allRecords({bool includeDeleted = false}) =>
      _dao.all(includeDeleted: includeDeleted);

  Future<TxRecord?> findById(int id) => _dao.getById(id);
}
