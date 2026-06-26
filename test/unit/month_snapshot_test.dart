import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/month_snapshot.dart';

void main() {
  group('MonthSnapshot.fromSupabase', () {
    final baseJson = {
      'id': 'snap-1',
      'month_key': '2026-06',
      'total_budget': 1000.0,
      'total_spent': 750.0,
      'total_income': 2500.0,
      'category_spending': <String, dynamic>{
        'Food': 300.0,
        'Transport': 150.0,
        '__b__Food': 400.0,
        '__b__Transport': 200.0,
        '__tx__': [
          {
            'date': '2026-06-05',
            'description': 'Groceries',
            'amount': 85.0,
            'category': 'Food',
          },
        ],
      },
    };

    test('parses category spending correctly', () {
      final snap = MonthSnapshot.fromSupabase(baseJson);
      expect(snap.categorySpending['Food'], 300.0);
      expect(snap.categorySpending['Transport'], 150.0);
      expect(snap.categorySpending.containsKey('__b__Food'), false);
    });

    test('parses category budgets from prefixed keys', () {
      final snap = MonthSnapshot.fromSupabase(baseJson);
      expect(snap.categoryBudgets['Food'], 400.0);
      expect(snap.categoryBudgets['Transport'], 200.0);
    });

    test('parses transactions list', () {
      final snap = MonthSnapshot.fromSupabase(baseJson);
      expect(snap.transactions.length, 1);
      expect(snap.transactions.first['description'], 'Groceries');
      expect(snap.transactions.first['amount'], 85.0);
    });

    test('variance = budget - spent', () {
      final snap = MonthSnapshot.fromSupabase(baseJson);
      expect(snap.variance, 250.0);
    });

    test('netSavings = income - spent', () {
      final snap = MonthSnapshot.fromSupabase(baseJson);
      expect(snap.netSavings, 1750.0);
    });

    test('backward-compatible: old records without prefixes still parse', () {
      final oldJson = {
        'id': 'old-1',
        'month_key': '2026-05',
        'total_budget': 500.0,
        'total_spent': 300.0,
        'total_income': 1000.0,
        'category_spending': <String, dynamic>{'Food': 200.0, 'Bills': 100.0},
      };
      final snap = MonthSnapshot.fromSupabase(oldJson);
      expect(snap.categorySpending['Food'], 200.0);
      expect(snap.categoryBudgets.isEmpty, true);
      expect(snap.transactions.isEmpty, true);
    });
  });

  group('MonthSnapshot.toSupabase', () {
    test('round-trips spending + budgets + transactions', () {
      final snap = MonthSnapshot(
        id: 'snap-2',
        monthKey: '2026-06',
        totalBudget: 800.0,
        totalSpent: 600.0,
        totalIncome: 2000.0,
        categorySpending: {'Food': 300.0, 'Transport': 150.0},
        categoryBudgets: {'Food': 400.0, 'Transport': 200.0},
        transactions: [
          {'date': '2026-06-10', 'description': 'Lunch', 'amount': 12.5, 'category': 'Food'},
        ],
      );

      final map = snap.toSupabase('user-123');
      final combined = map['category_spending'] as Map<String, dynamic>;

      expect(combined['Food'], 300.0);
      expect(combined['__b__Food'], 400.0);
      expect(combined['__b__Transport'], 200.0);
      expect((combined['__tx__'] as List).length, 1);
    });

    test('omits __tx__ when transactions are empty', () {
      final snap = MonthSnapshot(
        id: 'snap-3',
        monthKey: '2026-06',
        totalBudget: 500.0,
        totalSpent: 200.0,
        totalIncome: 1000.0,
        categorySpending: {'Food': 200.0},
        categoryBudgets: {'Food': 300.0},
      );
      final map = snap.toSupabase('user-123');
      final combined = map['category_spending'] as Map<String, dynamic>;
      expect(combined.containsKey('__tx__'), false);
    });
  });
}
