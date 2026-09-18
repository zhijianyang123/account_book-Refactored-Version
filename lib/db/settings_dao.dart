import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> raw() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    return {
      for (final row in rows)
        (row['key'] as String): (row['value'] ?? '') as String,
    };
  }

  Future<AppSettings> load() async => AppSettings.fromMap(await raw());

  Future<void> put(String key, String value, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> putAll(Map<String, String> values,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? await _db.database;
    final batch = db.batch();
    values.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  Future<void> delete(String key) async {
    final db = await _db.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
