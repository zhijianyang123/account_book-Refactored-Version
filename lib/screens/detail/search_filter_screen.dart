import 'dart:async';

import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/models/saved_filter.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/saved_filter_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:account_new/screens/detail/transaction_edit_screen.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/widgets/filter_sheet.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:account_new/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 搜索与筛选.
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key, this.initialFilter});

  final TxFilter? initialFilter;

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late TxFilter _filter = widget.initialFilter ?? const TxFilter();
  late final TextEditingController _searchController =
      TextEditingController(text: _filter.keyword);
  List<TxRecord> _results = const [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final provider = context.read<TransactionProvider>();
    setState(() => _loading = true);
    final results = await provider.search(_filter);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _onKeywordChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _filter = _filter.copyWith(keyword: value);
      _runSearch();
    });
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(context, _filter);
    if (result == null) return;
    setState(() => _filter = result);
    await _runSearch();
  }

  Future<void> _saveCurrentFilter() async {
    final t = AppLocalizations.of(context);
    if (_filter.isEmpty) {
      _toast(t.t('search_no_condition'));
      return;
    }
    final provider = context.read<SavedFilterProvider>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('search_save_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.t('search_save_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.t('common_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim().isEmpty
                  ? t.t('search_unnamed')
                  : controller.text.trim(),
            ),
            child: Text(t.t('common_save')),
          ),
        ],
      ),
    );
    if (name == null) return;
    await provider.add(SavedFilter(name: name, filter: _filter));
    if (!mounted) return;
    _toast(t.tArgs('search_saved', {'name': name}));
  }

  Future<void> _deleteSavedFilter(SavedFilter saved) async {
    final t = AppLocalizations.of(context);
    final provider = context.read<SavedFilterProvider>();
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('search_delete_title'),
      message: t.tArgs('search_delete_message', {'name': saved.name}),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('common_delete'),
      destructive: true,
    );
    if (confirmed != true) return;
    await provider.delete(saved.id!);
  }

  Future<void> _openEdit(TxRecord record) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditScreen(record: record),
      ),
    );
    await _runSearch();
  }

  void _toast(String message) {
    showBriefSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context
        .select<SettingsProvider, AppSettings>((provider) => provider.settings);
    final categories = context.watch<CategoryProvider>();
    final savedFilters = context.watch<SavedFilterProvider>().filters;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: SizedBox(
          height: 44,
          child: TextField(
            controller: _searchController,
            onChanged: _onKeywordChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.t('search_hint'),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onKeywordChanged('');
                      },
                    ),
            ),
          ),
        ),
        actions: [
          Badge(
            isLabelVisible: _filter.activeCount > 0,
            label: Text('${_filter.activeCount}'),
            child: IconButton(
              onPressed: _openFilter,
              icon: const Icon(Icons.tune),
            ),
          ),
          IconButton(
            onPressed: _saveCurrentFilter,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (savedFilters.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final saved in savedFilters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.bookmark, size: 16),
                        label: Text(saved.name),
                        onPressed: () {
                          setState(() => _filter = saved.filter);
                          _searchController.text = saved.filter.keyword;
                          _runSearch();
                        },
                        onDeleted: () => _deleteSavedFilter(saved),
                      ),
                    ),
                ],
              ),
            ),
          if (!_filter.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.tArgs('filter_count', {'count': _filter.activeCount}),
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _filter = const TxFilter());
                      _searchController.clear();
                      _runSearch();
                    },
                    child: Text(t.t('common_clear')),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(t.t('search_no_match'),
                            style: TextStyle(color: scheme.outline)),
                      )
                    : _buildResults(
                        t, categories, settings, scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    AppLocalizations t,
    CategoryProvider categories,
    AppSettings settings,
    ColorScheme scheme,
  ) {
    final grouped = <String, List<TxRecord>>{};
    for (final record in _results) {
      grouped.putIfAbsent(record.date, () => []).add(record);
    }
    final days = grouped.entries.toList(growable: false);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final entry = days[index];
        final records = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                DateX.dayLabel(DateX.parseDate(entry.key), t.languageCode),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < records.length; i++) ...[
                    TransactionTile(
                      record: records[i],
                      category: categories.find(records[i].categoryId),
                      noTypeLabel: t.t('no_type'),
                      expenseColor: Color(settings.expenseColor),
                      incomeColor: Color(settings.incomeColor),
                      onTap: () => _openEdit(records[i]),
                    ),
                    if (i != records.length - 1)
                      const Divider(indent: 68, endIndent: 16),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
