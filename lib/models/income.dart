class Income {
  final String id;
  String source;
  double amount;
  DateTime date;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: json['id'],
        source: json['source'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );

  factory Income.fromSupabase(Map<String, dynamic> json) => Income(
        id: json['id'],
        source: json['source'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'source': source,
        'amount': amount,
        'date': date.toIso8601String().split('T')[0],
      };
}
