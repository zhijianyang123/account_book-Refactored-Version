class Category {
  const Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'tag',
    this.color = 0xFF8E8E93,
    this.sortOrder = 0,
    this.parentId,
    this.isDefault = false,
    this.isHidden = false,
  });

  final int? id;
  final String name;

  /// [TxType.expense] or [TxType.income].
  final String type;
  final String icon;
  final int color;
  final int sortOrder;
  final int? parentId;
  final bool isDefault;
  final bool isHidden;

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    int? color,
    int? sortOrder,
    Object? parentId = _sentinel,
    bool? isDefault,
    bool? isHidden,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      parentId: parentId == _sentinel ? this.parentId : parentId as int?,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'sort_order': sortOrder,
        'parent_id': parentId,
        'is_default': isDefault ? 1 : 0,
        'is_hidden': isHidden ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int?,
        name: (map['name'] ?? '') as String,
        type: (map['type'] ?? 'expense') as String,
        icon: (map['icon'] ?? 'tag') as String,
        color: (map['color'] as num?)?.toInt() ?? 0xFF8E8E93,
        sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
        parentId: (map['parent_id'] as num?)?.toInt(),
        isDefault: ((map['is_default'] as num?)?.toInt() ?? 0) == 1,
        isHidden: ((map['is_hidden'] as num?)?.toInt() ?? 0) == 1,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'sort_order': sortOrder,
        'parent_id': parentId,
        'is_default': isDefault,
        'is_hidden': isHidden,
      };

  factory Category.fromJson(Map<String, Object?> json) => Category(
        id: (json['id'] as num?)?.toInt(),
        name: (json['name'] ?? '') as String,
        type: (json['type'] ?? 'expense') as String,
        icon: (json['icon'] ?? 'tag') as String,
        color: (json['color'] as num?)?.toInt() ?? 0xFF8E8E93,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        parentId: (json['parent_id'] as num?)?.toInt(),
        isDefault: json['is_default'] == true,
        isHidden: json['is_hidden'] == true,
      );
}

const Object _sentinel = Object();
