/// Shared enums and default seed data.
class TxType {
  TxType._();
  static const String expense = 'expense';
  static const String income = 'income';

  static const List<String> all = [expense, income];
}

class BudgetPeriod {
  BudgetPeriod._();
  static const String month = 'month';
  static const String year = 'year';
  static const String custom = 'custom';

  static const List<String> all = [month, year, custom];
}

/// A category definition used to seed the database.
class SeedCategory {
  const SeedCategory(this.name, this.type, this.icon, this.color);
  final String name;
  final String type;
  final String icon;
  final int color;
}

class Defaults {
  Defaults._();

  static const int expenseColor = 0xFFFF3B30;
  static const int incomeColor = 0xFF34C759;

  static const List<SeedCategory> expenseCategories = [
    SeedCategory('餐饮', TxType.expense, 'restaurant', 0xFFFF9500),
    SeedCategory('交通', TxType.expense, 'directions_car', 0xFF007AFF),
    SeedCategory('购物', TxType.expense, 'shopping_bag', 0xFFFF2D55),
    SeedCategory('居家', TxType.expense, 'home', 0xFF5856D6),
    SeedCategory('娱乐', TxType.expense, 'sports_esports', 0xFFAF52DE),
    SeedCategory('医疗', TxType.expense, 'medical_services', 0xFF00C7BE),
  ];

  static const List<SeedCategory> incomeCategories = [
    SeedCategory('工资', TxType.income, 'payments', 0xFF34C759),
    SeedCategory('奖金', TxType.income, 'card_giftcard', 0xFF30B0C7),
    SeedCategory('理财', TxType.income, 'trending_up', 0xFF007AFF),
    SeedCategory('其他收入', TxType.income, 'add_circle', 0xFF8E8E93),
  ];

  static const List<SeedCategory> allCategories = [
    ...expenseCategories,
    ...incomeCategories,
  ];

  static const Map<String, String> defaultSettings = {
    'theme_mode': 'system',
    'locale': 'zh',
    'currency': 'CNY',
    'first_weekday': '1',
    'default_tx_type': TxType.expense,
    'save_and_continue': 'false',
    'calculator_enabled': 'true',
    'auto_zero': 'false',
    'expense_color': '$expenseColor',
    'income_color': '$incomeColor',
  };

  static const List<String> colorPalette = [
    '0xFFFF3B30',
    '0xFFFF9500',
    '0xFFFFCC00',
    '0xFF34C759',
    '0xFF00C7BE',
    '0xFF30B0C7',
    '0xFF007AFF',
    '0xFF5856D6',
    '0xFFAF52DE',
    '0xFFFF2D55',
    '0xFF8E8E93',
    '0xFF1C1C1E',
  ];

  static const List<String> iconPalette = [
    'restaurant', 'directions_car', 'shopping_bag', 'home', 'sports_esports',
    'medical_services', 'payments', 'card_giftcard', 'trending_up',
    'add_circle', 'local_cafe', 'local_grocery_store', 'flight', 'hotel',
    'phone_iphone', 'wifi', 'tv', 'headphones', 'menu_book', 'movie', 'music_note',
    'fitness_center', 'pets', 'child_care', 'school', 'work', 'build', 'brush',
    'local_gas_station', 'local_parking', 'directions_bus', 'train',
    'local_hospital', 'spa', 'checkroom', 'redeem', 'savings', 'account_balance',
    'credit_card', 'receipt_long', 'subscriptions', 'sports_soccer', 'beach_access',
    'celebration', 'cake', 'local_florist', 'water_drop', 'bolt', 'shield',
    'star', 'favorite', 'label', 'attach_money',
  ];
}
