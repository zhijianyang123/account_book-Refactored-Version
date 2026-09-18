import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/category_dao.dart';
import 'package:account_new/models/category.dart';
import 'package:account_new/utils/constants.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({CategoryDao? dao})
      : _dao = dao ?? CategoryDao(AppDatabase.instance);

  final CategoryDao _dao;

  List<Category> _categories = const [];
  bool _loading = false;

  List<Category> get categories => _categories;
  bool get loading => _loading;

  List<Category> get expense =>
      _categories.where((c) => c.type == TxType.expense).toList();

  List<Category> get income =>
      _categories.where((c) => c.type == TxType.income).toList();

  List<Category> byType(String type) =>
      _categories.where((c) => c.type == type).toList();

  List<Category> byTypeVisible(String type) => _categories
      .where((c) => c.type == type && !c.isHidden && c.parentId == null)
      .toList();

  List<Category> childrenOf(int parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  Map<int, Category> get byId =>
      {for (final c in _categories) if (c.id != null) c.id!: c};

  Category? find(int? id) => id == null ? null : byId[id];

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _categories = await _dao.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<int> add(Category category) async {
    final id = await _dao.insert(category);
    await load();
    return id;
  }

  Future<void> update(Category category) async {
    await _dao.update(category);
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    await load();
  }

  Future<void> reorder(List<Category> ordered) async {
    await _dao.updateSortOrders(ordered);
    await load();
  }
}
