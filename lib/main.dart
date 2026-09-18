import 'package:account_new/app.dart';
import 'package:account_new/db/app_database.dart';
import 'package:account_new/db/budget_dao.dart';
import 'package:account_new/db/category_dao.dart';
import 'package:account_new/db/saved_filter_dao.dart';
import 'package:account_new/db/settings_dao.dart';
import 'package:account_new/db/transaction_dao.dart';
import 'package:account_new/providers/budget_provider.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/saved_filter_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase.instance;
  final settings = SettingsProvider(dao: SettingsDao(db));
  final categories = CategoryProvider(dao: CategoryDao(db));
  final transactions = TransactionProvider(dao: TransactionDao(db));
  final budgets = BudgetProvider(
    dao: BudgetDao(db),
    txDao: TransactionDao(db),
  );
  final savedFilters = SavedFilterProvider(dao: SavedFilterDao(db));
  final stats = StatsProvider(
    txDao: TransactionDao(db),
    categoryDao: CategoryDao(db),
    budgetDao: BudgetDao(db),
  );

  await settings.load();
  await Future.wait([
    categories.load(),
    transactions.load(),
    budgets.load(),
    savedFilters.load(),
    stats.load(firstWeekday: settings.settings.firstWeekday),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<CategoryProvider>.value(value: categories),
        ChangeNotifierProvider<TransactionProvider>.value(value: transactions),
        ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
        ChangeNotifierProvider<SavedFilterProvider>.value(value: savedFilters),
        ChangeNotifierProvider<StatsProvider>.value(value: stats),
      ],
      child: const AccountApp(),
    ),
  );
}
