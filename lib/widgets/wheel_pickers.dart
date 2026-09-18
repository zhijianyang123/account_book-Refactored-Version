import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:flutter/material.dart';

/// Wheel-style year + month picker. Returns the selected month or null.
Future<DateTime?> showMonthWheelPicker(
  BuildContext context, {
  required DateTime initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _MonthPickerSheet(initial: initial),
  );
}

/// Wheel-style year / month / day picker (no time). Returns the date or null.
Future<DateTime?> showDateWheelPicker(
  BuildContext context, {
  required DateTime initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _DatePickerSheet(initial: initial),
  );
}

const int _firstYear = 2000;
const int _lastYear = 2100;

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year.clamp(_firstYear, _lastYear);
    _month = widget.initial.month;
    _yearController =
        FixedExtentScrollController(initialItem: _year - _firstYear);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    return WheelSheetShell(
      scheme: scheme,
      title: t.t('picker_select_month'),
      onCancel: () => Navigator.of(context).pop(),
      onDone: () => Navigator.of(context).pop(DateTime(_year, _month, 1)),
      child: SizedBox(
        height: 190,
        child: Row(
          children: [
            Expanded(
              child: FlatWheel(
                controller: _yearController,
                itemCount: _lastYear - _firstYear + 1,
                onSelected: (index) => _year = _firstYear + index,
                labelOf: (index) => '${_firstYear + index}',
              ),
            ),
            Expanded(
              child: FlatWheel(
                controller: _monthController,
                itemCount: 12,
                onSelected: (index) => _month = index + 1,
                labelOf: (index) => (index + 1).toString().padLeft(2, '0'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;

  int get _daysInMonth => DateX.daysInMonth(DateTime(_year, _month));

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year.clamp(_firstYear, _lastYear);
    _month = widget.initial.month;
    _day = widget.initial.day;
    _yearController =
        FixedExtentScrollController(initialItem: _year - _firstYear);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _clampDay() {
    final maxDay = _daysInMonth;
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayController.hasClients) _dayController.jumpToItem(_day - 1);
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    return WheelSheetShell(
      scheme: scheme,
      title: t.t('picker_select_date'),
      onCancel: () => Navigator.of(context).pop(),
      onDone: () => Navigator.of(context).pop(DateTime(_year, _month, _day)),
      child: SizedBox(
        height: 190,
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: FlatWheel(
                controller: _yearController,
                itemCount: _lastYear - _firstYear + 1,
                onSelected: (index) {
                  _year = _firstYear + index;
                  _clampDay();
                },
                labelOf: (index) => '${_firstYear + index}',
                suffix: t.t('picker_year_suffix'),
              ),
            ),
            Expanded(
              flex: 8,
              child: FlatWheel(
                controller: _monthController,
                itemCount: 12,
                onSelected: (index) {
                  _month = index + 1;
                  _clampDay();
                },
                labelOf: (index) => (index + 1).toString().padLeft(2, '0'),
                suffix: t.t('picker_month_suffix'),
              ),
            ),
            Expanded(
              flex: 8,
              child: FlatWheel(
                controller: _dayController,
                itemCount: _daysInMonth,
                onSelected: (index) => _day = index + 1,
                labelOf: (index) => (index + 1).toString().padLeft(2, '0'),
                suffix: t.t('picker_day_suffix'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A flat (non-magnified) scroll wheel with a rectangular centre highlight.
class FlatWheel extends StatelessWidget {
  const FlatWheel({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onSelected,
    required this.labelOf,
    this.suffix,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final ValueChanged<int> onSelected;
  final String Function(int index) labelOf;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: IgnorePointer(
              child: Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 42,
          physics: const FixedExtentScrollPhysics(),
          perspective: 0.001,
          diameterRatio: 2.6,
          overAndUnderCenterOpacity: 0.55,
          onSelectedItemChanged: onSelected,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) => Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    labelOf(index),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      suffix!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared bottom-sheet chrome for the wheel pickers.
class WheelSheetShell extends StatelessWidget {
  const WheelSheetShell({
    super.key,
    required this.scheme,
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onDone,
  });

  final ColorScheme scheme;
  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            child,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      child: Text(t.t('common_cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      child: Text(t.t('common_done')),
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
}
