class SavingsGoal {
  final String id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime? targetDate;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
  });

  double get progressPercent =>
      targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate?.toIso8601String().split('T')[0],
      };

  factory SavingsGoal.fromSupabase(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'],
        name: json['name'],
        targetAmount: (json['target_amount'] as num).toDouble(),
        currentAmount: (json['current_amount'] as num).toDouble(),
        targetDate: json['target_date'] != null
            ? DateTime.parse(json['target_date'])
            : null,
      );
}
