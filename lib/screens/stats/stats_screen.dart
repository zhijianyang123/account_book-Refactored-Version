import 'dart:math' as math;

import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/screens/root_shell.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/utils/stats_calculator.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:keframe/keframe.dart';
import 'package:provider/provider.dart';

/// 统计 Tab.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int? _highlightedCategoryId;

  void _openCategory(int? categoryId) {
    context
        .findAncestorStateOfType<RootShellState>()
        ?.openCategoryInDetail(categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context
        .select<SettingsProvider, AppSettings>((provider) => provider.settings);
    final stats = context.watch<StatsProvider>();
    final categories = context.watch<CategoryProvider>();

    final expenseColor = Color(settings.expenseColor);
    final incomeColor = Color(settings.incomeColor);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: StatsProvider.week, label: Text(t.t('stats_week'))),
                ButtonSegment(
                    value: StatsProvider.month, label: Text(t.t('stats_month'))),
                ButtonSegment(
                    value: StatsProvider.year, label: Text(t.t('stats_year'))),
              ],
              selected: {stats.rangeType},
              showSelectedIcon: false,
              onSelectionChanged: (value) => stats.setRangeType(value.first),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: stats.previous,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    stats.rangeLabel,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: stats.next,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Expanded(
            child: stats.loading && !stats.hasData
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 120),
                    children: [
                      _deferred(0, 150,
                          _summaryCard(t, stats, expenseColor, incomeColor)),
                      const SizedBox(height: 14),
                      _deferred(
                        1,
                        260,
                        _pieCard(
                          t,
                          title: t.t('stats_expense_distribution'),
                          data: stats.expenseCategories,
                          categories: categories,
                          emptyText: t.t('stats_no_expense'),
                          fallbackColor: expenseColor,
                          total: stats.expenseCents,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _deferred(
                        2,
                        260,
                        _pieCard(
                          t,
                          title: t.t('stats_income_distribution'),
                          data: stats.incomeCategories,
                          categories: categories,
                          emptyText: t.t('stats_no_income'),
                          fallbackColor: incomeColor,
                          total: stats.incomeCents,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _deferred(
                          3, 220, _categorySummaryCard(t, stats, categories)),
                      const SizedBox(height: 14),
                      _deferred(4, 240,
                          _trendCard(t, stats, expenseColor, incomeColor)),
                      const SizedBox(height: 14),
                      _deferred(5, 180, _budgetCard(t, stats, expenseColor)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Renders [child] on a later frame so tab switches stay smooth.
  Widget _deferred(int index, double height, Widget child) {
    return FrameSeparateWidget(
      index: index,
      placeHolder: SizedBox(height: height),
      child: child,
    );
  }

  Widget _card({required String title, required Widget child}) {
    return LightFollowCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryCard(AppLocalizations t, StatsProvider stats,
      Color expenseColor, Color incomeColor) {
    final isExpense = stats.amountType == TxType.expense;
    final accent = isExpense ? expenseColor : incomeColor;

    return LightFollowCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                  value: TxType.expense, label: Text(t.t('type_expense'))),
              ButtonSegment(
                  value: TxType.income, label: Text(t.t('type_income'))),
            ],
            selected: {stats.amountType},
            showSelectedIcon: false,
            onSelectionChanged: (value) => stats.setAmountType(value.first),
          ),
          const SizedBox(height: 14),
          Text(
            isExpense ? t.t('stats_total_expense') : t.t('stats_total_income'),
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              Money.format(stats.totalCents),
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('${t.t('income')} ${Money.format(stats.incomeCents)}',
                  style: TextStyle(fontSize: 13, color: incomeColor)),
              Text('${t.t('expense')} ${Money.format(stats.expenseCents)}',
                  style: TextStyle(fontSize: 13, color: expenseColor)),
            ],
          ),
        ],
      ),
    );
  }

  Color _categoryColor(CategoryProvider categories, int? id, Color fallback) {
    final category = categories.find(id);
    return category == null ? fallback : Color(category.color);
  }

  Widget _pieCard(
    AppLocalizations t, {
    required String title,
    required List<CategoryStat> data,
    required CategoryProvider categories,
    required String emptyText,
    required Color fallbackColor,
    required int total,
  }) {
    if (data.isEmpty || total == 0) {
      return _card(
        title: title,
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(emptyText,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline, fontSize: 13)),
          ),
        ),
      );
    }

    return _card(
      title: title,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: [
                  for (final stat in data)
                    PieChartSectionData(
                      value: stat.amountCents.toDouble(),
                      color: _categoryColor(categories, stat.id, fallbackColor),
                      radius: _highlightedCategoryId == stat.id ? 62 : 54,
                      showTitle: stat.amountCents / total >= 0.07,
                      title:
                          '${(stat.amountCents / total * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                ],
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is! FlTapUpEvent) return;
                    final index = response?.touchedSection?.touchedSectionIndex;
                    setState(() {
                      if (index == null || index < 0 || index >= data.length) {
                        _highlightedCategoryId = null;
                      } else {
                        _highlightedCategoryId = data[index].id;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final stat in data)
            _legendRow(t, stat, categories, fallbackColor, total),
        ],
      ),
    );
  }

  Widget _legendRow(
    AppLocalizations t,
    CategoryStat stat,
    CategoryProvider categories,
    Color fallbackColor,
    int total,
  ) {
    final category = categories.find(stat.id);
    final color = _categoryColor(categories, stat.id, fallbackColor);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openCategory(stat.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category == null
                    ? t.t('no_type')
                    : t.categoryName(category.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(Money.format(stat.amountCents),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              child: Text(
                '${(stat.amountCents / total * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendCard(AppLocalizations t, StatsProvider stats,
      Color expenseColor, Color incomeColor) {
    final points = stats.trend;
    final maxValue = points.fold<double>(0, (max, p) {
      return math.max(max, math.max(p.incomeCents, p.expenseCents).toDouble());
    });
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;
    final interval = math.max(1, (points.length / 6).ceil()).toDouble();
    final scheme = Theme.of(context).colorScheme;

    return _card(
      title: t.t('stats_trend'),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, points.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) => Text(
                    _compact(value),
                    style: TextStyle(color: scheme.outline, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(points[index].label,
                          style:
                              TextStyle(color: scheme.outline, fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              _line(points.map((p) => p.incomeCents.toDouble()).toList(),
                  incomeColor),
              _line(points.map((p) => p.expenseCents.toDouble()).toList(),
                  expenseColor),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData:
          BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
    );
  }

  Widget _categorySummaryCard(
    AppLocalizations t,
    StatsProvider stats,
    CategoryProvider categories,
  ) {
    final data = stats.amountType == TxType.expense
        ? stats.expenseCategories
        : stats.incomeCategories;
    if (data.isEmpty) {
      return _card(
        title: t.t('stats_category_summary'),
        child: Text(t.t('stats_no_expense'),
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 13)),
      );
    }
    final max = data.first.amountCents;
    final fallback = stats.amountType == TxType.expense
        ? Color(context.select<SettingsProvider, AppSettings>(
                (p) => p.settings)
            .expenseColor)
        : Color(context.select<SettingsProvider, AppSettings>(
                (p) => p.settings)
            .incomeColor);

    return _card(
      title: t.t('stats_category_summary'),
      child: Column(
        children: [
          for (final stat in data)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openCategory(stat.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _categoryColor(
                                categories, stat.id, fallback),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categories.find(stat.id) == null
                                ? t.t('no_type')
                                : t.categoryName(
                                    categories.find(stat.id)!.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                        Text(Money.format(stat.amountCents),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : stat.amountCents / max,
                        minHeight: 6,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(
                          _categoryColor(categories, stat.id, fallback),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetCard(
      AppLocalizations t, StatsProvider stats, Color expenseColor) {
    final budget = stats.activeBudget;
    if (budget == null) {
      return _card(
        title: t.t('stats_budget_execution'),
        child: Text(t.t('stats_no_budget'),
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 13)),
      );
    }
    final amount = budget.amountCents;
    final used = stats.budgetUsedCents;
    final remaining = stats.budgetRemainingCents;
    final overspent = remaining < 0;
    final statusColor = overspent ? expenseColor : const Color(0xFF1FA971);
    final ratio = amount == 0 ? 0.0 : (used / amount).clamp(0.0, 1.0);

    return _card(
      title: t.t('stats_budget_execution'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _budgetStat(t.t('stats_budget'), Money.format(amount)),
              _budgetStat(t.t('stats_used'), Money.format(used),
                  color: statusColor),
              _budgetStat(
                overspent ? t.t('stats_overspent') : t.t('stats_remaining'),
                Money.format(remaining.abs()),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            overspent
                ? t.t('stats_overspent_hint')
                : t.tArgs('stats_daily_available', {
                    'amount': Money.format(stats.budgetDailyAvailableCents),
                  }),
            style: TextStyle(color: statusColor, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _budgetStat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }

  String _compact(double cents) {
    final yuan = cents / 100;
    if (yuan.abs() >= 10000) return '${(yuan / 10000).toStringAsFixed(1)}w';
    return yuan.toStringAsFixed(0);
  }
}
