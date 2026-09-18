/// Aggregated values used by the statistics screen.
class CategoryStat {
  const CategoryStat({
    required this.id,
    required this.name,
    required this.amountCents,
  });

  final int? id;
  final String name;
  final int amountCents;
}

class TrendPoint {
  const TrendPoint({
    required this.start,
    required this.label,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime start;
  final String label;
  final int incomeCents;
  final int expenseCents;
}

/// A time bucket for the trend charts.
class StatsBucket {
  const StatsBucket({
    required this.start,
    required this.endExclusive,
    required this.label,
  });

  final DateTime start;
  final DateTime endExclusive;
  final String label;
}
