import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/saved_filter_dao.dart';
import 'package:account_new/models/saved_filter.dart';
import 'package:flutter/foundation.dart';

class SavedFilterProvider extends ChangeNotifier {
  SavedFilterProvider({SavedFilterDao? dao})
      : _dao = dao ?? SavedFilterDao(AppDatabase.instance);

  final SavedFilterDao _dao;

  List<SavedFilter> _filters = const [];
  bool _loading = false;

  List<SavedFilter> get filters => _filters;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _filters = await _dao.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<int> add(SavedFilter filter) async {
    final id = await _dao.insert(filter);
    await load();
    return id;
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    await load();
  }
}
