class Transaction {
  final String id;
  final String categoryId;
  String description;
  double amount;
  DateTime date;
  bool isExpense;

  Transaction({
    required this.id,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.date,
    this.isExpense = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'isExpense': isExpense,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        categoryId: json['categoryId'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        isExpense: json['isExpense'] ?? true,
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String().split('T')[0],
      };

  factory Transaction.fromSupabase(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        categoryId: json['category_id'],
        description: json['description'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        isExpense: json['is_expense'] ?? true,
      );
}
