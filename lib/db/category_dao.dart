import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/category.dart';
import 'package:account_new/utils/constants.dart';
import 'package:sqflite/sqflite.dart';

class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<List<Category>> getAll({String? type, bool includeHidden = true}) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (!includeHidden) {
      where.add('is_hidden = 0');
    }
    final rows = await db.query(
      'categories',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category?> findByName(String name, String type) async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> insert(Category category, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db.database;
    return db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    final db = await _db.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  /// Deletes the category and detaches it from any transaction (sets NULL so
  /// the entry falls back to "无类型").
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('transactions', {'category_id': null},
          where: 'category_id = ?', whereArgs: [id]);
      await txn.update('categories', {'parent_id': null},
          where: 'parent_id = ?', whereArgs: [id]);
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> updateSortOrders(List<Category> ordered) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var i = 0; i < ordered.length; i++) {
        final c = ordered[i];
        await txn.update('categories', {'sort_order': i},
            where: 'id = ?', whereArgs: [c.id]);
      }
    });
  }

  Future<Map<int, String>> nameMap() async {
    final all = await getAll();
    return {for (final c in all) c.id!: c.name};
  }

  Future<List<Category>> childrenOf(int parentId) async {
    final db = await _db.database;
    final rows = await db.query('categories',
        where: 'parent_id = ?', whereArgs: [parentId], orderBy: 'sort_order ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories'));
    return result ?? 0;
  }

  Future<void> ensureDefaults() async {
    final existing = await getAll();
    final expense = existing.where((c) => c.type == TxType.expense).length;
    if (expense > 0) return;
    var order = existing.length;
    for (final c in Defaults.allCategories) {
      await insert(Category(
        name: c.name,
        type: c.type,
        icon: c.icon,
        color: c.color,
        sortOrder: order++,
        isDefault: true,
      ));
    }
  }
}
