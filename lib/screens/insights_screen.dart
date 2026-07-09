import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/advisor_service.dart';
import '../services/finance_service.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        final overBudget = finance.categories
            .where((c) => c.isOverBudget)
            .toList();
        final topSpenders = [...finance.categories]
          ..sort((a, b) => b.actualAmount.compareTo(a.actualAmount));

        final score = _computeHealthScore(finance);

        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient))
                : null,
            title: const Text('Insights'),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Health Score ─────────────────────────────────────────────
              _SectionTitle('Financial Health Score'),
              const SizedBox(height: 12),
              _HealthScoreCard(score: score)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 24),

              // ── Smart Insights ───────────────────────────────────────────
              _SectionTitle('Smart Insights'),
              const SizedBox(height: 8),
              ..._buildInsights(finance, overBudget)
                  .asMap()
                  .entries
                  .map((e) => e.value
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 + e.key * 60))
                      .slideY(begin: 0.2)),
              const SizedBox(height: 24),

              // ── Spending Forecast ────────────────────────────────────────
              _SectionTitle('Spending Forecast'),
              const SizedBox(height: 8),
              _SpendingForecast(finance: finance)
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 24),

              // ── Breakdown Pie ────────────────────────────────────────────
              if (finance.categories.isNotEmpty &&
                  finance.totalActualSpent > 0) ...[
                _SectionTitle('Spending Breakdown'),
                const SizedBox(height: 8),
                _SpendingBreakdown(
                  topSpenders: topSpenders,
                  total: finance.totalActualSpent,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
              ],

              // ── Top Spending ─────────────────────────────────────────────
              _SectionTitle('Top Spending Categories'),
              const SizedBox(height: 8),
              ...topSpenders.take(5).map((cat) => _CategoryBar(
                    cat: cat,
                    max: topSpenders.isNotEmpty
                        ? topSpenders.first.actualAmount
                        : 1,
                  )),
              const SizedBox(height: 24),

              // ── Budget Utilization ───────────────────────────────────────
              _SectionTitle('Budget Utilization'),
              const SizedBox(height: 8),
              ...finance.categories
                  .map((cat) => _UtilizationRow(cat: cat)),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  int _computeHealthScore(FinanceService finance) =>
      AdvisorService.computeHealthScore(finance);

  List<Widget> _buildInsights(
      FinanceService finance, List<BudgetCategory> overBudget) {
    final insights = <Widget>[];
    final sym = finance.currencySymbol;

    for (final cat in overBudget) {
      insights.add(_InsightCard(
        icon: Icons.warning_amber,
        color: AppTheme.rose,
        title: '${cat.name} Over Budget',
        message:
            'You\'ve exceeded your ${cat.name} budget by $sym${(-cat.variance).toStringAsFixed(2)}.',
      ));
    }

    if (finance.netSavings > 0) {
      insights.add(_InsightCard(
        icon: Icons.savings,
        color: AppTheme.emerald,
        title: 'Great Savings!',
        message:
            'You\'re saving $sym${finance.netSavings.toStringAsFixed(2)} this month. Keep it up!',
      ));
    }

    if (finance.totalActualSpent == 0) {
      insights.add(const _InsightCard(
        icon: Icons.info_outline,
        color: Colors.blue,
        title: 'No Expenses Yet',
        message: 'Start adding expenses to see insights here.',
      ));
    }

    final cats = [...finance.categories]
      ..sort((a, b) => b.actualAmount.compareTo(a.actualAmount));
    if (cats.isNotEmpty && cats.first.actualAmount > 0) {
      insights.add(_InsightCard(
        icon: Icons.trending_up,
        color: AppTheme.amber,
        title: 'Biggest Spend',
        message:
            '${cats.first.name} is your top expense at $sym${cats.first.actualAmount.toStringAsFixed(2)}.',
      ));
    }

    if (finance.recurring.where((r) => r.isActive).isNotEmpty) {
      final total = finance.recurring
          .where((r) => r.isActive)
          .fold(0.0, (sum, r) => sum + r.amount);
      insights.add(_InsightCard(
        icon: Icons.repeat,
        color: Colors.purple,
        title: 'Recurring Bills',
        message:
            'You have $sym${total.toStringAsFixed(2)}/month in recurring expenses.',
      ));
    }

    if (insights.isEmpty) {
      insights.add(const _InsightCard(
        icon: Icons.check_circle,
        color: AppTheme.emerald,
        title: 'All Good!',
        message: 'No issues detected. Keep up the great work!',
      ));
    }

    return insights;
  }
}

// ── Health Score Card ─────────────────────────────────────────────────────────
class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  Color get _color {
    if (score < 40) return AppTheme.rose;
    if (score < 60) return AppTheme.amber;
    if (score < 80) return AppTheme.primary;
    return AppTheme.emerald;
  }

  String get _label {
    if (score < 40) return 'Needs Work';
    if (score < 60) return 'Fair';
    if (score < 80) return 'Good';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: AppTheme.motionCurve,
            builder: (_, v, __) => SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _HealthGaugePainter(
                    progress: v, color: _color),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(v * 100).round()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Based on budget adherence, savings rate, and spending distribution.',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ScorePill(label: 'Budget', score: score >= 40 ? 40 : score, max: 40, color: _color),
                    const SizedBox(width: 6),
                    _ScorePill(label: 'Savings', score: (score - 40).clamp(0, 30), max: 30, color: _color),
                    const SizedBox(width: 6),
                    _ScorePill(label: 'Spread', score: (score - 70).clamp(0, 30), max: 30, color: _color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int score;
  final int max;
  final Color color;
  const _ScorePill(
      {required this.label,
      required this.score,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $score/$max',
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HealthGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HealthGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HealthGaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ── Spending Breakdown ────────────────────────────────────────────────────────
class _SpendingBreakdown extends StatefulWidget {
  final List<BudgetCategory> topSpenders;
  final double total;
  const _SpendingBreakdown(
      {required this.topSpenders, required this.total});

  @override
  State<_SpendingBreakdown> createState() => _SpendingBreakdownState();
}

class _SpendingBreakdownState extends State<_SpendingBreakdown> {
  int _touched = -1;

  List<BudgetCategory> get _spenders =>
      widget.topSpenders.where((c) => c.actualAmount > 0).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final spenders = _spenders;
    final topColor = spenders.isNotEmpty ? spenders.first.color : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          if (isDark && spenders.isNotEmpty)
            BoxShadow(
              color: topColor.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 4,
            ),
        ],
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isDark && spenders.isNotEmpty)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_touched >= 0 && _touched < spenders.length
                                  ? spenders[_touched].color
                                  : topColor)
                              .withValues(alpha: 0.15),
                          blurRadius: 50,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                  ),
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _touched = response
                                  ?.touchedSection?.touchedSectionIndex ??
                              -1;
                        });
                      },
                    ),
                    sections: List.generate(spenders.length, (i) {
                      final c = spenders[i];
                      final isTouched = i == _touched;
                      return PieChartSectionData(
                        value: c.actualAmount,
                        color: c.color.withValues(alpha: isTouched ? 1.0 : 0.80),
                        radius: isTouched ? 72 : 58,
                        title: '',
                        borderSide: isTouched
                            ? BorderSide(color: c.color, width: 2)
                            : const BorderSide(color: Colors.transparent),
                      );
                    }),
                    sectionsSpace: 2,
                    centerSpaceRadius: 52,
                    startDegreeOffset: -90,
                  ),
                ),
                // Center label
                _touched >= 0 && _touched < spenders.length
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(spenders[_touched].icon,
                              color: spenders[_touched].color, size: 16),
                          const SizedBox(height: 2),
                          Text(
                            spenders[_touched].name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: spenders[_touched].color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(spenders[_touched].actualAmount / widget.total * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: spenders[_touched].color,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: spenders[_touched].color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Top',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          Text(
                            'Spend',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(spenders.length, (i) {
              final c = spenders[i];
              final isTouched = i == _touched;
              return GestureDetector(
                onTap: () => setState(() => _touched = isTouched ? -1 : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTouched
                        ? c.color.withValues(alpha: 0.14)
                        : colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTouched
                          ? c.color.withValues(alpha: 0.6)
                          : colorScheme.outline.withValues(alpha: 0.25),
                    ),
                    boxShadow: isTouched
                        ? [BoxShadow(color: c.color.withValues(alpha: 0.2), blurRadius: 8)]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: c.color.withValues(alpha: 0.5),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(c.actualAmount / widget.total * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

class _CategoryBar extends StatelessWidget {
  final BudgetCategory cat;
  final double max;
  const _CategoryBar({required this.cat, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (cat.actualAmount / max).clamp(0.0, 1.0);
    final sym = context.watch<FinanceService>().currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(cat.icon, color: cat.color, size: 16),
                const SizedBox(width: 6),
                Text(cat.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface)),
              ]),
              Text('$sym${cat.actualAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor:
                    colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(cat.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilizationRow extends StatelessWidget {
  final BudgetCategory cat;
  const _UtilizationRow({required this.cat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final pct = cat.utilizationPercent.clamp(0.0, 100.0);
    final color = cat.isOverBudget
        ? AppTheme.rose
        : pct >= 80
            ? AppTheme.amber
            : AppTheme.emerald;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(cat.icon, color: cat.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(cat.name,
                  style: TextStyle(
                      fontSize: 13, color: colorScheme.onSurface))),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor:
                    colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text('${pct.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
          right: BorderSide(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
          bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface)),
        subtitle: Text(message,
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6))),
      ),
    );
  }
}

class _SpendingForecast extends StatelessWidget {
  final FinanceService finance;
  const _SpendingForecast({required this.finance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysLeft = daysInMonth - daysPassed;
    final spent = finance.totalActualSpent;
    final budget = finance.totalMonthlyBudget;

    final sym = finance.currencySymbol;

    if (spent == 0 || daysPassed == 0) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Text(
          'Add some expenses to see your spending forecast.',
          style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13),
        ),
      );
    }

    final dailyRate = spent / daysPassed;
    final projected = spent + (dailyRate * daysLeft);
    final isProjectedOver = projected > budget;
    final projectedVariance = budget - projected;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  color: isProjectedOver ? AppTheme.rose : AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isProjectedOver
                      ? 'On track to exceed budget by $sym${projectedVariance.abs().toStringAsFixed(2)}'
                      : 'On track to stay $sym${projectedVariance.toStringAsFixed(2)} under budget',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isProjectedOver
                          ? AppTheme.rose
                          : AppTheme.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ForecastRow('Daily spending rate',
              '$sym${dailyRate.toStringAsFixed(2)}/day'),
          _ForecastRow('Days remaining', '$daysLeft days'),
          _ForecastRow('Projected month total',
              '$sym${projected.toStringAsFixed(2)}'),
          _ForecastRow('Monthly budget',
              '$sym${budget.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final String value;
  const _ForecastRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}
