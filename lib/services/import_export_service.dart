import 'package:account_new/db/app_database.dart';
import 'package:account_new/models/backup_envelope.dart';
import 'package:account_new/models/import_models.dart';
import 'package:account_new/utils/backup_codec.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:sqflite/sqflite.dart';

enum ExportScope { all, dateRange, month, category }

class ExportOptions {
  const ExportOptions({
    this.scope = ExportScope.all,
    this.startDate,
    this.endDate,
    this.year,
    this.month,
    this.categoryId,
    this.includeDeleted = false,
  });

  final ExportScope scope;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? year;
  final int? month;
  final int? categoryId;
  final bool includeDeleted;
}

/// Builds and consumes backup JSON documents.
///
/// The whole import runs inside a single SQLite transaction so a failure rolls
/// the database back to its previous state.
class ImportExportService {
  ImportExportService({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  static const Set<String> _categoryCols = {
    'name', 'type', 'icon', 'color', 'sort_order', 'parent_id', 'is_default',
    'is_hidden',
  };
  static const Set<String> _txCols = {
    'type', 'amount_cents', 'category_id', 'date', 'time', 'note',
    'created_at', 'updated_at', 'deleted_at',
  };
  static const Set<String> _budgetCols = {
    'period_type', 'amount_cents', 'category_id', 'start_date', 'end_date',
  };

  // ---------------------------------------------------------------- export

  Future<BackupEnvelope> buildExport(ExportOptions options) async {
    final db = await _db.database;
    final categories = await db.query('categories', orderBy: 'sort_order');
    final budgets = await db.query('budgets');
    final settingsRows = await db.query('settings');

    final where = <String>[];
    final args = <Object?>[];
    if (!options.includeDeleted) where.add('deleted_at IS NULL');

    switch (options.scope) {
      case ExportScope.dateRange:
        if (options.startDate != null) {
          where.add('date >= ?');
          args.add(DateX.toDateString(options.startDate!));
        }
        if (options.endDate != null) {
          where.add('date <= ?');
          args.add(DateX.toDateString(options.endDate!));
        }
        break;
      case ExportScope.month:
        final year = options.year ?? DateTime.now().year;
        final month = options.month ?? DateTime.now().month;
        where.add('date >= ? AND date <= ?');
        args.add(DateX.toDateString(DateTime(year, month, 1)));
        args.add(DateX.toDateString(DateTime(year, month + 1, 0)));
        break;
      case ExportScope.category:
        where.add('category_id = ?');
        args.add(options.categoryId);
        break;
      case ExportScope.all:
        break;
    }

    final transactions = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date ASC, time ASC',
    );

    return BackupEnvelope(
      schemaVersion: BackupCodec.currentSchemaVersion,
      appVersion: BackupCodec.appVersion,
      exportedAt: DateTime.now().toIso8601String(),
      exportType: options.scope.name,
      categories: _asMaps(categories),
      transactions: _asMaps(transactions),
      budgets: _asMaps(budgets),
      settings: {
        for (final row in settingsRows)
          (row['key'] as String): (row['value'] ?? '') as String,
      },
    );
  }

  List<Map<String, Object?>> _asMaps(List<Map<String, Object?>> rows) =>
      rows.map((row) => Map<String, Object?>.from(row)).toList();

  // --------------------------------------------------------------- preview

  Future<ImportPreview> buildPreview(BackupEnvelope envelope) async {
    final db = await _db.database;
    final categories = await db.query('categories');

    final categoryKeys = {
      for (final row in categories) '${row['name']}|${row['type']}',
    };
    var categoryConflicts = 0;
    for (final raw in envelope.categories) {
      if (categoryKeys.contains('${raw['name']}|${raw['type']}')) {
        categoryConflicts++;
      }
    }

    final categoryNames = {
      for (final row in categories)
        (row['id'] as num).toInt(): row['name'] as String,
    };
    final existing = await db.query('transactions');
    final fingerprints = {
      for (final row in existing)
        _fingerprint(
          row['date']?.toString() ?? '',
          (row['amount_cents'] as num?)?.toInt() ?? 0,
          row['type']?.toString() ?? '',
          categoryNames[(row['category_id'] as num?)?.toInt()] ?? '',
          row['note']?.toString() ?? '',
        ),
    };
    final envCategoryNames = {
      for (final raw in envelope.categories)
        (raw['id'] as num?)?.toInt(): raw['name']?.toString() ?? '',
    };
    var duplicates = 0;
    for (final raw in envelope.transactions) {
      final fp = _fingerprint(
        raw['date']?.toString() ?? '',
        (raw['amount_cents'] as num?)?.toInt() ?? 0,
        raw['type']?.toString() ?? '',
        envCategoryNames[(raw['category_id'] as num?)?.toInt()] ?? '',
        raw['note']?.toString() ?? '',
      );
      if (fingerprints.contains(fp)) duplicates++;
    }

    DateTime? earliest;
    DateTime? latest;
    for (final raw in envelope.transactions) {
      final date = DateX.tryParseDate(raw['date']?.toString());
      if (date == null) continue;
      if (earliest == null || date.isBefore(earliest)) earliest = date;
      if (latest == null || date.isAfter(latest)) latest = date;
    }

    return ImportPreview(
      schemaVersion: envelope.schemaVersion,
      appVersion: envelope.appVersion,
      categoryCount: envelope.categories.length,
      transactionCount: envelope.transactions.length,
      budgetCount: envelope.budgets.length,
      earliestDate: earliest,
      latestDate: latest,
      categoryConflicts: categoryConflicts,
      duplicateTransactions: duplicates,
    );
  }

  // --------------------------------------------------------------- execute

  Future<ImportResult> execute(
    BackupEnvelope envelope,
    ImportOptions options,
  ) async {
    final result = ImportResult();
    final db = await _db.database;
    try {
      await db.transaction((txn) async {
        if (options.mode == ImportMode.overwrite) {
          for (final table in const [
            'transactions',
            'budgets',
            'categories',
            'settings',
          ]) {
            await txn.delete(table);
          }
        }

        final categoryMap =
            await _importCategories(txn, envelope, options, result);
        await _importBudgets(txn, envelope, options, categoryMap, result);
        await _importTransactions(txn, envelope, options, categoryMap, result);
        await _breakCategoryCycles(txn, result);

        if (options.mode == ImportMode.overwrite &&
            envelope.settings.isNotEmpty) {
          for (final entry in envelope.settings.entries) {
            await txn.insert(
              'settings',
              {'key': entry.key, 'value': entry.value},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (error) {
      result.failed = true;
      result.errors.add('$error');
    }
    return result;
  }

  Future<Map<int, int>> _importCategories(
    DatabaseExecutor txn,
    BackupEnvelope envelope,
    ImportOptions options,
    ImportResult result,
  ) async {
    final map = <int, int>{};
    final existing = await txn.query('categories');
    final byKey = <String, int>{
      for (final row in existing)
        '${row['name']}|${row['type']}': (row['id'] as num).toInt(),
    };

    for (final raw in envelope.categories) {
      final oldId = (raw['id'] as num?)?.toInt();
      final name = raw['name']?.toString() ?? '';
      if (name.isEmpty) {
        result.skipped++;
        continue;
      }
      final key = '$name|${raw['type']}';
      final existingId = byKey[key];
      final values =
          _normalize(raw, _categoryCols, const {'is_default', 'is_hidden'})
            ..remove('parent_id');

      if (existingId != null) {
        switch (options.categoryConflict) {
          case ConflictAction.skip:
            result.skipped++;
            break;
          case ConflictAction.merge:
            result.warnings.add(name);
            break;
          case ConflictAction.create:
            final id = await txn.insert('categories', values);
            byKey[key] = id;
            result.categoriesInserted++;
            if (oldId != null) map[oldId] = id;
            continue;
        }
        if (oldId != null) map[oldId] = existingId;
      } else {
        final id = await txn.insert('categories', values);
        byKey[key] = id;
        result.categoriesInserted++;
        if (oldId != null) map[oldId] = id;
      }
    }

    for (final raw in envelope.categories) {
      final oldId = (raw['id'] as num?)?.toInt();
      final oldParent = (raw['parent_id'] as num?)?.toInt();
      final newId = oldId == null ? null : map[oldId];
      if (newId == null || oldParent == null) continue;
      final newParent = map[oldParent];
      if (newParent == null) continue;
      await txn.update('categories', {'parent_id': newParent},
          where: 'id = ?', whereArgs: [newId]);
    }
    return map;
  }

  Future<void> _importBudgets(
    DatabaseExecutor txn,
    BackupEnvelope envelope,
    ImportOptions options,
    Map<int, int> categoryMap,
    ImportResult result,
  ) async {
    final existing = await txn.query('budgets');
    for (final raw in envelope.budgets) {
      final values = _normalize(raw, _budgetCols, const {});
      final oldCategory = (values['category_id'] as num?)?.toInt();
      values['category_id'] =
          oldCategory == null ? null : categoryMap[oldCategory];

      final match = existing.where((row) =>
          row['period_type'] == values['period_type'] &&
          row['start_date'] == values['start_date'] &&
          row['end_date'] == values['end_date'] &&
          (row['category_id'] as num?)?.toInt() == values['category_id']);
      final hasConflict = match.isNotEmpty;

      if (hasConflict) {
        switch (options.budgetConflict) {
          case BudgetConflictAction.skip:
            result.skipped++;
            continue;
          case BudgetConflictAction.overwrite:
            await txn.update('budgets', values,
                where: 'id = ?', whereArgs: [match.first['id']]);
            continue;
          case BudgetConflictAction.keepBoth:
            break;
        }
      }
      await txn.insert('budgets', values);
      result.budgetsInserted++;
    }
  }

  Future<void> _importTransactions(
    DatabaseExecutor txn,
    BackupEnvelope envelope,
    ImportOptions options,
    Map<int, int> categoryMap,
    ImportResult result,
  ) async {
    final existing = await txn.query('transactions', columns: ['id']);
    final existingIds = {
      for (final row in existing) (row['id'] as num).toInt(),
    };

    final categoryNames = await _nameMap(txn, 'categories');
    final existingRows = await txn.query('transactions');
    final existingFingerprints = {
      for (final row in existingRows)
        _fingerprint(
          row['date']?.toString() ?? '',
          (row['amount_cents'] as num?)?.toInt() ?? 0,
          row['type']?.toString() ?? '',
          categoryNames[(row['category_id'] as num?)?.toInt()] ?? '',
          row['note']?.toString() ?? '',
        ),
    };
    final batchFingerprints = <String>{};

    final envCategoryNames = {
      for (final raw in envelope.categories)
        (raw['id'] as num?)?.toInt(): raw['name']?.toString() ?? '',
    };

    for (final raw in envelope.transactions) {
      final oldId = (raw['id'] as num?)?.toInt();
      final date = raw['date']?.toString() ?? '';
      final amount = (raw['amount_cents'] as num?)?.toInt();
      if (DateX.tryParseDate(date) == null) {
        result.skipped++;
        result.errors.add(date);
        continue;
      }
      if (amount == null) {
        result.skipped++;
        result.errors.add(date);
        continue;
      }

      if (options.mode == ImportMode.dateRange) {
        final parsed = DateX.parseDate(date);
        if (options.rangeStart != null &&
            parsed.isBefore(DateX.startOfDay(options.rangeStart!))) {
          result.skipped++;
          continue;
        }
        if (options.rangeEnd != null &&
            parsed.isAfter(DateX.startOfDay(options.rangeEnd!))) {
          result.skipped++;
          continue;
        }
      }

      final fingerprint = _fingerprint(
        date,
        amount,
        raw['type']?.toString() ?? 'expense',
        envCategoryNames[(raw['category_id'] as num?)?.toInt()] ?? '',
        raw['note']?.toString() ?? '',
      );

      if (options.mode != ImportMode.overwrite) {
        if (options.txDuplicate == TxDuplicateStrategy.byId &&
            oldId != null &&
            existingIds.contains(oldId)) {
          result.skipped++;
          continue;
        }
        if (options.txDuplicate == TxDuplicateStrategy.byFingerprint &&
            (existingFingerprints.contains(fingerprint) ||
                batchFingerprints.contains(fingerprint))) {
          result.skipped++;
          continue;
        }
      }

      final values = _normalize(raw, _txCols, const {})..remove('id');
      final oldCategory = (values['category_id'] as num?)?.toInt();
      values['category_id'] =
          oldCategory == null ? null : categoryMap[oldCategory];

      final newId = await txn.insert('transactions', values);
      existingIds.add(newId);
      existingFingerprints.add(fingerprint);
      batchFingerprints.add(fingerprint);
      result.transactionsInserted++;
    }
  }

  Future<void> _breakCategoryCycles(
      DatabaseExecutor txn, ImportResult result) async {
    final rows = await txn.query('categories', columns: ['id', 'parent_id']);
    final parent = {
      for (final row in rows)
        (row['id'] as num).toInt(): (row['parent_id'] as num?)?.toInt(),
    };
    for (final id in parent.keys) {
      final seen = <int>{};
      int? cursor = id;
      var cyclic = false;
      while (cursor != null) {
        if (!seen.add(cursor)) {
          cyclic = true;
          break;
        }
        cursor = parent[cursor];
      }
      if (cyclic) {
        await txn.update('categories', {'parent_id': null},
            where: 'id = ?', whereArgs: [id]);
        result.warnings.add('$id');
      }
    }
  }

  Future<Map<int, String>> _nameMap(
      DatabaseExecutor txn, String table) async {
    final rows = await txn.query(table, columns: ['id', 'name']);
    return {
      for (final row in rows)
        (row['id'] as num).toInt(): row['name']?.toString() ?? '',
    };
  }

  Map<String, Object?> _normalize(
    Map<String, Object?> raw,
    Set<String> columns,
    Set<String> boolFields,
  ) {
    final values = <String, Object?>{};
    raw.forEach((key, value) {
      if (!columns.contains(key)) return;
      if (boolFields.contains(key)) {
        values[key] = (value == true || value == 1) ? 1 : 0;
      } else {
        values[key] = value;
      }
    });
    return values;
  }

  String _fingerprint(
    String date,
    int amount,
    String type,
    String categoryName,
    String note,
  ) =>
      '$date|$amount|$type|$categoryName|$note';
}
