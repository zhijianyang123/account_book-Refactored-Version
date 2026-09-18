import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/utils/backup_codec.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';

/// 关于：版本号、开源许可。
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('about'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 40),
        children: [
          Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.menu_book,
                    size: 38, color: scheme.primary),
              ),
              const SizedBox(height: 12),
              Text(t.t('app_name'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                t.tArgs('about_version', {'version': BackupCodec.appVersion}),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.description_outlined,
                      color: scheme.primary),
                  title: Text(t.t('about_licenses')),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _LicensesScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              t.t('about_local_note'),
              style: TextStyle(color: scheme.outline, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicensesScreen extends StatelessWidget {
  const _LicensesScreen();

  static const List<(String, String)> _packages = [
    ('Flutter', 'BSD-3-Clause'),
    ('provider', 'MIT'),
    ('sqflite', 'BSD-2-Clause'),
    ('fl_chart', 'MIT'),
    ('intl', 'BSD-3-Clause'),
    ('file_picker', 'MIT'),
    ('keframe', 'MIT'),
    ('collection', 'BSD-3-Clause'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('about_licenses_title'))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        itemCount: _packages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (name, license) = _packages[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text(name),
              subtitle: Text(license),
              trailing: Text(
                t.t('about_view'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, fontSize: 13),
              ),
              onTap: () => _showLicenseText(context, name, license),
            ),
          );
        },
      ),
    );
  }

  void _showLicenseText(
      BuildContext context, String name, String license) {
    final t = AppLocalizations.of(context);
    showImmersiveSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.tArgs('about_license_title', {
                'name': name,
                'license': license,
              }), style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                t.tArgs('about_license_body', {
                  'name': name,
                  'license': license,
                }),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(t.t('about_got_it')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
