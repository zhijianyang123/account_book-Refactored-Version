import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/category.dart';
import 'package:account_new/providers/category_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/utils/app_icons.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  String _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<CategoryProvider>();
    final topLevel =
        provider.byType(_type).where((c) => c.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('category_manage')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context, type: _type),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: TxType.expense,
                    label: Text(t.t('category_expense_tab'))),
                ButtonSegment(
                    value: TxType.income,
                    label: Text(t.t('category_income_tab'))),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
              itemCount: topLevel.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                final list = List<Category>.from(topLevel);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                await context.read<CategoryProvider>().reorder(list);
              },
              itemBuilder: (context, index) {
                final category = topLevel[index];
                final children = provider.childrenOf(category.id!);
                return Padding(
                  key: ValueKey('category-${category.id}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _row(context, category,
                            onTap: () =>
                                _openForm(context, category: category)),
                        for (final child in children)
                          _row(context, child,
                              indented: true,
                              onTap: () =>
                                  _openForm(context, category: child)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Category category,
      {bool indented = false, required VoidCallback onTap}) {
    final t = AppLocalizations.of(context);
    final color = Color(category.color);
    return ListTile(
      contentPadding: EdgeInsets.only(left: indented ? 40 : 16, right: 16),
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Icon(AppIcons.resolve(category.icon), size: 19, color: color),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(t.categoryName(category.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (category.isHidden) ...[
            const SizedBox(width: 6),
            Text(t.t('category_label_hidden'),
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline)),
          ],
          if (category.isDefault) ...[
            const SizedBox(width: 6),
            Text(t.t('category_label_default'),
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline)),
          ],
        ],
      ),
      trailing: const Icon(Icons.drag_handle, size: 20),
    );
  }

  Future<void> _openForm(BuildContext context,
      {Category? category, String? type}) async {
    await showImmersiveSheet<bool>(
      context: context,
      builder: (_) =>
          _CategoryForm(category: category, type: type ?? _type),
    );
    if (context.mounted) {
      await context.read<StatsProvider>().load();
    }
  }
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.category, required this.type});

  final Category? category;
  final String type;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _nameController;
  late String _icon;
  late int _color;
  late bool _isHidden;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _icon = category?.icon ?? 'label';
    _color = category?.color ?? 0xFF0A59F7;
    _isHidden = category?.isHidden ?? false;
    _parentId = category?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast(t.t('category_error_name'));
      return;
    }
    final provider = context.read<CategoryProvider>();
    final category = Category(
      id: widget.category?.id,
      name: name,
      type: widget.category?.type ?? widget.type,
      icon: _icon,
      color: _color,
      sortOrder: widget.category?.sortOrder ?? 999,
      parentId: _parentId,
      isDefault: widget.category?.isDefault ?? false,
      isHidden: _isHidden,
    );
    if (widget.category == null) {
      await provider.add(category);
    } else {
      await provider.update(category);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final id = widget.category?.id;
    if (id == null) return;
    final provider = context.read<CategoryProvider>();
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('category_delete_title'),
      message: t.t('category_delete_message'),
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
    final provider = context.watch<CategoryProvider>();
    final type = widget.category?.type ?? widget.type;
    final parents = provider
        .byType(type)
        .where((c) => c.parentId == null && c.id != widget.category?.id)
        .toList();

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
          Text(widget.category == null ? t.t('category_add') : t.t('category_edit'),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration:
                        InputDecoration(hintText: t.t('category_name')),
                  ),
                  const SizedBox(height: 14),
                  _label(t.t('category_parent')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(t.t('common_none')),
                        selected: _parentId == null,
                        onSelected: (_) => setState(() => _parentId = null),
                      ),
                      for (final parent in parents)
                        ChoiceChip(
                          label: Text(parent.name),
                          selected: _parentId == parent.id,
                          onSelected: (_) =>
                              setState(() => _parentId = parent.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.t('category_hide')),
                    value: _isHidden,
                    onChanged: (value) => setState(() => _isHidden = value),
                  ),
                  _label(t.t('category_icon')),
                  SizedBox(
                    height: 100,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: Defaults.iconPalette.length,
                      itemBuilder: (context, index) {
                        final name = Defaults.iconPalette[index];
                        final selected = name == _icon;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _icon = name),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? Color(_color)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(AppIcons.resolve(name),
                                size: 18,
                                color: selected
                                    ? Colors.white
                                    : Color(_color)),
                          ),
                        );
                      },
                    ),
                  ),
                  _label(t.t('category_color')),
                  _colorPicker(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (widget.category != null) ...[
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

  Widget _colorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final raw in Defaults.colorPalette)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _color = int.parse(raw)),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(int.parse(raw)),
                shape: BoxShape.circle,
                border: _color == int.parse(raw)
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 3)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
