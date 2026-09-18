import 'package:account_new/providers/budget_provider.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/saved_filter_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Reloads every provider after a destructive/global data operation
/// (import, clear-all). Keeps 明细/统计/预算 in sync.
Future<void> refreshAllData(BuildContext context) async {
  final settings = context.read<SettingsProvider>();
  final categories = context.read<CategoryProvider>();
  final transactions = context.read<TransactionProvider>();
  final budgets = context.read<BudgetProvider>();
  final savedFilters = context.read<SavedFilterProvider>();
  final stats = context.read<StatsProvider>();

  await settings.load();
  await Future.wait([
    categories.load(),
    transactions.load(),
    budgets.load(),
    savedFilters.load(),
    stats.load(firstWeekday: settings.settings.firstWeekday),
  ]);
}
