import 'dart:convert';
import 'dart:typed_data';

import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/services/import_export_service.dart';
import 'package:account_new/utils/backup_codec.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Exports the complete ledger as a single backup file.
///
/// The only supported scenario is migrating everything to a new phone, so
/// partial scopes and "include deleted" options are intentionally omitted.
class ExportOptionsScreen extends StatefulWidget {
  const ExportOptionsScreen({super.key});

  @override
  State<ExportOptionsScreen> createState() => _ExportOptionsScreenState();
}

class _ExportOptionsScreenState extends State<ExportOptionsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = AppLocalizations.of(context);
    try {
      final envelope =
          await ImportExportService().buildExport(const ExportOptions());
      final bytes = utf8.encode(BackupCodec.encode(envelope));
      final fileName = BackupCodec.fileName(DateTime.now());
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: 'application/json',
        dialogTitle: t.t('export_dialog_title'),
      );
      if (!mounted) return;
      _toast(uri == null ? t.t('export_cancelled') : t.t('export_done'));
    } catch (error) {
      if (!mounted) return;
      _toast(t.tArgs('export_failed', {'error': error}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    showBriefSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('export_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.cloud_download_outlined,
                      size: 34, color: scheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t.t('data_export_sub'),
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t.tArgs('export_file_name',
                {'name': BackupCodec.fileName(DateTime.now())}),
            style: TextStyle(color: scheme.outline, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.save_alt),
            label: Text(t.t('export_save_local')),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
