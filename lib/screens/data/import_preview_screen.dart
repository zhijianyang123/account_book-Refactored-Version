import 'dart:convert';
import 'dart:typed_data';

import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/backup_envelope.dart';
import 'package:account_new/models/import_models.dart';
import 'package:account_new/services/import_export_service.dart';
import 'package:account_new/utils/app_refresh.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Previews a full backup and imports it by replacing the current ledger.
///
/// Designed for migrating data to a new phone, so existing data handling and
/// per-type conflict options are intentionally omitted.
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, required this.envelope});

  final BackupEnvelope envelope;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  final ImportExportService _service = ImportExportService();

  ImportPreview? _preview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() async {
    final preview = await _service.buildPreview(widget.envelope);
    if (!mounted) return;
    setState(() => _preview = preview);
  }

  Future<void> _execute() async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('import_overwrite_title'),
      message: t.t('import_overwrite_message'),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('import_overwrite_confirm'),
      destructive: true,
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final result = await _service.execute(
      widget.envelope,
      const ImportOptions(mode: ImportMode.overwrite),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.failed) await refreshAllData(context);
    if (!mounted) return;
    await _showResult(result);
    if (mounted && !result.failed) Navigator.of(context).maybePop();
  }

  Future<void> _showResult(ImportResult result) {
    final t = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(result.failed ? t.t('import_failed') : t.t('import_done')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _resultLine(t.t('import_count_categories'),
                  result.categoriesInserted),
              _resultLine(t.t('import_count_budgets'), result.budgetsInserted),
              _resultLine(
                  t.t('import_count_transactions'), result.transactionsInserted),
              _resultLine(t.t('import_skipped'), result.skipped),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(t.t('errors'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                for (final error in result.errors) _bullet(error),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(t.t('warnings'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                for (final warning in result.warnings) _bullet(warning),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveReport(result),
            child: Text(t.t('import_export_report')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.t('common_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReport(ImportResult result) async {
    final t = AppLocalizations.of(context);
    try {
      final bytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(result.toReportJson()));
      await FilePicker.saveFile(
        fileName: 'import_report_${DateX.fileTimestamp(DateTime.now())}.json',
        bytes: Uint8List.fromList(bytes),
        mimeType: 'application/json',
      );
    } catch (error) {
      if (!mounted) return;
      showBriefSnack(
        context,
        t.tArgs('import_report_failed', {'error': error}),
      );
    }
  }

  Widget _resultLine(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text('$value',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text('· $text', style: const TextStyle(fontSize: 12.5)),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final preview = _preview;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('import_title'))),
      body: preview == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.t('import_backup_content'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        _resultLine(
                            t.t('import_count_categories'), preview.categoryCount),
                        _resultLine(t.t('import_count_transactions'),
                            preview.transactionCount),
                        _resultLine(
                            t.t('import_count_budgets'), preview.budgetCount),
                        const SizedBox(height: 8),
                        Text(
                          t.tArgs('import_date_range', {
                            'range':
                                '${preview.earliestDate == null ? '—' : DateX.toDateString(preview.earliestDate!)} ~ ${preview.latestDate == null ? '—' : DateX.toDateString(preview.latestDate!)}',
                          }),
                          style:
                              TextStyle(color: scheme.outline, fontSize: 12.5),
                        ),
                        Text(
                          t.tArgs('import_versions', {
                            'schema': preview.schemaVersion,
                            'app': preview.appVersion,
                          }),
                          style:
                              TextStyle(color: scheme.outline, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.t('data_import_sub'),
                  style: TextStyle(color: scheme.outline, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _execute,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: Text(
                      _busy ? t.t('import_importing') : t.t('import_start')),
                ),
              ],
            ),
    );
  }
}
