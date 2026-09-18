import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:account_new/screens/detail/search_filter_screen.dart';
import 'package:account_new/screens/detail/transaction_edit_screen.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/widgets/category_picker_sheet.dart';
import 'package:account_new/widgets/filter_sheet.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:account_new/widgets/transaction_tile.dart';
import 'package:account_new/widgets/wheel_pickers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Summary {
  const _Summary(this.income, this.expense);
  final int income;
  final int expense;
  int get balance => income - expense;

  @override
  bool operator ==(Object other) =>
      other is _Summary &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(income, expense);
}

/// 明细 Tab.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final Set<int> _selected = <int>{};

  bool get _selecting => _selected.isNotEmpty;

  void _mutateSelection(void Function() change) {
    setState(change);
    context
        .read<TransactionProvider>()
        .setSelectionActive(_selected.isNotEmpty);
  }

  Future<void> _openEdit([TxRecord? record]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditScreen(record: record),
      ),
    );
  }

  Future<void> _openSearch(TxFilter filter) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchFilterScreen(initialFilter: filter),
      ),
    );
  }

  Future<void> _pickMonth(TransactionProvider tx) async {
    final picked = await showMonthWheelPicker(
      context,
      initial: tx.selectedMonth,
    );
    if (picked != null) await tx.setMonth(picked);
  }

  Future<void> _openFilter() async {
    final provider = context.read<TransactionProvider>();
    final result = await showFilterSheet(context, provider.filter);
    if (result == null) return;
    await provider.setFilter(result);
  }

  Future<void> _delete(TxRecord record) async {
    final provider = context.read<TransactionProvider>();
    final stats = context.read<StatsProvider>();
    await provider.delete(record.id!);
    await stats.load();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    showBriefSnack(
      context,
      t.t('detail_deleted'),
      action: SnackBarAction(
        label: t.t('detail_undo'),
        onPressed: () async {
          await provider.restore(record.id!);
          await stats.load();
        },
      ),
    );
  }

  Future<void> _batchDelete() async {
    final t = AppLocalizations.of(context);
    final provider = context.read<TransactionProvider>();
    final stats = context.read<StatsProvider>();
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('detail_batch_delete_title'),
      message: t.tArgs('detail_batch_delete_message', {'count': _selected.length}),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('common_delete'),
      destructive: true,
    );
    if (confirmed != true) return;
    final ids = Set<int>.from(_selected);
    _mutateSelection(_selected.clear);
    await provider.deleteMany(ids);
    await stats.load();
    if (!mounted) return;
    showBriefSnack(
      context,
      t.tArgs('detail_deleted_count', {'count': ids.length}),
    );
  }

  Future<void> _batchChangeCategory() async {
    final t = AppLocalizations.of(context);
    final provider = context.read<TransactionProvider>();
    final stats = context.read<StatsProvider>();
    final picked = await showCategoryPicker(
      context,
      selectedId: null,
      allowNone: false,
      title: t.t('detail_change_category'),
    );
    if (picked == null) return;
    final ids = Set<int>.from(_selected);
    _mutateSelection(_selected.clear);
    await provider.updateCategoryMany(
        ids, picked == kNoCategory ? null : picked);
    await stats.load();
    if (!mounted) return;
    showBriefSnack(context, t.t('detail_category_updated'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context
        .select<SettingsProvider, AppSettings>((provider) => provider.settings);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _TopBar(
            onSearch: () => _openSearch(
              context.read<TransactionProvider>().filter,
            ),
            onFilter: _openFilter,
            onPickMonth: () => _pickMonth(context.read<TransactionProvider>()),
          ),
          _OverviewCard(
            expenseColor: Color(settings.expenseColor),
            incomeColor: Color(settings.incomeColor),
          ),
          if (_selecting) _selectionHeader(t),
          Expanded(
            child: _TransactionList(
              expenseColor: Color(settings.expenseColor),
              incomeColor: Color(settings.incomeColor),
              selectionMode: _selecting,
              selected: _selected,
              onToggle: (id) => _mutateSelection(() {
                if (!_selected.remove(id)) _selected.add(id);
              }),
              onEnterSelection: (id) => _mutateSelection(() => _selected.add(id)),
              onOpen: _openEdit,
              onDelete: _delete,
            ),
          ),
          if (_selecting) _selectionBar(t),
        ],
      ),
    );
  }

  Widget _selectionHeader(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          t.tArgs('detail_selected', {'count': _selected.length}),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _selectionBar(AppLocalizations t) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Card(
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _batchChangeCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: Text(t.t('detail_change_category')),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _batchDelete,
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  label: Text(
                    t.t('common_delete'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _mutateSelection(_selected.clear),
                  icon: const Icon(Icons.close),
                  label: Text(t.t('common_cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onSearch,
    required this.onFilter,
    required this.onPickMonth,
  });

  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filterCount = context.select<TransactionProvider, int>(
        (provider) => provider.filter.activeCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.read<TransactionProvider>().previousMonth(),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Selector<TransactionProvider, DateTime>(
                selector: (_, provider) => provider.selectedMonth,
                builder: (context, month, _) => TextButton.icon(
                  onPressed: onPickMonth,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                    DateX.monthLabel(month, t.languageCode),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.read<TransactionProvider>().nextMonth(),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            tooltip: t.t('search_title'),
          ),
          Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            child: IconButton(
              onPressed: onFilter,
              icon: const Icon(Icons.tune),
              tooltip: t.t('filter_title'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.expenseColor, required this.incomeColor});

  final Color expenseColor;
  final Color incomeColor;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final summary = context.select<TransactionProvider, _Summary>(
      (provider) =>
          _Summary(provider.monthIncomeCents, provider.monthExpenseCents),
    );
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: LightFollowCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            _stat(t.t('income'), summary.income, incomeColor, scheme),
            _divider(scheme),
            _stat(t.t('expense'), summary.expense, expenseColor, scheme),
            _divider(scheme),
            _stat(
              t.t('balance'),
              summary.balance,
              summary.balance < 0 ? expenseColor : scheme.onSurface,
              scheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int cents, Color color, ColorScheme scheme) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              Money.formatBalance(cents),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) => Container(
        width: 1,
        height: 30,
        color: scheme.outlineVariant,
      );
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.expenseColor,
    required this.incomeColor,
    required this.selectionMode,
    required this.selected,
    required this.onToggle,
    required this.onEnterSelection,
    required this.onOpen,
    required this.onDelete,
  });

  final Color expenseColor;
  final Color incomeColor;
  final bool selectionMode;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onEnterSelection;
  final ValueChanged<TxRecord> onOpen;
  final Future<void> Function(TxRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categories = context.watch<CategoryProvider>();
    final grouped = context.select<TransactionProvider,
        Map<String, List<TxRecord>>>((provider) => provider.groupedByDate);

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 14),
            Text(t.t('detail_empty_title'),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              t.t('detail_empty_subtitle'),
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final days = grouped.entries.toList(growable: false);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
          sliver: SliverList.builder(
            itemCount: days.length,
            itemBuilder: (context, index) {
              final entry = days[index];
              final records = entry.value;
              final date = DateX.parseDate(entry.key);
              final expense = records
                  .where((r) => r.type == 'expense')
                  .fold<int>(0, (sum, r) => sum + r.amountCents);
              final income = records
                  .where((r) => r.type == 'income')
                  .fold<int>(0, (sum, r) => sum + r.amountCents);

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dayHeader(
                        context, t, date, expense, income),
                    const SizedBox(height: 4),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < records.length; i++) ...[
                            _buildTile(context, t, categories, records[i]),
                            if (i != records.length - 1)
                              const Divider(indent: 68, endIndent: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dayHeader(BuildContext context, AppLocalizations t, DateTime date,
      int expense, int income) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Text(
            DateX.dayLabel(date, t.languageCode),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (expense > 0)
            Text('${t.t('expense')} ${Money.format(expense)}',
                style: TextStyle(fontSize: 12, color: expenseColor)),
          if (expense > 0 && income > 0) const SizedBox(width: 10),
          if (income > 0)
            Text('${t.t('income')} ${Money.format(income)}',
                style: TextStyle(fontSize: 12, color: incomeColor)),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, AppLocalizations t,
      CategoryProvider categories, TxRecord record) {
    final tile = TransactionTile(
      record: record,
      category: categories.find(record.categoryId),
      noTypeLabel: t.t('no_type'),
      expenseColor: expenseColor,
      incomeColor: incomeColor,
      selectionMode: selectionMode,
      selected: selected.contains(record.id),
      onTap: selectionMode
          ? () => onToggle(record.id!)
          : () => onOpen(record),
      onLongPress: selectionMode ? null : () => onEnterSelection(record.id!),
    );

    if (selectionMode) return tile;
    return Dismissible(
      key: ValueKey('tx-${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete(record);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: tile,
    );
  }
}
