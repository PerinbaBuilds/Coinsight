import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'finance_service.dart';

/// A single message in the advisor conversation.
class AdvisorMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final ImpactReport? impact;

  /// Raw <impact> JSON kept alongside the parsed report so the conversation
  /// (including the impact dashboard) can be restored from local storage.
  final String? impactRaw;

  const AdvisorMessage({
    required this.role,
    required this.text,
    this.impact,
    this.impactRaw,
  });

  Map<String, dynamic> toJson() =>
      {'role': role, 'text': text, if (impactRaw != null) 'impact': impactRaw};

  factory AdvisorMessage.fromJson(Map<String, dynamic> j) {
    final raw = j['impact'] as String?;
    return AdvisorMessage(
      role: j['role'] as String? ?? 'assistant',
      text: j['text'] as String? ?? '',
      impact: raw == null ? null : ImpactReport.tryParse(raw),
      impactRaw: raw,
    );
  }
}

/// Machine-readable decision report the model appends to a final
/// recommendation, rendered as the impact dashboard.
class ImpactReport {
  final String verdict; // 'go' | 'wait' | 'avoid'
  final String title;
  final String summary;
  final double? oneTimeCost;
  final double? monthlyCost;
  final ImpactSnapshot current;
  final ImpactSnapshot projected;
  final List<TimelinePoint> timeline;
  final List<String> suggestions;

  const ImpactReport({
    required this.verdict,
    required this.title,
    required this.summary,
    this.oneTimeCost,
    this.monthlyCost,
    required this.current,
    required this.projected,
    required this.timeline,
    required this.suggestions,
  });

  static ImpactReport? tryParse(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      double? num_(dynamic v) => v == null ? null : (v as num).toDouble();
      ImpactSnapshot snap(dynamic v) {
        final m = (v as Map<String, dynamic>?) ?? const {};
        return ImpactSnapshot(
          netSavings: num_(m['net_savings']) ?? 0,
          budgetUsedPct: num_(m['budget_used_pct']) ?? 0,
          bufferMonths: num_(m['buffer_months']) ?? 0,
          healthScore: num_(m['health_score']) ?? 0,
        );
      }

      return ImpactReport(
        verdict: (map['verdict'] as String?) ?? 'wait',
        title: (map['title'] as String?) ?? 'Decision impact',
        summary: (map['summary'] as String?) ?? '',
        oneTimeCost: num_(map['one_time_cost']),
        monthlyCost: num_(map['monthly_cost']),
        current: snap(map['current']),
        projected: snap(map['projected']),
        timeline: ((map['timeline'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((p) => TimelinePoint(
                  label: (p['label'] as String?) ?? '',
                  without: num_(p['without']) ?? 0,
                  withDecision: num_(p['with']) ?? 0,
                ))
            .toList(),
        suggestions: ((map['suggestions'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

class ImpactSnapshot {
  final double netSavings;
  final double budgetUsedPct;
  final double bufferMonths;
  final double healthScore;

  const ImpactSnapshot({
    required this.netSavings,
    required this.budgetUsedPct,
    required this.bufferMonths,
    required this.healthScore,
  });
}

class TimelinePoint {
  final String label;
  final double without;
  final double withDecision;

  const TimelinePoint({
    required this.label,
    required this.without,
    required this.withDecision,
  });
}

class AdvisorService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  final List<AdvisorMessage> _messages = [];
  bool _isThinking = false;
  String? _error;
  bool _restored = false;

  AdvisorService() {
    _restore();
  }

  List<AdvisorMessage> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;
  String? get error => _error;

  // Conversation is stored per user so switching accounts never mixes history.
  String get _storageKey {
    final uid = _supabase.auth.currentUser?.id ?? 'anon';
    return 'advisor_history_$uid';
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(AdvisorMessage.fromJson)
          .toList();
      if (list.isNotEmpty && _messages.isEmpty) {
        _messages.addAll(list);
        notifyListeners();
      }
    } catch (_) {
      // Corrupt/absent history is non-fatal — start fresh.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode([for (final m in _messages) m.toJson()]),
      );
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  void clearConversation() {
    _messages.clear();
    _error = null;
    _persist();
    notifyListeners();
  }

  Future<void> send(String text, FinanceService finance) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking) return;

    _messages.add(AdvisorMessage(role: 'user', text: trimmed));
    _isThinking = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase.functions.invoke(
        'financial-advisor',
        body: {
          'messages': [
            for (final m in _messages)
              {'role': m.role, 'content': m.text},
          ],
          'snapshot': _buildSnapshot(finance),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final raw = (data?['content'] as String?) ?? '';
      if (raw.isEmpty) {
        throw (data?['error'] as String?) ?? 'Empty response from advisor';
      }
      _messages.add(_parseAssistantMessage(raw));
    } catch (e) {
      _error = _friendlyError(e);
    } finally {
      _isThinking = false;
      _persist();
      notifyListeners();
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('429') || s.toLowerCase().contains('rate')) {
      return 'The advisor is busy right now. Try again in a minute.';
    }
    if (s.contains('GROQ_API_KEY')) {
      return 'The advisor backend is not configured yet.';
    }
    return 'Could not reach the advisor. Check your connection and try again.';
  }

  AdvisorMessage _parseAssistantMessage(String raw) {
    final match =
        RegExp(r'<impact>([\s\S]*?)</impact>').firstMatch(raw);
    if (match == null) {
      return AdvisorMessage(role: 'assistant', text: raw.trim());
    }
    final prose = raw.replaceRange(match.start, match.end, '').trim();
    final impactRaw = match.group(1)!.trim();
    return AdvisorMessage(
      role: 'assistant',
      text: prose,
      impact: ImpactReport.tryParse(impactRaw),
      impactRaw: impactRaw,
    );
  }

  /// Everything the model needs to reason about the user's finances,
  /// computed from data already loaded in [FinanceService].
  Map<String, dynamic> _buildSnapshot(FinanceService finance) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthlySpendEstimate = finance.totalActualSpent > 0 && now.day > 3
        ? finance.totalActualSpent / now.day * daysInMonth
        : finance.totalMonthlyBudget;
    final goalSavedTotal =
        finance.goals.fold<double>(0, (s, g) => s + g.currentAmount);
    final bufferMonths = monthlySpendEstimate <= 0
        ? 0.0
        : goalSavedTotal / monthlySpendEstimate;

    return {
      'currency': finance.currency,
      'currency_symbol': finance.currencySymbol,
      'today': now.toIso8601String().substring(0, 10),
      'day_of_month': now.day,
      'days_in_month': daysInMonth,
      'monthly_budget': finance.totalMonthlyBudget,
      'spent_this_month': finance.totalActualSpent,
      'budget_used_pct': finance.totalMonthlyBudget == 0
          ? 0
          : (finance.totalActualSpent / finance.totalMonthlyBudget * 100)
              .toStringAsFixed(1),
      'income_this_month': finance.totalIncome,
      'net_savings_this_month': finance.netSavings,
      'projected_month_spend': monthlySpendEstimate.round(),
      'total_saved_in_goals': goalSavedTotal,
      'emergency_buffer_months': double.parse(bufferMonths.toStringAsFixed(1)),
      'health_score': computeHealthScore(finance),
      'categories': [
        for (final c in finance.categories)
          {
            'name': c.name,
            'budget': c.budgetAmount,
            'spent': c.actualAmount,
            'over_budget': c.isOverBudget,
          },
      ],
      'savings_goals': [
        for (final g in finance.goals)
          {
            'name': g.name,
            'target': g.targetAmount,
            'saved': g.currentAmount,
            if (g.targetDate != null)
              'target_date': g.targetDate!.toIso8601String().substring(0, 10),
          },
      ],
      'recurring_bills': [
        for (final r in finance.recurring.where((r) => r.isActive))
          {
            'description': r.description,
            'amount': r.amount,
            'day_of_month': r.dayOfMonth,
          },
      ],
      'recent_months': [
        for (final m in finance.monthHistory.take(6))
          {
            'month': m.monthKey,
            'budget': m.totalBudget,
            'spent': m.totalSpent,
            'income': m.totalIncome,
            'net_savings': m.netSavings,
          },
      ],
    };
  }

  /// Single source of truth for the health score — the Insights screen
  /// delegates here so the advisor and the Insights tab always agree.
  static int computeHealthScore(FinanceService finance) {
    int score = 0;

    // Budget adherence: 40 pts
    if (!finance.isOverBudget) {
      score += 40;
    } else {
      final overBy = finance.totalActualSpent - finance.totalMonthlyBudget;
      final ratio = finance.totalMonthlyBudget == 0
          ? 1.0
          : overBy / finance.totalMonthlyBudget;
      score += (40 * (1.0 - ratio.clamp(0.0, 1.0))).round();
    }

    // Savings rate: 30 pts
    if (finance.totalIncome > 0) {
      final savingsRate = finance.netSavings / finance.totalIncome;
      if (savingsRate >= 0.2) {
        score += 30;
      } else if (savingsRate > 0) {
        score += (30 * (savingsRate / 0.2)).round();
      }
    }

    // Category distribution: 30 pts
    if (finance.totalActualSpent > 0 && finance.categories.isNotEmpty) {
      final maxPct = finance.categories
          .map((c) => c.actualAmount / finance.totalActualSpent)
          .reduce(math.max);
      if (maxPct <= 0.5) {
        score += 30;
      } else {
        score += (30 * (1.0 - (maxPct - 0.5) / 0.5)).round().clamp(0, 30);
      }
    } else {
      score += 15; // neutral if no data
    }

    return score.clamp(0, 100);
  }
}
