import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:sqflite/sqflite.dart';

class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- queries

  Future<List<TxRecord>> query(
    TxFilter filter, {
    bool includeDeleted = false,
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) where.add('t.deleted_at IS NULL');

    if (filter.types.isNotEmpty) {
      where.add('t.type IN (${_marks(filter.types.length)})');
      args.addAll(filter.types);
    }
    if (filter.categoryIds.isNotEmpty) {
      where.add('t.category_id IN (${_marks(filter.categoryIds.length)})');
      args.addAll(filter.categoryIds);
    }
    if (filter.minCents != null) {
      where.add('t.amount_cents >= ?');
      args.add(filter.minCents);
    }
    if (filter.maxCents != null) {
      where.add('t.amount_cents <= ?');
      args.add(filter.maxCents);
    }
    if (filter.startDate != null) {
      where.add('t.date >= ?');
      args.add(filter.startDate);
    }
    if (filter.endDate != null) {
      where.add('t.date <= ?');
      args.add(filter.endDate);
    }
    if (filter.keyword.isNotEmpty) {
      final like = '%${filter.keyword}%';
      where.add('(t.note LIKE ? OR c.name LIKE ?)');
      args.addAll([like, like]);
    }

    final sql = '''
      SELECT t.* FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY t.date DESC, t.time DESC, t.id DESC
    ''';
    final rows = await db.rawQuery(sql, args);
    return rows.map(TxRecord.fromMap).toList();
  }

  Future<List<TxRecord>> all({bool includeDeleted = true}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'date DESC, time DESC, id DESC',
    );
    return rows.map(TxRecord.fromMap).toList();
  }

  Future<TxRecord?> getById(int id, {bool includeDeleted = true}) async {
    final db = await _db.database;
    final rows = await db.query(
      'transactions',
      where: includeDeleted ? 'id = ?' : 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TxRecord.fromMap(rows.first);
  }

  // ---------------------------------------------------------------- writes

  Future<int> insert(TxRecord record) async {
    final db = await _db.database;
    return db.insert('transactions', record.toMap());
  }

  Future<void> update(TxRecord record) async {
    final db = await _db.database;
    await db.update('transactions', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> softDelete(int id) async {
    final db = await _db.database;
    await db.update(
      'transactions',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDeleteMany(Iterable<int> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final id in list) {
      batch.update('transactions', {'deleted_at': now},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> restore(int id) async {
    final db = await _db.database;
    await db.update('transactions', {'deleted_at': null},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hardDelete(int id) async {
    final db = await _db.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCategoryMany(Iterable<int> ids, int? categoryId) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final id in list) {
      batch.update('transactions', {'category_id': categoryId},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  // ------------------------------------------------------------------ stats

  Future<int> count({bool includeDeleted = false}) async {
    final db = await _db.database;
    final result = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM transactions${includeDeleted ? '' : ' WHERE deleted_at IS NULL'}'));
    return result ?? 0;
  }

  Future<void> replaceAll(List<TxRecord> records) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      for (final record in records) {
        await txn.insert('transactions', record.toMap());
      }
    });
  }

  Future<void> appendAll(List<TxRecord> records) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final record in records) {
        final map = record.toMap()..remove('id');
        await txn.insert('transactions', map);
      }
    });
  }

  static String _marks(int count) => List.filled(count, '?').join(', ');
}
