import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the combined filter sheet, returning the applied filter or null.
Future<TxFilter?> showFilterSheet(BuildContext context, TxFilter initial) {
  return showImmersiveSheet<TxFilter>(
    context: context,
    builder: (_) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final TxFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _types;
  late Set<int> _categoryIds;
  DateTime? _startDate;
  DateTime? _endDate;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _types = Set<String>.from(widget.initial.types);
    _categoryIds = Set<int>.from(widget.initial.categoryIds);
    _startDate = DateX.tryParseDate(widget.initial.startDate);
    _endDate = DateX.tryParseDate(widget.initial.endDate);
    _minController = TextEditingController(
      text: widget.initial.minCents == null
          ? ''
          : Money.centsToAmount(widget.initial.minCents!).toString(),
    );
    _maxController = TextEditingController(
      text: widget.initial.maxCents == null
          ? ''
          : Money.centsToAmount(widget.initial.maxCents!).toString(),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _reset() {
    setState(() {
      _types.clear();
      _categoryIds.clear();
      _startDate = null;
      _endDate = null;
      _minController.clear();
      _maxController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(TxFilter(
      keyword: widget.initial.keyword,
      types: _types,
      categoryIds: _categoryIds,
      minCents: Money.parseToCents(_minController.text),
      maxCents: Money.parseToCents(_maxController.text),
      startDate: _startDate == null ? null : DateX.toDateString(_startDate!),
      endDate: _endDate == null ? null : DateX.toDateString(_endDate!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categories = context.watch<CategoryProvider>().categories;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(t.t('filter_title'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(t.t('filter_type')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in TxType.all)
                        _chip(
                          label: type == TxType.expense
                              ? t.t('type_expense')
                              : t.t('type_income'),
                          selected: _types.contains(type),
                          onTap: () => setState(() {
                            if (_types.contains(type)) {
                              _types.remove(type);
                            } else {
                              _types.add(type);
                            }
                          }),
                        ),
                    ],
                  ),
                  _label(t.t('filter_category')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories)
                        _chip(
                          label: t.categoryName(category.name),
                          selected: _categoryIds.contains(category.id),
                          avatarColor: Color(category.color),
                          onTap: () => setState(() {
                            if (_categoryIds.contains(category.id)) {
                              _categoryIds.remove(category.id);
                            } else {
                              _categoryIds.add(category.id!);
                            }
                          }),
                        ),
                    ],
                  ),
                  _label(t.t('filter_amount')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: t.t('filter_min'),
                            prefixText: '¥ ',
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('~'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: t.t('filter_max'),
                            prefixText: '¥ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  _label(t.t('filter_date')),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(t.t('filter_start_date')),
                          trailing: Text(_startDate == null
                              ? t.t('filter_unlimited')
                              : DateX.toDateString(_startDate!)),
                          onTap: () => _pickDate(true),
                        ),
                        const Divider(indent: 56, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.event_available_outlined),
                          title: Text(t.t('filter_end_date')),
                          trailing: Text(_endDate == null
                              ? t.t('filter_unlimited')
                              : DateX.toDateString(_endDate!)),
                          onTap: () => _pickDate(false),
                        ),
                      ],
                    ),
                  ),
                  if (_startDate != null || _endDate != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                        child: Text(t.t('filter_clear_date')),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.t('common_reset')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check),
                  label: Text(t.t('common_apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? avatarColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: avatarColor == null
          ? null
          : CircleAvatar(backgroundColor: avatarColor, radius: 8),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
      selected: selected,
      showCheckmark: avatarColor == null,
      checkmarkColor: scheme.onPrimary,
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(
        color: selected ? Colors.transparent : scheme.outlineVariant,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}
