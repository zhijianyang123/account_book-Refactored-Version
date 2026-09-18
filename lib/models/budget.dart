class Budget {
  const Budget({
    this.id,
    required this.periodType,
    required this.amountCents,
    this.categoryId,
    required this.startDate,
    required this.endDate,
  });

  final int? id;

  /// [BudgetPeriod.month], [BudgetPeriod.year] or [BudgetPeriod.custom].
  final String periodType;
  final int amountCents;
  final int? categoryId;

  /// `yyyy-MM-dd`, inclusive.
  final String startDate;

  /// `yyyy-MM-dd`, inclusive.
  final String endDate;

  bool get isCategoryBudget => categoryId != null;

  Budget copyWith({
    int? id,
    String? periodType,
    int? amountCents,
    Object? categoryId = _sentinel,
    String? startDate,
    String? endDate,
  }) {
    return Budget(
      id: id ?? this.id,
      periodType: periodType ?? this.periodType,
      amountCents: amountCents ?? this.amountCents,
      categoryId:
          categoryId == _sentinel ? this.categoryId : categoryId as int?,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'period_type': periodType,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'start_date': startDate,
        'end_date': endDate,
      };

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
        id: (map['id'] as num?)?.toInt(),
        periodType: (map['period_type'] ?? 'month') as String,
        amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
        categoryId: (map['category_id'] as num?)?.toInt(),
        startDate: (map['start_date'] ?? '1970-01-01') as String,
        endDate: (map['end_date'] ?? '1970-01-01') as String,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'period_type': periodType,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'start_date': startDate,
        'end_date': endDate,
      };

  factory Budget.fromJson(Map<String, Object?> json) => Budget(
        id: (json['id'] as num?)?.toInt(),
        periodType: (json['period_type'] ?? 'month') as String,
        amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
        categoryId: (json['category_id'] as num?)?.toInt(),
        startDate: (json['start_date'] ?? '1970-01-01') as String,
        endDate: (json['end_date'] ?? '1970-01-01') as String,
      );
}

const Object _sentinel = Object();
