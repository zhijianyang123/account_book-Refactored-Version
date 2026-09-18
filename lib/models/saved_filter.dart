import 'dart:convert';

import 'package:account_new/models/tx_filter.dart';

class SavedFilter {
  const SavedFilter({
    this.id,
    required this.name,
    required this.filter,
  });

  final int? id;
  final String name;
  final TxFilter filter;

  SavedFilter copyWith({int? id, String? name, TxFilter? filter}) =>
      SavedFilter(
        id: id ?? this.id,
        name: name ?? this.name,
        filter: filter ?? this.filter,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'payload': jsonEncode(filter.toJson()),
      };

  factory SavedFilter.fromMap(Map<String, Object?> map) {
    Map<String, Object?> payload = const {};
    final raw = map['payload'];
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        payload = decoded.cast<String, Object?>();
      }
    }
    return SavedFilter(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] ?? '') as String,
      filter: TxFilter.fromJson(payload),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'filter': filter.toJson(),
      };

  factory SavedFilter.fromJson(Map<String, Object?> json) => SavedFilter(
        id: (json['id'] as num?)?.toInt(),
        name: (json['name'] ?? '') as String,
        filter: TxFilter.fromJson(
          ((json['filter'] as Map?) ?? const {}).cast<String, Object?>(),
        ),
      );
}
