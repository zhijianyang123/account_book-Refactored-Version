import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/models/category.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:account_new/utils/calculator.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/widgets/amount_keypad.dart';
import 'package:account_new/widgets/category_grid.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:account_new/widgets/wheel_pickers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 记一笔 / 编辑账单 — expense & income only.
class TransactionEditScreen extends StatefulWidget {
  const TransactionEditScreen({super.key, this.record});

  final TxRecord? record;

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  late String _type;
  String _expression = '';
  int? _categoryId;
  late DateTime _date;
  bool _saving = false;

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  final GlobalKey _noteKey = GlobalKey();

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    final settings = context.read<SettingsProvider>().settings;
    _noteFocus.addListener(_onNoteFocusChanged);

    if (record != null) {
      _type = record.type;
      _expression = Calculator.format(Money.centsToAmount(record.amountCents));
      _categoryId = record.categoryId;
      _date = _combineDateTime(record.date, record.time);
      _noteController.text = record.note ?? '';
    } else {
      _type = settings.defaultTxType;
      _date = DateTime.now();
      final categories =
          context.read<CategoryProvider>().byTypeVisible(_type);
      if (categories.isNotEmpty) _categoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
    _noteFocus.removeListener(_onNoteFocusChanged);
    _noteFocus.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime _combineDateTime(String date, String time) {
    final day = DateX.tryParseDate(date) ?? DateTime.now();
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  void _onNoteFocusChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_noteFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noteContext = _noteKey.currentContext;
      if (noteContext == null) return;
      Scrollable.ensureVisible(
        noteContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  void _onKey(String value) {
    setState(() {
      if (Calculator.isOperator(value)) {
        if (_expression.isEmpty) return;
        if (Calculator.isOperator(_expression[_expression.length - 1])) {
          _expression =
              _expression.substring(0, _expression.length - 1) + value;
        } else {
          _expression += value;
        }
        return;
      }
      if (value == '.') {
        final last = _expression.split(RegExp(r'[+\-*/×÷]')).last;
        if (last.contains('.')) return;
        _expression += last.isEmpty ? '0.' : '.';
        return;
      }
      final last = _expression.split(RegExp(r'[+\-*/×÷]')).last;
      if (last == '0') {
        _expression = _expression.substring(0, _expression.length - 1) + value;
      } else {
        _expression += value;
      }
    });
  }

  void _onBackspace() {
    if (_expression.isEmpty) return;
    setState(() =>
        _expression = _expression.substring(0, _expression.length - 1));
  }

  void _onTypeChanged(String type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      final list = context.read<CategoryProvider>().byTypeVisible(type);
      final stillValid = list.any((c) => c.id == _categoryId);
      if (!stillValid) _categoryId = list.isNotEmpty ? list.first.id : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDateWheelPicker(context, initial: _date);
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour,
          _date.minute);
    });
  }

  Future<void> _save({required bool continueAfter}) async {
    if (_saving) return;
    final t = AppLocalizations.of(context);
    final cents = Calculator.toCents(_expression);
    if (cents == null || cents <= 0) {
      _toast(t.t('edit_error_amount'), error: true);
      return;
    }
    if (_categoryId == null) {
      _toast(t.t('edit_error_category'), error: true);
      return;
    }

    setState(() => _saving = true);
    final tx = context.read<TransactionProvider>();
    final stats = context.read<StatsProvider>();
    final now = DateTime.now();
    final iso = now.toIso8601String();
    final note = _noteController.text.trim();
    final record = TxRecord(
      id: widget.record?.id,
      type: _type,
      amountCents: cents,
      categoryId: _categoryId,
      date: DateX.toDateString(_date),
      time: DateX.toTimeString(_date),
      note: note.isEmpty ? null : note,
      createdAt: widget.record?.createdAt ?? iso,
      updatedAt: iso,
    );

    try {
      if (_isEditing) {
        await tx.update(record);
      } else {
        await tx.save(record);
      }
      await stats.load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(t.tArgs('edit_save_failed', {'error': error}), error: true);
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (continueAfter) {
      setState(() {
        _expression = '';
        _noteController.clear();
        _date = DateTime.now();
      });
      _toast(t.t('edit_saved_continue'));
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _delete() async {
    final id = widget.record?.id;
    if (id == null) return;
    final t = AppLocalizations.of(context);
    final tx = context.read<TransactionProvider>();
    final stats = context.read<StatsProvider>();
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('edit_delete_title'),
      message: t.t('edit_delete_message'),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('common_delete'),
      destructive: true,
    );
    if (confirmed != true) return;
    await tx.delete(id);
    await stats.load();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _toast(String message, {bool error = false}) {
    showBriefSnack(
      context,
      message,
      backgroundColor:
          error ? Theme.of(context).colorScheme.error : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context
        .select<SettingsProvider, AppSettings>((provider) => provider.settings);
    final categories = context.watch<CategoryProvider>();
    final categoryList = categories.byTypeVisible(_type);

    final expenseColor = Color(settings.expenseColor);
    final incomeColor = Color(settings.incomeColor);
    final accent = _type == TxType.expense ? expenseColor : incomeColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isEditing ? t.t('edit_edit_title') : t.t('edit_new_title')),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _TypeSelector(
                type: _type,
                expenseColor: expenseColor,
                incomeColor: incomeColor,
                expenseLabel: t.t('type_expense'),
                incomeLabel: t.t('type_income'),
                onChanged: _onTypeChanged,
              ),
            ),
            _amountDisplay(t, accent),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: _noteFocus.hasFocus ? 24 : 12,
                ),
                children: [
                  if (categoryList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t.t('edit_no_category')),
                    )
                  else
                    CategoryGrid(
                      categories: categoryList,
                      selectedId: _categoryId,
                      onSelected: (Category category) =>
                          setState(() => _categoryId = category.id),
                    ),
                  const SizedBox(height: 8),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: Text(t.t('edit_date')),
                          trailing: Text(
                            DateX.toDateString(_date),
                            style: const TextStyle(fontSize: 15),
                          ),
                          onTap: _pickDate,
                        ),
                        const Divider(indent: 56, endIndent: 16),
                        Padding(
                          key: _noteKey,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: TextField(
                            controller: _noteController,
                            focusNode: _noteFocus,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _noteFocus.unfocus(),
                            decoration: InputDecoration(
                              hintText: t.t('edit_note'),
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (!_noteFocus.hasFocus)
              AmountKeypad(
                onKey: _onKey,
                onBackspace: _onBackspace,
                calculatorEnabled: settings.calculatorEnabled,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _saving ? null : () => _save(continueAfter: true),
                      icon: const Icon(Icons.playlist_add),
                      label: Text(t.t('edit_save_and_continue')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _saving ? null : () => _save(continueAfter: false),
                      icon: const Icon(Icons.check),
                      label: Text(t.t('edit_save')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountDisplay(AppLocalizations t, Color accent) {
    final value = Calculator.evaluate(_expression);
    final showResult = _expression.isNotEmpty &&
        _expression.split(RegExp(r'[+\-*/×÷]')).length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('¥',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600, color: accent)),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _expression.isEmpty ? t.t('edit_amount_hint') : _expression,
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                ),
              ),
            ],
          ),
          if (showResult && value != null)
            Text(
              '= ${Money.format((value * 100).round())}',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Expense / income switch that clearly highlights the active type.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.type,
    required this.expenseColor,
    required this.incomeColor,
    required this.expenseLabel,
    required this.incomeLabel,
    required this.onChanged,
  });

  final String type;
  final Color expenseColor;
  final Color incomeColor;
  final String expenseLabel;
  final String incomeLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segment(
            context,
            value: TxType.expense,
            label: expenseLabel,
            color: expenseColor,
            icon: Icons.arrow_upward_rounded,
          ),
          _segment(
            context,
            value: TxType.income,
            label: incomeLabel,
            color: incomeColor,
            icon: Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final selected = value == type;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? Colors.white : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
