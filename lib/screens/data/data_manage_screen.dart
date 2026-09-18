import 'dart:convert';

import 'package:account_new/db/app_database.dart';
import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/screens/data/export_options_screen.dart';
import 'package:account_new/screens/data/import_preview_screen.dart';
import 'package:account_new/utils/app_refresh.dart';
import 'package:account_new/utils/backup_codec.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DataManageScreen extends StatefulWidget {
  const DataManageScreen({super.key});

  @override
  State<DataManageScreen> createState() => _DataManageScreenState();
}

class _DataManageScreenState extends State<DataManageScreen> {
  bool _busy = false;

  Future<void> _importJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: AppLocalizations.of(context).t('data_import'),
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final envelope = BackupCodec.decode(content);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImportPreviewScreen(envelope: envelope),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      _toast(error.message);
    } catch (error) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)
          .tArgs('data_read_failed', {'error': error}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearAll() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showImmersiveConfirm(
      context: context,
      title: t.t('data_clear_title'),
      message: t.t('data_clear_message'),
      cancelLabel: t.t('common_cancel'),
      confirmLabel: t.t('data_clear'),
      destructive: true,
    );
    if (confirmed != true) return;
    await AppDatabase.instance.clearAll();
    if (!mounted) return;
    await refreshAllData(context);
    if (!mounted) return;
    _toast(t.t('data_cleared'));
  }

  void _toast(String message) {
    showBriefSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('data_manage'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.file_download_outlined,
                      color: scheme.primary),
                  title: Text(t.t('data_export')),
                  subtitle: Text(t.t('data_export_sub')),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportOptionsScreen(),
                    ),
                  ),
                ),
                const Divider(indent: 56, endIndent: 16),
                ListTile(
                  leading:
                      Icon(Icons.file_upload_outlined, color: scheme.primary),
                  title: Text(t.t('data_import')),
                  subtitle: Text(t.t('data_import_sub')),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _busy ? null : _importJson,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: scheme.error),
              title: Text(t.t('data_clear'),
                  style: TextStyle(color: scheme.error)),
              subtitle: Text(t.t('data_clear_sub')),
              onTap: _clearAll,
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 12),
          Text(
            t.t('data_import_tx_note'),
            style: TextStyle(color: scheme.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
