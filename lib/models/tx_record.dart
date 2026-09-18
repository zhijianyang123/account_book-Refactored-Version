import 'package:account_new/utils/constants.dart';

/// A single ledger entry. Only expense/income are supported.
class TxRecord {
  const TxRecord({
    this.id,
    required this.type,
    required this.amountCents,
    this.categoryId,
    required this.date,
    required this.time,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int? id;
  final String type;
  final int amountCents;
  final int? categoryId;

  /// `yyyy-MM-dd`.
  final String date;

  /// `HH:mm`.
  final String time;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  bool get isDeleted => deletedAt != null && deletedAt!.isNotEmpty;

  int get signedAmountCents =>
      type == TxType.income ? amountCents : -amountCents;

  TxRecord copyWith({
    int? id,
    String? type,
    int? amountCents,
    Object? categoryId = _sentinel,
    String? date,
    String? time,
    Object? note = _sentinel,
    String? createdAt,
    String? updatedAt,
    Object? deletedAt = _sentinel,
  }) {
    return TxRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as int?,
      date: date ?? this.date,
      time: time ?? this.time,
      note: note == _sentinel ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as String?,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'date': date,
        'time': time,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory TxRecord.fromMap(Map<String, Object?> map) => TxRecord(
        id: (map['id'] as num?)?.toInt(),
        type: (map['type'] ?? TxType.expense) as String,
        amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
        categoryId: (map['category_id'] as num?)?.toInt(),
        date: (map['date'] ?? '1970-01-01') as String,
        time: (map['time'] ?? '00:00') as String,
        note: map['note'] as String?,
        createdAt: map['created_at'] as String?,
        updatedAt: map['updated_at'] as String?,
        deletedAt: map['deleted_at'] as String?,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'date': date,
        'time': time,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory TxRecord.fromJson(Map<String, Object?> json) => TxRecord(
        id: (json['id'] as num?)?.toInt(),
        type: (json['type'] ?? TxType.expense) as String,
        amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
        categoryId: (json['category_id'] as num?)?.toInt(),
        date: (json['date'] ?? '1970-01-01') as String,
        time: (json['time'] ?? '00:00') as String,
        note: json['note'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        deletedAt: json['deleted_at'] as String?,
      );

  /// Business fingerprint: date + amount + type + category + note.
  String fingerprint(String? categoryName) => [
        date,
        amountCents.toString(),
        type,
        categoryName ?? '',
        note ?? '',
      ].join('|');
}

const Object _sentinel = Object();
