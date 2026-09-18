import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/budget.dart';
import 'package:sqflite/sqflite.dart';

class BudgetDao {
  BudgetDao(this._db);

  final AppDatabase _db;

  Future<List<Budget>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('budgets', orderBy: 'id ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getById(int id) async {
    final db = await _db.database;
    final rows =
        await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<int> insert(Budget budget, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db.database;
    return db.insert('budgets', budget.toMap());
  }

  Future<void> update(Budget budget) async {
    final db = await _db.database;
    await db
        .update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM budgets'));
    return result ?? 0;
  }
}
