import 'package:flutter/material.dart';

class BudgetCategory {
  final String id;
  String name;
  double budgetAmount;
  double actualAmount;
  IconData icon;
  Color color;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.budgetAmount,
    this.actualAmount = 0.0,
    required this.icon,
    required this.color,
  });

  double get variance => budgetAmount - actualAmount;
  double get variancePercent =>
      budgetAmount == 0 ? 0 : (variance / budgetAmount) * 100;
  bool get isOverBudget => actualAmount > budgetAmount;
  double get utilizationPercent =>
      budgetAmount == 0 ? 0 : (actualAmount / budgetAmount) * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budgetAmount': budgetAmount,
        'actualAmount': actualAmount,
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory(
        id: json['id'],
        name: json['name'],
        budgetAmount: (json['budgetAmount'] as num).toDouble(),
        actualAmount: (json['actualAmount'] as num).toDouble(),
        icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
        color: Color(json['colorValue']),
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'budget_amount': budgetAmount,
        'actual_amount': actualAmount,
        'icon_code': icon.codePoint,
        'color_value': color.toARGB32(),
      };

  factory BudgetCategory.fromSupabase(Map<String, dynamic> json) =>
      BudgetCategory(
        id: json['id'],
        name: json['name'],
        budgetAmount: (json['budget_amount'] as num).toDouble(),
        actualAmount: (json['actual_amount'] as num? ?? 0).toDouble(),
        icon: IconData(json['icon_code'] ?? Icons.category.codePoint,
            fontFamily: 'MaterialIcons'),
        color: Color(json['color_value'] ?? Colors.blue.value),
      );
}
