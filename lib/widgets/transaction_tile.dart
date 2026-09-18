import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/category.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/utils/app_icons.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/money.dart';
import 'package:flutter/material.dart';

/// One ledger row.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.record,
    required this.category,
    required this.noTypeLabel,
    required this.expenseColor,
    required this.incomeColor,
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final TxRecord record;
  final Category? category;
  final String noTypeLabel;
  final Color expenseColor;
  final Color incomeColor;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  bool get _isIncome => record.type == TxType.income;

  String get _amountText {
    final value = Money.format(record.amountCents);
    return _isIncome ? '+$value' : '-$value';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category == null
        ? scheme.outline
        : Color(category!.color);
    final note = record.note?.trim() ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      onLongPress: onLongPress,
      leading: selectionMode
          ? Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outline,
            )
          : Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(AppIcons.resolve(category?.icon),
                  size: 21, color: color),
            ),
      title: Text(
        category == null
            ? noTypeLabel
            : AppLocalizations.of(context).categoryName(category!.name),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
      ),
      subtitle: note.isEmpty
          ? null
          : Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Text(
        _amountText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _isIncome ? incomeColor : expenseColor,
        ),
      ),
    );
  }
}
