import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/budget.dart';
import 'package:account_new/providers/budget_provider.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BudgetManageScreen extends StatelessWidget {
  const BudgetManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<BudgetProvider>();
    final categories = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('budget_manage')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          if (provider.budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Text(t.t('stats_no_budget'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outline)),
              ),
            )
          else
            for (final budget in provider.budgets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BudgetCard(
                  budget: budget,
                  usage: provider.usageOf(budget),
                  remaining: provider.remainingOf(budget),
                  dailyAvailable: provider.dailyAvailableOf(budget),
                  overspent: provider.overspentOf(budget),
                  categoryName: budget.categoryId == null
                      ? null
                      : t.categoryName(categories
                              .find(budget.categoryId)
                              ?.name ??
                          t.t('no_type')),
                  onTap: () => _openForm(context, budget: budget),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Budget? budget}) async {
    final budgets = context.read<BudgetProvider>();
    final stats = context.read<StatsProvider>();
    await showImmersiveSheet<bool>(
      context: context,
      builder: (_) => _BudgetForm(budget: budget),
    );
    await budgets.load();
    await stats.load();
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.usage,
    required this.remaining,
    required this.dailyAvailable,
    required this.overspent,
    required this.categoryName,
    required this.onTap,
  });

  final Budget budget;
  final int usage;
  final int remaining;
  final int dailyAvailable;
  final bool overspent;
  final String? categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final statusColor =
        overspent ? scheme.error : const Color(0xFF1FA971);
    final ratio = budget.amountCents == 0
        ? 0.0
        : (usage / budget.amountCents).clamp(0.0, 1.0);

    final title = budget.categoryId == null
        ? _periodLabel(t, budget.periodType)
        : t.tArgs('budget_category_label', {'name': categoryName ?? t.t('no_type')});

    return LightFollowCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${DateX.toDateString(DateX.parseDate(budget.startDate))} ~ ${DateX.toDateString(DateX.parseDate(budget.endDate))}',
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(t.tArgs('budget_used_label', {'amount': Money.format(usage)}),
                  style: TextStyle(color: statusColor, fontSize: 13)),
              const Spacer(),
              Text(
                  t.tArgs(
                      'budget_amount_label', {'amount': Money.format(budget.amountCents)}),
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overspent
                ? t.tArgs('budget_overspent_label',
                    {'amount': Money.format(remaining.abs())})
                : t.tArgs('budget_remaining_label', {
                    'amount': Money.format(remaining),
                    'daily': Money.format(dailyAvailable),
                  }),
            style: TextStyle(color: statusColor, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  String _periodLabel(AppLocalizations t, String period) {
    switch (period) {
      case BudgetPeriod.year:
        return t.t('period_year');
      case BudgetPeriod.custom:
        return t.t('period_custom');
      default:
        return t.t('period_month');
    }
  }
}

class _BudgetForm extends StatefulWidget {
  const _BudgetForm({this.budget});

  final Budget? budget;

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  late final TextEditingController _amountController;
  late String _periodType;
  int? _categoryId;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _amountController = TextEditingController(
      text: budget == null
          ? ''
          : Money.centsToAmount(budget.amountCents).toString(),
    );
    _periodType = budget?.periodType ?? BudgetPeriod.month;
    _categoryId = budget?.categoryId;
    final now = DateTime.now();
    _startDate = budget == null
        ? DateX.startOfMonth(now)
        : DateX.parseDate(budget.startDate);
    _endDate = budget == null
        ? DateX.endOfMonthExclusive(now).subtract(const Duration(days: 1))
        : DateX.parseDate(budget.endDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyPeriod(String type) {
    final now = DateTime.now();
    setState(() {
      _periodType = type;
      if (type == BudgetPeriod.month) {
        _startDate = DateX.startOfMonth(now);
        _endDate =
            DateX.endOfMonthExclusive(now).subtract(const Duration(days: 1));
      } else if (type == BudgetPeriod.year) {
        _startDate = DateX.startOfYear(now);
        _endDate =
            DateX.endOfYearExclusive(now).subtract(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
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

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final amount = Money.parseToCents(_amountController.text);
    if (amount == null || amount <= 0) {
      _toast(t.t('budget_error_amount'));
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _toast(t.t('budget_error_date'));
      return;
    }
    final provider = context.read<BudgetProvider>();
    final budget = Budget(
      id: widget.budget?.id,
      periodType: _periodType,
      amountCents: amount,
      categoryId: _categoryId,
      startDate: DateX.toDateString(_startDate),
      endDate: DateX.toDateString(_endDate),
    );
    if (widget.budget == null) {
      await provider.add(budget);
    } else {
      await provider.update(budget);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final id = widget.budget?.id;
    if (id == null) return;
    final provider = context.read<BudgetProvider>();
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('budget_delete_title'),
      message: t.t('budget_delete_message'),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('common_delete'),
      destructive: true,
    );
    if (confirmed != true) return;
    await provider.delete(id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _toast(String message) {
    showBriefSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categories = context.watch<CategoryProvider>().categories;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.budget == null ? t.t('budget_add') : t.t('budget_edit'),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(t.t('budget_period')),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in BudgetPeriod.all)
                        ChoiceChip(
                          label: Text(_periodLabel(t, type)),
                          selected: _periodType == type,
                          onSelected: (_) => _applyPeriod(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      hintText: t.t('budget_amount'),
                      prefixText: '¥ ',
                    ),
                  ),
                  _label(t.t('budget_category_optional')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(t.t('budget_total')),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                       for (final category in categories)
                         ChoiceChip(
                           label: Text(t.categoryName(category.name)),
                          selected: _categoryId == category.id,
                          onSelected: (_) =>
                              setState(() => _categoryId = category.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(t.t('budget_start_date')),
                    trailing: Text(DateX.toDateString(_startDate)),
                    onTap: () => _pickDate(true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(t.t('budget_end_date')),
                    trailing: Text(DateX.toDateString(_endDate)),
                    onTap: () => _pickDate(false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (widget.budget != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    label: Text(t.t('common_delete'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(t.t('common_save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  String _periodLabel(AppLocalizations t, String period) {
    switch (period) {
      case BudgetPeriod.year:
        return t.t('period_year');
      case BudgetPeriod.custom:
        return t.t('period_custom');
      default:
        return t.t('period_month');
    }
  }
}
