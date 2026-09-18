import 'package:account_new/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single-book SQLite database. All money is stored as integer cents.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// v2 removed accounts/tags/merchants and transfer/refund support.
  static const int schemaVersion = 2;
  static const String dbName = 'account_new.db';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, dbName);
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) => _createV2(db),
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop unsupported entry types, then rebuild the simplified tables.
      await db.delete('transactions',
          where: "type NOT IN ('expense','income')");

      await db.execute('''
        CREATE TABLE transactions_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount_cents INTEGER NOT NULL DEFAULT 0,
          category_id INTEGER,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          note TEXT,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO transactions_v2
          (id, type, amount_cents, category_id, date, time, note, created_at, updated_at, deleted_at)
        SELECT id, type, amount_cents, category_id, date, time, note, created_at, updated_at, deleted_at
        FROM transactions
      ''');
      await db.execute('DROP TABLE transactions');
      await db.execute('ALTER TABLE transactions_v2 RENAME TO transactions');

      await db.execute('''
        CREATE TABLE budgets_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          period_type TEXT NOT NULL,
          amount_cents INTEGER NOT NULL DEFAULT 0,
          category_id INTEGER,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO budgets_v2
          (id, period_type, amount_cents, category_id, start_date, end_date)
        SELECT id, period_type, amount_cents, category_id, start_date, end_date
        FROM budgets
      ''');
      await db.execute('DROP TABLE budgets');
      await db.execute('ALTER TABLE budgets_v2 RENAME TO budgets');

      await db.execute('DROP TABLE IF EXISTS transaction_tags');
      await db.execute('DROP TABLE IF EXISTS accounts');
      await db.execute('DROP TABLE IF EXISTS tags');
      await db.execute('DROP TABLE IF EXISTS merchants');

      await db.execute(
          'CREATE INDEX idx_tx_date ON transactions(date)');
      await db.execute(
          'CREATE INDEX idx_tx_category ON transactions(category_id)');
    }
  }

  Future<void> _createV2(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'label',
        color INTEGER NOT NULL DEFAULT 4289379212,
        sort_order INTEGER NOT NULL DEFAULT 0,
        parent_id INTEGER,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_hidden INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        note TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period_type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE saved_filters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    batch.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    batch.execute('CREATE INDEX idx_tx_category ON transactions(category_id)');

    await batch.commit(noResult: true);
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    var order = 0;
    for (final c in Defaults.allCategories) {
      batch.insert('categories', {
        'name': c.name,
        'type': c.type,
        'icon': c.icon,
        'color': c.color,
        'sort_order': order++,
        'is_default': 1,
        'is_hidden': 0,
      });
    }

    Defaults.defaultSettings.forEach((key, value) {
      batch.insert('settings', {'key': key, 'value': value});
    });

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Wipes every table and re-seeds defaults. Used by "clear all data".
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in const [
        'transactions',
        'budgets',
        'saved_filters',
        'categories',
        'settings',
      ]) {
        await txn.delete(table);
      }
    });
    await _seed(db);
  }
}
