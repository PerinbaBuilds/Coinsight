import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class BudgetChart extends StatefulWidget {
  final List<BudgetCategory> categories;
  const BudgetChart({super.key, required this.categories});

  @override
  State<BudgetChart> createState() => _BudgetChartState();
}

class _BudgetChartState extends State<BudgetChart> {
  int _touched = -1;

  List<BudgetCategory> get _cats =>
      widget.categories.where((c) => c.budgetAmount > 0).toList();

  double get _totalSpent =>
      widget.categories.fold(0.0, (s, c) => s + c.actualAmount);

  double get _totalBudget =>
      widget.categories.fold(0.0, (s, c) => s + c.budgetAmount);

  @override
  Widget build(BuildContext context) {
    final cs = context.watch<FinanceService>().currencySymbol;
    final totalSpent = _totalSpent;
    final totalBudget = _totalBudget;
    final overallPct = totalBudget == 0 ? 0.0 : totalSpent / totalBudget * 100;
    final isOver = totalSpent > totalBudget;
    final statusColor = AppTheme.budgetStatusColor(overallPct, isOver);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          if (isDark && _cats.isNotEmpty)
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.07),
              blurRadius: 32,
              spreadRadius: 2,
            ),
        ],
        border: Border.all(color: scheme.outline.withValues(alpha: isDark ? 1.0 : 0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              _StatusPill(spent: totalSpent, budget: totalBudget, cs: cs),
            ],
          ),
          const SizedBox(height: 20),

          if (_cats.isEmpty)
            _empty(scheme)
          else ...[
            _buildDonut(
                totalSpent, totalBudget, statusColor, overallPct, cs, scheme, isDark),
            const SizedBox(height: 16),
            _buildLegend(scheme),
          ],
        ],
      ),
    );
  }

  Widget _empty(ColorScheme scheme) => SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.donut_large_outlined,
                size: 44,
                color: scheme.onSurface.withValues(alpha: 0.22),
              ),
              const SizedBox(height: 10),
              Text(
                'Set budgets to see this chart',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDonut(
    double totalSpent,
    double totalBudget,
    Color statusColor,
    double overallPct,
    String cs,
    ColorScheme scheme,
    bool isDark,
  ) {
    final cats = _cats;
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer behind the chart (dark mode only)
          if (isDark)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.12),
                    blurRadius: 48,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touched =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: List.generate(cats.length, (i) {
                final cat = cats[i];
                final isTouched = i == _touched;
                return PieChartSectionData(
                  value: cat.actualAmount == 0 ? 0.0001 : cat.actualAmount,
                  color: cat.color.withValues(alpha: isTouched ? 1.0 : 0.82),
                  radius: isTouched ? 66 : 54,
                  title: '',
                  borderSide: isTouched
                      ? BorderSide(color: cat.color, width: 2)
                      : const BorderSide(color: Colors.transparent),
                );
              }),
              centerSpaceRadius: 62,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
          ),
          _buildCenter(totalSpent, totalBudget, statusColor, overallPct, cs, scheme, cats),
        ],
      ),
    );
  }

  Widget _buildCenter(
    double totalSpent,
    double totalBudget,
    Color statusColor,
    double overallPct,
    String cs,
    ColorScheme scheme,
    List<BudgetCategory> cats,
  ) {
    if (_touched >= 0 && _touched < cats.length) {
      final cat = cats[_touched];
      final pct = cat.budgetAmount == 0
          ? 0.0
          : cat.actualAmount / cat.budgetAmount * 100;
      final catColor = AppTheme.budgetStatusColor(pct, cat.isOverBudget);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.icon, color: cat.color, size: 14),
          const SizedBox(height: 2),
          Text(
            cat.name,
            style: TextStyle(
              color: cat.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmt(cat.actualAmount, cs),
            style: TextStyle(
              color: catColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              shadows: [Shadow(color: catColor.withValues(alpha: 0.4), blurRadius: 8)],
            ),
          ),
          Text(
            'of ${_fmt(cat.budgetAmount, cs)}',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}% used',
              style: TextStyle(
                color: catColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(totalSpent, cs),
          style: TextStyle(
            color: statusColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            shadows: [Shadow(color: statusColor.withValues(alpha: 0.35), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'of ${_fmt(totalBudget, cs)}',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${overallPct.toStringAsFixed(0)}% used',
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(ColorScheme scheme) {
    final cats = _cats;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: List.generate(cats.length, (i) {
        final cat = cats[i];
        final isTouched = i == _touched;
        return GestureDetector(
          onTap: () => setState(() => _touched = isTouched ? -1 : i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTouched
                  ? cat.color.withValues(alpha: 0.14)
                  : scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTouched
                    ? cat.color.withValues(alpha: 0.6)
                    : scheme.outline.withValues(alpha: 0.25),
              ),
              boxShadow: isTouched
                  ? [BoxShadow(color: cat.color.withValues(alpha: 0.2), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: cat.color.withValues(alpha: 0.5), blurRadius: 4)
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _fmt(double v, String cs) =>
      v >= 1000 ? '$cs${(v / 1000).toStringAsFixed(1)}k' : '$cs${v.toStringAsFixed(0)}';
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final double spent, budget;
  final String cs;
  const _StatusPill(
      {required this.spent, required this.budget, required this.cs});

  @override
  Widget build(BuildContext context) {
    final pct = budget == 0 ? 0.0 : spent / budget * 100;
    final isOver = spent > budget;
    final color = AppTheme.budgetStatusColor(pct, isOver);
    final label = isOver
        ? '-${(pct - 100).toStringAsFixed(0)}% over'
        : '${pct.toStringAsFixed(0)}% used';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
