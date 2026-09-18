/// JSON backup envelope. Lists are kept as raw maps so unknown fields survive
/// a round-trip and future schema versions can be migrated incrementally.
class BackupEnvelope {
  const BackupEnvelope({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.exportType,
    this.categories = const [],
    this.transactions = const [],
    this.budgets = const [],
    this.settings = const {},
  });

  final int schemaVersion;
  final String appVersion;
  final String exportedAt;
  final String exportType;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> transactions;
  final List<Map<String, Object?>> budgets;
  final Map<String, String> settings;

  Map<String, Object?> toJson() => {
        'schema_version': schemaVersion,
        'app_version': appVersion,
        'exported_at': exportedAt,
        'export_type': exportType,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
        'settings': settings,
      };

  factory BackupEnvelope.fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> list(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList();
    }

    final rawSettings = json['settings'];
    final settings = <String, String>{};
    if (rawSettings is Map) {
      rawSettings.forEach((key, value) {
        settings['$key'] = value?.toString() ?? '';
      });
    }

    return BackupEnvelope(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      appVersion: (json['app_version'] ?? 'unknown').toString(),
      exportedAt: (json['exported_at'] ?? '').toString(),
      exportType: (json['export_type'] ?? 'all').toString(),
      categories: list('categories'),
      transactions: list('transactions'),
      budgets: list('budgets'),
      settings: settings,
    );
  }
}
