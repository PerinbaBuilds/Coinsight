import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';
import '../models/recurring_expense.dart';
import '../models/month_snapshot.dart';

class FinanceService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  bool _isLoading = false;
  bool _isDarkMode = false;
  String _currency = 'USD';

  // Exchange rates: 1 USD == _rates[code] units of that currency. All amounts
  // are stored in USD; these are only used to convert for display and to
  // convert user-entered values back to USD. Seeded with sensible fallbacks so
  // conversion works offline, then refreshed from a live feed on startup.
  Map<String, double> _rates = const {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 85.0,
    'JPY': 157.0,
    'CAD': 1.37,
  };

  FinanceService() {
    _restoreLocalPrefs();
    _refreshRates();
  }

  List<BudgetCategory> _categories = [];
  List<Transaction> _transactions = [];
  List<Income> _incomes = [];
  List<SavingsGoal> _goals = [];
  List<RecurringExpense> _recurring = [];
  List<MonthSnapshot> _monthHistory = [];
  Map<String, double> _nextMonthBudgets = {};
  double _totalMonthlyBudget = 5000.0;

  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;

  Map<String, String> get availableCurrencies => const {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'C\$',
  };

  String get currencySymbol => availableCurrencies[_currency] ?? '\$';

  // 1 USD expressed in the active currency. Amounts are stored in USD.
  double get fxRate => _rates[_currency] ?? 1.0;
  // USD → active currency (for display).
  double toDisplay(double usd) => usd * fxRate;
  // active currency → USD (for values the user typed in).
  double toBase(double amount) => fxRate == 0 ? amount : amount / fxRate;

  // Formats a USD amount in the active currency: symbol + converted value.
  String money(double usd,
      {int decimals = 2, bool compact = false, bool signed = false}) {
    final v = usd * fxRate;
    final abs = v.abs();
    final sign = v < 0 ? '-' : (signed ? '+' : '');
    if (compact && abs >= 1000) {
      return '$sign$currencySymbol${(abs / 1000).toStringAsFixed(1)}k';
    }
    return '$sign$currencySymbol${abs.toStringAsFixed(decimals)}';
  }

  List<BudgetCategory> get categories => List.unmodifiable(_categories);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Income> get incomes => List.unmodifiable(_incomes);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  List<RecurringExpense> get recurring => List.unmodifiable(_recurring);
  List<MonthSnapshot> get monthHistory => List.unmodifiable(_monthHistory);
  Map<String, double> get nextMonthBudgets =>
      Map.unmodifiable(_nextMonthBudgets);
  double get totalMonthlyBudget => _totalMonthlyBudget;

  double get totalActualSpent =>
      _categories.fold(0, (sum, c) => sum + c.actualAmount);
  double get totalIncome =>
      _incomes.fold(0, (sum, i) => sum + i.amount);
  double get totalVariance => _totalMonthlyBudget - totalActualSpent;
  double get netSavings => totalIncome - totalActualSpent;
  bool get isOverBudget => totalActualSpent > _totalMonthlyBudget;
  bool get isBudgetLocked => DateTime.now().day > 7;
  int get budgetWindowDaysLeft => (7 - DateTime.now().day).clamp(0, 7);
  double get nextMonthTotal =>
      _nextMonthBudgets.values.fold(0, (sum, v) => sum + v);

  String? _cachedUserId;

  // Falls back to the SDK getter for cases (app resume, deep links) where
  // setUserId() hasn't been called explicitly, but prefers the cached value
  // since Supabase's currentUser can lag behind a just-completed sign-in.
  String? get _userId => _cachedUserId ?? _supabase.auth.currentUser?.id;

  void setUserId(String? id) => _cachedUserId = id;

  Future<void>? _inFlightLoad;

  // A sign-in triggers loadData() from two places: the screen that submitted
  // the form, and _AuthGate's auth-state listener reacting to the same
  // signedIn event. Without this guard both run concurrently and double
  // every network request.
  Future<void> loadData() {
    return _inFlightLoad ??= _loadDataInternal().whenComplete(() {
      _inFlightLoad = null;
    });
  }

  Future<void> _loadDataInternal() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSettings();
    } catch (e) {
      debugPrint('Settings load (non-fatal): $e');
    }

    try {
      await Future.wait([
        _loadCategories(),
        _loadTransactions(),
        _loadIncomes(),
        _loadGoals(),
        _loadRecurring(),
        _loadMonthHistory(),
        _loadNextMonthBudgets(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (_categories.isEmpty) {
        // Try to persist defaults to Supabase; fall back to local-only if that also fails
        try {
          await _initDefaultCategoriesRemote();
        } catch (_) {
          _initDefaultCategories();
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final res = await _supabase
        .from('user_settings')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();
    if (res != null) {
      _totalMonthlyBudget =
          (res['total_monthly_budget'] as num? ?? 5000).toDouble();
      final serverDark = res['is_dark_mode'];
      if (serverDark is bool) _isDarkMode = serverDark;
      // Only adopt the server currency when it's actually present, so a missing
      // column or an unsynced row can't clobber the locally-cached choice.
      final serverCurrency = res['currency'] as String?;
      if (serverCurrency != null &&
          availableCurrencies.containsKey(serverCurrency)) {
        _currency = serverCurrency;
      }
      await _saveLocalPrefs();
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;
    // Without an explicit onConflict target, Postgrest falls back to the
    // table's primary key for the upsert's ON CONFLICT clause. If user_id
    // isn't that primary key, Postgres can't resolve the conflict and
    // rejects the request with a 400 — so the unique column must be named.
    await _supabase.from('user_settings').upsert({
      'user_id': _userId,
      'total_monthly_budget': _totalMonthlyBudget,
      'is_dark_mode': _isDarkMode,
      'currency': _currency,
    }, onConflict: 'user_id');
  }

  Future<void> _loadCategories() async {
    final res = await _supabase
        .from('categories')
        .select()
        .eq('user_id', _userId!)
        .order('created_at');
    if ((res as List).isEmpty) {
      await _initDefaultCategoriesRemote();
      // Re-fetch so local UUIDs are guaranteed to match what Supabase stored
      final fresh = await _supabase
          .from('categories')
          .select()
          .eq('user_id', _userId!)
          .order('created_at');
      if ((fresh as List).isNotEmpty) {
        _categories = fresh.map((e) => BudgetCategory.fromSupabase(e)).toList();
      }
    } else {
      _categories =
          res.map((e) => BudgetCategory.fromSupabase(e)).toList();
    }
  }

  Future<void> _loadTransactions() async {
    final res = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', _userId!)
        .order('date', ascending: false);
    _transactions =
        (res as List).map((e) => Transaction.fromSupabase(e)).toList();

    for (var cat in _categories) {
      cat.actualAmount = _transactions
          .where((t) => t.categoryId == cat.id && t.isExpense)
          .fold(0, (sum, t) => sum + t.amount);
    }
  }

  Future<void> _loadIncomes() async {
    final res = await _supabase
        .from('incomes')
        .select()
        .eq('user_id', _userId!)
        .order('date', ascending: false);
    _incomes = (res as List).map((e) => Income.fromSupabase(e)).toList();
  }

  Future<void> _loadGoals() async {
    final res = await _supabase
        .from('savings_goals')
        .select()
        .eq('user_id', _userId!)
        .order('created_at');
    _goals = (res as List).map((e) => SavingsGoal.fromSupabase(e)).toList();
  }

  Future<void> _loadRecurring() async {
    final res = await _supabase
        .from('recurring_expenses')
        .select()
        .eq('user_id', _userId!)
        .order('day_of_month');
    _recurring =
        (res as List).map((e) => RecurringExpense.fromSupabase(e)).toList();
  }

  Future<void> _loadMonthHistory() async {
    final res = await _supabase
        .from('month_history')
        .select()
        .eq('user_id', _userId!)
        .order('month_key', ascending: false);
    _monthHistory =
        (res as List).map((e) => MonthSnapshot.fromSupabase(e)).toList();
  }

  Future<void> _loadNextMonthBudgets() async {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final monthKey =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
    final res = await _supabase
        .from('budget_planner')
        .select()
        .eq('user_id', _userId!)
        .eq('month_key', monthKey);
    _nextMonthBudgets = {};
    for (final row in (res as List)) {
      _nextMonthBudgets[row['category_id']] =
          (row['planned_amount'] as num).toDouble();
    }
  }

  void _initDefaultCategories() {
    _categories = [
      BudgetCategory(id: _uuid.v4(), name: 'Housing', budgetAmount: 1500, icon: Icons.home, color: const Color(0xFF0EA5E9)),
      BudgetCategory(id: _uuid.v4(), name: 'Food & Dining', budgetAmount: 600, icon: Icons.restaurant, color: const Color(0xFFF97316)),
      BudgetCategory(id: _uuid.v4(), name: 'Transportation', budgetAmount: 400, icon: Icons.directions_car, color: const Color(0xFF06B6D4)),
      BudgetCategory(id: _uuid.v4(), name: 'Healthcare', budgetAmount: 300, icon: Icons.health_and_safety, color: const Color(0xFFEF4444)),
      BudgetCategory(id: _uuid.v4(), name: 'Entertainment', budgetAmount: 200, icon: Icons.movie, color: const Color(0xFF8B5CF6)),
      BudgetCategory(id: _uuid.v4(), name: 'Shopping', budgetAmount: 300, icon: Icons.shopping_bag, color: const Color(0xFFEC4899)),
      BudgetCategory(id: _uuid.v4(), name: 'Utilities', budgetAmount: 250, icon: Icons.bolt, color: const Color(0xFFF59E0B)),
      BudgetCategory(id: _uuid.v4(), name: 'Savings', budgetAmount: 450, icon: Icons.savings, color: const Color(0xFF14B8A6)),
    ];
  }

  Future<void> _initDefaultCategoriesRemote() async {
    _initDefaultCategories();
    for (final cat in _categories) {
      await _supabase.from('categories').insert(cat.toSupabase(_userId!));
    }
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  Future<void> addCategory(BudgetCategory cat) async {
    _categories.add(cat);
    notifyListeners();
    await _supabase.from('categories').insert(cat.toSupabase(_userId!));
  }

  Future<void> updateCategory(BudgetCategory updated) async {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _categories[idx] = updated;
      notifyListeners();
      await _supabase
          .from('categories')
          .update(updated.toSupabase(_userId!))
          .eq('id', updated.id);
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _transactions.removeWhere((t) => t.categoryId == id);
    notifyListeners();
    await _supabase.from('categories').delete().eq('id', id);
    await _supabase.from('transactions').delete().eq('category_id', id);
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx);
    final catIdx = _categories.indexWhere((c) => c.id == tx.categoryId);
    if (catIdx >= 0 && tx.isExpense) {
      _categories[catIdx].actualAmount += tx.amount;
      // Upsert instead of update so the row is created if it was never synced to Supabase
      // (prevents the transactions_category_id_fkey FK violation)
      await _supabase
          .from('categories')
          .upsert(_categories[catIdx].toSupabase(_userId!));
    }
    notifyListeners();
    await _supabase.from('transactions').insert(tx.toSupabase(_userId!));
  }

  Future<void> deleteTransaction(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);
    _transactions.removeWhere((t) => t.id == id);
    final catIdx = _categories.indexWhere((c) => c.id == tx.categoryId);
    if (catIdx >= 0 && tx.isExpense) {
      _categories[catIdx].actualAmount =
          (_categories[catIdx].actualAmount - tx.amount).clamp(0, double.infinity);
      await _supabase.from('categories').update({
        'actual_amount': _categories[catIdx].actualAmount,
      }).eq('id', tx.categoryId);
    }
    notifyListeners();
    await _supabase.from('transactions').delete().eq('id', id);
  }

  List<Transaction> getTransactionsForCategory(String categoryId) =>
      _transactions.where((t) => t.categoryId == categoryId).toList();

  // ── Income ────────────────────────────────────────────────────────────────

  Future<void> addIncome(Income income) async {
    _incomes.insert(0, income);
    notifyListeners();
    await _supabase.from('incomes').insert(income.toSupabase(_userId!));
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    notifyListeners();
    await _supabase.from('incomes').delete().eq('id', id);
  }

  // ── Savings Goals ─────────────────────────────────────────────────────────

  Future<void> addGoal(SavingsGoal goal) async {
    _goals.add(goal);
    notifyListeners();
    await _supabase.from('savings_goals').insert(goal.toSupabase(_userId!));
  }

  Future<void> addToGoal(String goalId, double amount) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx >= 0) {
      _goals[idx].currentAmount += amount;
      notifyListeners();
      await _supabase.from('savings_goals').update({
        'current_amount': _goals[idx].currentAmount,
      }).eq('id', goalId);
    }
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    await _supabase.from('savings_goals').delete().eq('id', id);
  }

  // ── Recurring ─────────────────────────────────────────────────────────────

  Future<void> addRecurring(RecurringExpense expense) async {
    _recurring.add(expense);
    notifyListeners();
    await _supabase
        .from('recurring_expenses')
        .insert(expense.toSupabase(_userId!));
  }

  Future<void> toggleRecurring(String id) async {
    final idx = _recurring.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _recurring[idx].isActive = !_recurring[idx].isActive;
      notifyListeners();
      await _supabase.from('recurring_expenses').update({
        'is_active': _recurring[idx].isActive,
      }).eq('id', id);
    }
  }

  Future<void> deleteRecurring(String id) async {
    _recurring.removeWhere((r) => r.id == id);
    notifyListeners();
    await _supabase.from('recurring_expenses').delete().eq('id', id);
  }

  Future<void> applyRecurringExpenses() async {
    final active = _recurring.where((r) => r.isActive).toList();
    for (final r in active) {
      final tx = Transaction(
        id: generateId(),
        categoryId: r.categoryId,
        description: '${r.description} (Recurring)',
        amount: r.amount,
        date: DateTime.now(),
      );
      await addTransaction(tx);
    }
  }

  // ── Next Month Planner ────────────────────────────────────────────────────

  double getNextMonthBudget(String categoryId) =>
      _nextMonthBudgets[categoryId] ??
      (_categories.firstWhere((c) => c.id == categoryId,
              orElse: () => BudgetCategory(
                  id: '', name: '', budgetAmount: 0, icon: Icons.category, color: Colors.grey))
          .budgetAmount);

  Future<void> setNextMonthBudget(String categoryId, double amount) async {
    _nextMonthBudgets[categoryId] = amount;
    notifyListeners();
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final monthKey =
        '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
    await _supabase.from('budget_planner').upsert({
      'user_id': _userId,
      'category_id': categoryId,
      'month_key': monthKey,
      'planned_amount': amount,
    });
  }

  // ── Budget & Settings ────────────────────────────────────────────────────

  // These setters are invoked as fire-and-forget UI callbacks (e.g.
  // SwitchListTile.onChanged), so a failed _saveSettings() would otherwise
  // surface as an uncaught error in the browser console with no UI impact.
  // The local state change already applied, so we just log and move on.

  Future<void> updateTotalBudget(double amount) async {
    _totalMonthlyBudget = amount;
    notifyListeners();
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to save total budget: $e');
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveLocalPrefs();
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to save dark mode: $e');
    }
  }

  Future<void> setCurrency(String code) async {
    if (!availableCurrencies.containsKey(code)) return;
    _currency = code;
    notifyListeners();
    await _saveLocalPrefs();
    try {
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to save currency: $e');
    }
  }

  // ── Local persistence & live FX rates ─────────────────────────────────────

  Future<void> _restoreLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var changed = false;
      final c = prefs.getString('currency');
      if (c != null && availableCurrencies.containsKey(c)) {
        _currency = c;
        changed = true;
      }
      final d = prefs.getBool('is_dark_mode');
      if (d != null) {
        _isDarkMode = d;
        changed = true;
      }
      final r = prefs.getString('fx_rates');
      if (r != null) {
        final decoded = (jsonDecode(r) as Map)
            .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
        if (decoded.isNotEmpty) {
          _rates = {..._rates, ...decoded};
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (_) {
      // First run or storage unavailable — fall back to defaults.
    }
  }

  Future<void> _saveLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', _currency);
      await prefs.setBool('is_dark_mode', _isDarkMode);
    } catch (_) {}
  }

  Future<void> _refreshRates() async {
    try {
      final symbols =
          availableCurrencies.keys.where((c) => c != 'USD').join(',');
      final uri =
          Uri.parse('https://api.frankfurter.app/latest?from=USD&to=$symbols');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final rates = (body['rates'] as Map?)
          ?.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      if (rates == null || rates.isEmpty) return;
      _rates = {'USD': 1.0, ...rates};
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fx_rates', jsonEncode(_rates));
      } catch (_) {}
    } catch (_) {
      // Offline or feed down — keep the fallback/cached rates.
    }
  }

  // ── Reset Month ───────────────────────────────────────────────────────────

  Future<void> resetMonth({bool carryForward = true}) async {
    final now = DateTime.now();
    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final surplus = totalVariance; // positive = unspent, negative = over

    final categorySpending = {
      for (final c in _categories) c.name: c.actualAmount
    };

    final categoryBudgets = {
      for (final c in _categories) c.name: c.budgetAmount
    };

    final txDetails = _transactions.map((tx) {
      final catName = _categories
          .firstWhere((c) => c.id == tx.categoryId,
              orElse: () => BudgetCategory(
                  id: '', name: 'Unknown', budgetAmount: 0, icon: Icons.category, color: Colors.grey))
          .name;
      return <String, dynamic>{
        'date': tx.date.toIso8601String().split('T')[0],
        'desc': tx.description,
        'amount': tx.amount,
        'cat': catName,
      };
    }).toList();

    final snapshot = MonthSnapshot(
      id: generateId(),
      monthKey: monthKey,
      totalBudget: _totalMonthlyBudget,
      totalSpent: totalActualSpent,
      totalIncome: totalIncome,
      categorySpending: categorySpending,
      categoryBudgets: categoryBudgets,
      transactions: txDetails,
    );

    await _supabase
        .from('month_history')
        .insert(snapshot.toSupabase(_userId!));
    _monthHistory.insert(0, snapshot);

    for (var cat in _categories) {
      cat.actualAmount = 0;
      await _supabase.from('categories').update({'actual_amount': 0.0}).eq('id', cat.id);
    }

    await _supabase
        .from('transactions')
        .delete()
        .eq('user_id', _userId!);
    _transactions.clear();

    await _supabase.from('incomes').delete().eq('user_id', _userId!);
    _incomes.clear();

    if (_nextMonthBudgets.isNotEmpty) {
      await _applyNextMonthPlan();
    }

    // Carry forward unspent balance into next month's budget
    if (carryForward && surplus > 0) {
      _totalMonthlyBudget += surplus;
      await _saveSettings();
    }

    notifyListeners();
  }

  double get carryForwardAmount {
    final surplus = totalVariance;
    return surplus > 0 ? surplus : 0;
  }

  Future<void> _applyNextMonthPlan() async {
    for (final entry in _nextMonthBudgets.entries) {
      final idx = _categories.indexWhere((c) => c.id == entry.key);
      if (idx >= 0) {
        _categories[idx].budgetAmount = entry.value;
        await _supabase.from('categories').update({
          'budget_amount': entry.value,
        }).eq('id', entry.key);
      }
    }
    _nextMonthBudgets.clear();
  }

  String generateId() => _uuid.v4();

  String exportToCsv() {
    final buf = StringBuffer();
    buf.writeln('Category,Budget,Spent,Variance');
    for (final cat in _categories) {
      buf.writeln(
          '${cat.name},${cat.budgetAmount.toStringAsFixed(2)},${cat.actualAmount.toStringAsFixed(2)},${cat.variance.toStringAsFixed(2)}');
    }
    buf.writeln('');
    buf.writeln('Date,Category,Description,Amount');
    for (final tx in _transactions) {
      final catName = _categories
          .firstWhere((c) => c.id == tx.categoryId,
              orElse: () => BudgetCategory(
                  id: '', name: 'Unknown', budgetAmount: 0, icon: Icons.category, color: Colors.grey))
          .name;
      buf.writeln(
          '${tx.date.toIso8601String().split('T')[0]},$catName,${tx.description},${tx.amount.toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  void clearData() {
    _cachedUserId = null;
    _categories = [];
    _transactions = [];
    _incomes = [];
    _goals = [];
    _recurring = [];
    _monthHistory = [];
    _nextMonthBudgets = {};
    _totalMonthlyBudget = 5000.0;
    notifyListeners();
  }
}
