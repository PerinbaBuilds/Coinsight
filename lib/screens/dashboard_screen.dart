import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../models/category.dart';
import '../widgets/summary_card.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_chart.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';
import 'manage_budgets_screen.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  /// Opens the app's side menu (Profile / Manage Budgets / theme). Wired from
  /// HomeScreen so the menu is reachable via a visible button, not only a swipe.
  final VoidCallback? onMenuTap;

  const DashboardScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        if (finance.isLoading) {
          return Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppTheme.navy)),
          );
        }

        final overAlertCats = finance.categories
            .where((c) => c.utilizationPercent >= 80 || c.isOverBudget)
            .toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DashboardHeader(finance: finance, onMenuTap: onMenuTap),
              ),

              // ── Alerts ──────────────────────────────────────────────────
              if (overAlertCats.isNotEmpty)
                SliverToBoxAdapter(
                  child: _AlertsRow(categories: overAlertCats)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, duration: 300.ms),
                ),

              // ── Budget Window Banner ─────────────────────────────────
              SliverToBoxAdapter(
                child: _BudgetWindowBanner(finance: finance),
              ),

              // ── Chart ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: BudgetChart(categories: finance.categories),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms),
              ),

              // ── Section Header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Budget Categories',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Actions live in an overflow menu so the header never
                      // overflows, regardless of screen width.
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: Theme.of(context).colorScheme.onSurface),
                        tooltip: 'Category actions',
                        onSelected: (value) {
                          if (value == 'manage') {
                            Navigator.push(
                              context,
                              AppTheme.slideRoute(
                                  const ManageBudgetsScreen()),
                            );
                          } else if (value == 'reset') {
                            _handleResetMonth(context, finance);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'manage',
                            child: Row(
                              children: [
                                Icon(Icons.tune_outlined, size: 18),
                                SizedBox(width: 12),
                                Text('Manage Budgets'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.restart_alt,
                                    size: 18, color: AppTheme.rose),
                                SizedBox(width: 12),
                                Text('Reset Month',
                                    style: TextStyle(color: AppTheme.rose)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Category Cards ───────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = finance.categories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: BudgetCategoryCard(
                        category: cat,
                        transactions:
                            finance.getTransactionsForCategory(cat.id),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 400 + index * 80),
                          duration: 350.ms,
                        )
                        .slideY(
                          begin: 0.3,
                          delay: Duration(milliseconds: 400 + index * 80),
                          duration: 350.ms,
                          curve: AppTheme.motionCurve,
                        );
                  },
                  childCount: finance.categories.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                AppTheme.bottomSheetRoute(const AddExpenseScreen()),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Expense',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleResetMonth(
      BuildContext context, FinanceService finance) async {
    final carry = finance.carryForwardAmount;
    final sym = finance.currencySymbol;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Month'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This saves a snapshot and clears current month data.'),
            if (carry > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.emerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings,
                        color: AppTheme.emerald, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$sym${carry.toStringAsFixed(2)} unspent will carry forward to next month\'s budget.',
                        style: const TextStyle(
                            color: AppTheme.emerald, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rose),
            child: const Text('Reset',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await finance.resetMonth();
      if (context.mounted) {
        final msg = carry > 0
            ? 'Month reset! $sym${carry.toStringAsFixed(2)} carried forward.'
            : 'Month reset! Snapshot saved to History.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.emerald),
        );
      }
    }
  }
}

// ── Dashboard Header ─────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final FinanceService finance;
  final VoidCallback? onMenuTap;
  const _DashboardHeader({required this.finance, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    final rawPercent = finance.totalMonthlyBudget == 0
        ? 0.0
        : finance.totalActualSpent / finance.totalMonthlyBudget;
    final isOver = finance.isOverBudget;
    final remaining = finance.totalVariance;
    final sym = finance.currencySymbol;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F2A1A), Color(0xFF1A4229), Color(0xFF050E09)]
              : const [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF4ADE80)],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<AuthService>(
                          builder: (_, auth, __) => Text(
                            'Hello, ${auth.displayName.isNotEmpty ? auth.displayName.split(' ').first : 'there'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          monthLabel,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.list_alt,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.push(
                          context,
                          AppTheme.slideRoute(
                              const TransactionsScreen()),
                        ),
                        tooltip: 'All Transactions',
                      ),
                      Consumer<FinanceService>(
                        builder: (_, fin, __) => IconButton(
                          icon: Icon(
                            fin.isDarkMode
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: fin.toggleDarkMode,
                          tooltip: fin.isDarkMode ? 'Light mode' : 'Dark mode',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_circle,
                            color: Colors.white, size: 26),
                        onPressed: onMenuTap ??
                            () => Navigator.push(
                                  context,
                                  AppTheme.slideRoute(const ProfileScreen()),
                                ),
                        tooltip: 'Menu',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Big spending amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0, end: finance.totalActualSpent),
                    duration: const Duration(milliseconds: 1200),
                    curve: AppTheme.motionCurve,
                    builder: (_, val, __) => Text(
                      '$sym${val.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'of $sym${finance.totalMonthlyBudget.toStringAsFixed(0)} budget',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOver
                          ? AppTheme.rose.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOver
                            ? AppTheme.rose.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isOver
                          ? '-$sym${remaining.abs().toStringAsFixed(0)} over'
                          : '$sym${remaining.toStringAsFixed(0)} left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar with glow effect — overflows visibly once over budget
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rawPercent),
                duration: const Duration(milliseconds: 900),
                curve: AppTheme.motionCurve,
                builder: (_, v, __) {
                  final barColor = isOver
                      ? AppTheme.rose
                      : AppTheme.emerald;
                  final fillWidth = v.clamp(0.0, 1.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOver
                                ? AppTheme.rose.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.55),
                            width: isOver ? 1.5 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: fillWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isOver
                                        ? [AppTheme.rose, Color(0xFFFF8FA0)]
                                        : [AppTheme.emerald, Color(0xFF00F5BB)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: isOver
                                    ? const ClipRRect(
                                        borderRadius:
                                            BorderRadius.all(Radius.circular(6)),
                                        child: _OverflowStripes(),
                                      )
                                    : null,
                              ),
                            )
                                .animate(
                                  onPlay: (c) =>
                                      isOver ? c.repeat(reverse: true) : null,
                                )
                                .boxShadow(
                                  begin: BoxShadow(
                                      color: barColor.withValues(alpha: 0.6),
                                      blurRadius: 8),
                                  end: BoxShadow(
                                      color: barColor.withValues(alpha: 0.95),
                                      blurRadius: 16,
                                      spreadRadius: 1),
                                  duration: isOver ? 700.ms : 0.ms,
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            '${(v * 100).toStringAsFixed(1)}% of budget used',
                            style: TextStyle(
                              color: isOver
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 11,
                              fontWeight:
                                  isOver ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isOver) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.warning_rounded,
                                size: 12, color: AppTheme.rose),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2x2 Summary grid
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Budget',
                      amount: finance.totalMonthlyBudget,
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF15803D),
                      currencySymbol: sym,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryCard(
                      label: 'Spent',
                      amount: finance.totalActualSpent,
                      icon: Icons.payment,
                      color: isOver
                          ? const Color(0xFFF87171)
                          : const Color(0xFF4ADE80),
                      currencySymbol: sym,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: 'Income',
                      amount: finance.totalIncome,
                      icon: Icons.trending_up,
                      color: const Color(0xFF2DD4BF),
                      currencySymbol: sym,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryCard(
                      label: 'Net Savings',
                      amount: finance.netSavings,
                      icon: Icons.savings,
                      color: finance.netSavings >= 0
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF87171),
                      currencySymbol: sym,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Budget Window Banner ──────────────────────────────────────────────────────
class _BudgetWindowBanner extends StatelessWidget {
  final FinanceService finance;
  const _BudgetWindowBanner({required this.finance});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (finance.isBudgetLocked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 15, color: AppTheme.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Budgets locked — edits open again on the 1st of next month.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final daysLeft = finance.budgetWindowDaysLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.emerald.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_calendar_outlined,
                size: 15, color: AppTheme.emerald),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                daysLeft == 0
                    ? 'Last day to adjust budgets — locks at midnight.'
                    : 'Budget window open — $daysLeft day${daysLeft == 1 ? '' : 's'} left to adjust.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alerts Row ────────────────────────────────────────────────────────────────
class _AlertsRow extends StatelessWidget {
  final List<BudgetCategory> categories;
  const _AlertsRow({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.amber, size: 16),
              const SizedBox(width: 6),
              Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isOver = cat.isOverBudget;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isOver
                        ? AppTheme.rose.withValues(alpha: 0.08)
                        : AppTheme.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOver
                          ? AppTheme.rose.withValues(alpha: 0.3)
                          : AppTheme.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOver
                            ? Icons.warning_rounded
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: isOver ? AppTheme.rose : AppTheme.amber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOver
                            ? '${cat.name} over budget'
                            : '${cat.name} at ${cat.utilizationPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isOver ? AppTheme.rose : AppTheme.amber,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overflow Stripes ────────────────────────────────────────────────────────
// Diagonal hazard pattern drawn over the progress bar once spending exceeds
// the monthly budget, so "full" reads as "overflowing" rather than "on track".
class _OverflowStripes extends StatelessWidget {
  const _OverflowStripes();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 3;
    const gap = 7.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
