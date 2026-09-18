// Import configuration and result types.

enum ImportMode { overwrite, merge, append, dateRange }

extension ImportModeX on ImportMode {
  String get labelKey {
    switch (this) {
      case ImportMode.overwrite:
        return 'import_mode_overwrite';
      case ImportMode.merge:
        return 'import_mode_merge';
      case ImportMode.append:
        return 'import_mode_append';
      case ImportMode.dateRange:
        return 'import_mode_date_range';
    }
  }
}

enum ConflictAction { skip, merge, create }

extension ConflictActionX on ConflictAction {
  String get labelKey {
    switch (this) {
      case ConflictAction.skip:
        return 'conflict_skip';
      case ConflictAction.merge:
        return 'conflict_merge';
      case ConflictAction.create:
        return 'conflict_create';
    }
  }
}

enum TxDuplicateStrategy { byId, byFingerprint, keepAll }

extension TxDuplicateStrategyX on TxDuplicateStrategy {
  String get labelKey {
    switch (this) {
      case TxDuplicateStrategy.byId:
        return 'dedupe_by_id';
      case TxDuplicateStrategy.byFingerprint:
        return 'dedupe_by_fingerprint';
      case TxDuplicateStrategy.keepAll:
        return 'dedupe_keep_all';
    }
  }
}

enum BudgetConflictAction { overwrite, keepBoth, skip }

extension BudgetConflictActionX on BudgetConflictAction {
  String get labelKey {
    switch (this) {
      case BudgetConflictAction.overwrite:
        return 'conflict_overwrite';
      case BudgetConflictAction.keepBoth:
        return 'conflict_keep_both';
      case BudgetConflictAction.skip:
        return 'conflict_skip';
    }
  }
}

class ImportOptions {
  const ImportOptions({
    this.mode = ImportMode.merge,
    this.categoryConflict = ConflictAction.merge,
    this.txDuplicate = TxDuplicateStrategy.byFingerprint,
    this.budgetConflict = BudgetConflictAction.skip,
    this.rangeStart,
    this.rangeEnd,
  });

  final ImportMode mode;
  final ConflictAction categoryConflict;
  final TxDuplicateStrategy txDuplicate;
  final BudgetConflictAction budgetConflict;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
}

class ImportPreview {
  const ImportPreview({
    required this.schemaVersion,
    required this.appVersion,
    required this.categoryCount,
    required this.transactionCount,
    required this.budgetCount,
    required this.earliestDate,
    required this.latestDate,
    required this.categoryConflicts,
    required this.duplicateTransactions,
  });

  final int schemaVersion;
  final String appVersion;
  final int categoryCount;
  final int transactionCount;
  final int budgetCount;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final int categoryConflicts;
  final int duplicateTransactions;
}

class ImportResult {
  ImportResult();

  bool failed = false;
  int categoriesInserted = 0;
  int budgetsInserted = 0;
  int transactionsInserted = 0;
  int skipped = 0;
  final List<String> errors = [];
  final List<String> warnings = [];

  Map<String, Object?> toReportJson() => {
        'failed': failed,
        'categories_inserted': categoriesInserted,
        'budgets_inserted': budgetsInserted,
        'transactions_inserted': transactionsInserted,
        'skipped': skipped,
        'errors': errors,
        'warnings': warnings,
        'generated_at': DateTime.now().toIso8601String(),
      };
}
