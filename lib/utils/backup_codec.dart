import 'dart:convert';

import 'package:account_new/models/backup_envelope.dart';

/// Reads/writes the backup JSON document and handles schema-version checks.
class BackupCodec {
  BackupCodec._();

  static const int currentSchemaVersion = 1;
  static const String appVersion = '1.0.0';

  static const String fileNamePrefix = '记账本备份';

  static String encode(BackupEnvelope envelope) =>
      const JsonEncoder.withIndent('  ').convert(envelope.toJson());

  /// Throws [FormatException] when the payload is not a valid backup.
  static BackupEnvelope decode(String source) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const FormatException('文件不是有效的 JSON');
    }
    if (decoded is! Map) {
      throw const FormatException('JSON 根节点必须是对象');
    }
    final json = decoded.cast<String, Object?>();
    if (!json.containsKey('schema_version')) {
      throw const FormatException('缺少 schema_version，可能不是记账本备份文件');
    }
    final envelope = BackupEnvelope.fromJson(json);
    if (envelope.schemaVersion > currentSchemaVersion) {
      throw FormatException(
        '备份版本（v${envelope.schemaVersion}）高于当前应用支持的版本（v$currentSchemaVersion），请先升级应用',
      );
    }
    // Future: migrate older schema versions here.
    return envelope;
  }

  /// `记账本备份_YYYYMMDD_HHmmss.json`
  static String fileName(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
    return '${fileNamePrefix}_$stamp.json';
  }
}
