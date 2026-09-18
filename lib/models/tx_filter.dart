/// Combined filter used by the detail list and the search screen.
class TxFilter {
  const TxFilter({
    this.keyword = '',
    this.types = const <String>{},
    this.categoryIds = const <int>{},
    this.minCents,
    this.maxCents,
    this.startDate,
    this.endDate,
  });

  final String keyword;
  final Set<String> types;
  final Set<int> categoryIds;
  final int? minCents;
  final int? maxCents;

  /// `yyyy-MM-dd` inclusive lower bound.
  final String? startDate;

  /// `yyyy-MM-dd` inclusive upper bound.
  final String? endDate;

  bool get isEmpty =>
      keyword.isEmpty &&
      types.isEmpty &&
      categoryIds.isEmpty &&
      minCents == null &&
      maxCents == null &&
      startDate == null &&
      endDate == null;

  int get activeCount {
    var count = 0;
    if (keyword.isNotEmpty) count++;
    if (types.isNotEmpty) count++;
    if (categoryIds.isNotEmpty) count++;
    if (minCents != null || maxCents != null) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  TxFilter copyWith({
    String? keyword,
    Set<String>? types,
    Set<int>? categoryIds,
    Object? minCents = _sentinel,
    Object? maxCents = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return TxFilter(
      keyword: keyword ?? this.keyword,
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      minCents: minCents == _sentinel ? this.minCents : minCents as int?,
      maxCents: maxCents == _sentinel ? this.maxCents : maxCents as int?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as String?,
      endDate: endDate == _sentinel ? this.endDate : endDate as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'keyword': keyword,
        'types': types.toList(),
        'category_ids': categoryIds.toList(),
        'min_cents': minCents,
        'max_cents': maxCents,
        'start_date': startDate,
        'end_date': endDate,
      };

  factory TxFilter.fromJson(Map<String, Object?> json) {
    Set<int> ints(Object? raw) => ((raw as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toSet();
    return TxFilter(
      keyword: (json['keyword'] ?? '') as String,
      types: ((json['types'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
      categoryIds: ints(json['category_ids']),
      minCents: (json['min_cents'] as num?)?.toInt(),
      maxCents: (json['max_cents'] as num?)?.toInt(),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }

  static TxFilter forType(String type) => TxFilter(types: {type});
}

const Object _sentinel = Object();
