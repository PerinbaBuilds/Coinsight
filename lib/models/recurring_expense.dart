class RecurringExpense {
  final String id;
  String categoryId;
  String description;
  double amount;
  int dayOfMonth;
  bool isActive;

  RecurringExpense({
    required this.id,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.dayOfMonth,
    this.isActive = true,
  });

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'description': description,
        'amount': amount,
        'day_of_month': dayOfMonth,
        'is_active': isActive,
      };

  factory RecurringExpense.fromSupabase(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'],
        categoryId: json['category_id'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        dayOfMonth: json['day_of_month'],
        isActive: json['is_active'] ?? true,
      );
}
