import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/saved_filter.dart';
import 'package:sqflite/sqflite.dart';

class SavedFilterDao {
  SavedFilterDao(this._db);

  final AppDatabase _db;

  Future<List<SavedFilter>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('saved_filters', orderBy: 'id ASC');
    return rows.map(SavedFilter.fromMap).toList();
  }

  Future<int> insert(SavedFilter filter, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db.database;
    return db.insert('saved_filters', filter.toMap());
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('saved_filters', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM saved_filters'));
    return result ?? 0;
  }
}
