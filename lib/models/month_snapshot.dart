class MonthSnapshot {
  final String id;
  final String monthKey;
  final double totalBudget;
  final double totalSpent;
  final double totalIncome;
  final Map<String, double> categorySpending;
  final Map<String, double> categoryBudgets;
  final List<Map<String, dynamic>> transactions;

  MonthSnapshot({
    required this.id,
    required this.monthKey,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalIncome,
    required this.categorySpending,
    this.categoryBudgets = const {},
    this.transactions = const [],
  });

  double get variance => totalBudget - totalSpent;
  double get netSavings => totalIncome - totalSpent;

  Map<String, dynamic> toSupabase(String userId) {
    final combined = <String, dynamic>{
      for (final e in categorySpending.entries) e.key: e.value,
      for (final e in categoryBudgets.entries) '__b__${e.key}': e.value,
      if (transactions.isNotEmpty) '__tx__': transactions,
    };
    return {
      'id': id,
      'user_id': userId,
      'month_key': monthKey,
      'total_budget': totalBudget,
      'total_spent': totalSpent,
      'total_income': totalIncome,
      'category_spending': combined,
    };
  }

  factory MonthSnapshot.fromSupabase(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json['category_spending'] as Map? ?? {});
    final spending = <String, double>{};
    final budgets = <String, double>{};
    final txList = <Map<String, dynamic>>[];

    for (final entry in raw.entries) {
      final k = entry.key.toString();
      final v = entry.value;
      if (k == '__tx__') {
        txList.addAll((v as List).map((e) => Map<String, dynamic>.from(e as Map)));
      } else if (k.startsWith('__b__')) {
        budgets[k.substring(5)] = (v as num).toDouble();
      } else if (v is num) {
        spending[k] = v.toDouble();
      }
    }

    return MonthSnapshot(
      id: json['id'],
      monthKey: json['month_key'],
      totalBudget: (json['total_budget'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalIncome: (json['total_income'] as num).toDouble(),
      categorySpending: spending,
      categoryBudgets: budgets,
      transactions: txList,
    );
  }
}
