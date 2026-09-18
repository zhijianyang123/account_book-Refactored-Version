import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/utils/app_icons.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sentinel returned by [showCategoryPicker] when the user picks "无类型".
const int kNoCategory = -1;

/// Shows a bottom sheet with a category grid.
///
/// Returns a category id, [kNoCategory] for "no type", or null when cancelled.
Future<int?> showCategoryPicker(
  BuildContext context, {
  int? selectedId,
  String? type,
  String? title,
  bool allowNone = true,
}) {
  return showImmersiveSheet<int>(
    context: context,
    builder: (sheetContext) => _CategoryPickerBody(
      selectedId: selectedId,
      fixedType: type,
      title: title,
      allowNone: allowNone,
    ),
  );
}

class _CategoryPickerBody extends StatefulWidget {
  const _CategoryPickerBody({
    required this.selectedId,
    required this.fixedType,
    required this.title,
    required this.allowNone,
  });

  final int? selectedId;
  final String? fixedType;
  final String? title;
  final bool allowNone;

  @override
  State<_CategoryPickerBody> createState() => _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends State<_CategoryPickerBody> {
  late String _type = widget.fixedType ?? TxType.expense;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<CategoryProvider>();
    final categories =
        provider.byType(_type).where((c) => !c.isHidden).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
          Text(
            widget.title ?? t.t('edit_category'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (widget.fixedType == null)
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: TxType.expense, label: Text(t.t('type_expense'))),
                ButtonSegment(
                    value: TxType.income, label: Text(t.t('type_income'))),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.allowNone)
                    _Cell(
                      label: t.t('no_type'),
                      icon: Icons.remove,
                      color: Theme.of(context).colorScheme.outline,
                      selected: widget.selectedId == null,
                      onTap: () => Navigator.of(context).pop(kNoCategory),
                    ),
                  for (final category in categories)
                    _Cell(
                      label: t.categoryName(category.name),
                      icon: AppIcons.resolve(category.icon),
                      color: Color(category.color),
                      selected: category.id == widget.selectedId,
                      onTap: () => Navigator.of(context).pop(category.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  size: 24, color: selected ? Colors.white : color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
