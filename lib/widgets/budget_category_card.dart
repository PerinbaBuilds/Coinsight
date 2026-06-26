import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import '../screens/add_expense_screen.dart';

class BudgetCategoryCard extends StatefulWidget {
  final BudgetCategory category;
  final List<Transaction> transactions;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    required this.transactions,
  });

  @override
  State<BudgetCategoryCard> createState() => _BudgetCategoryCardState();
}

class _BudgetCategoryCardState extends State<BudgetCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final txns = widget.transactions;
    final isOver = cat.isOverBudget;
    final sym = context.watch<FinanceService>().currencySymbol;
    final statusColor =
        AppTheme.budgetStatusColor(cat.utilizationPercent, cat.isOverBudget);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            cat.color.withValues(alpha: isDark ? 0.08 : 0.05), scheme.surface),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: cat.color.withValues(alpha: isDark ? 0.5 : 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category-colored left accent strip (identifies the category at a glance)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: cat.color,
                boxShadow: [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          // Icon circle
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                cat.color.withValues(alpha: 0.2),
                            child: Icon(cat.icon, color: cat.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          // Name + budget
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () {
                                    if (context.read<FinanceService>().isBudgetLocked) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Budgets are locked after the 7th — wait until next month.'),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                    _editBudget(context, cat);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Budget: $sym${cat.budgetAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: scheme.onSurface.withValues(alpha: 0.55),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        context.watch<FinanceService>().isBudgetLocked
                                            ? Icons.lock_outline
                                            : Icons.edit,
                                        size: 11,
                                        color: context.watch<FinanceService>().isBudgetLocked
                                            ? AppTheme.amber
                                            : scheme.onSurface.withValues(alpha: 0.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Ring + amount + variance
                          Row(
                            children: [
                              _RingProgress(
                                percent: cat.utilizationPercent,
                                color: statusColor,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$sym${cat.actualAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isOver
                                          ? '-$sym${cat.variance.abs().toStringAsFixed(0)}'
                                          : '+$sym${cat.variance.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: scheme.onSurface.withValues(alpha: 0.4),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Animated expand section
                  AnimatedSize(
                    duration: AppTheme.motionMedium,
                    curve: AppTheme.motionCurve,
                    child: _expanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Divider(
                                  height: 1,
                                  color: scheme.outline
                                      .withValues(alpha: 0.3)),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 8, 10, 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${txns.length} expense${txns.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        AppTheme.bottomSheetRoute(
                                          AddExpenseScreen(
                                              initialCategoryId: cat.id),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 15),
                                      label: const Text('Add Expense',
                                          style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: scheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (txns.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 4, 14, 16),
                                  child: Text(
                                    'No expenses yet. Tap "Add Expense" to get started.',
                                    style: TextStyle(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.4),
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else ...[
                                ...txns
                                    .take(10)
                                    .map((tx) => _TransactionRow(tx: tx)),
                                if (txns.length > 10)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '+ ${txns.length - 10} more',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBudget(BuildContext context, BudgetCategory cat) {
    final ctrl =
        TextEditingController(text: cat.budgetAmount.toStringAsFixed(2));
    final sym = context.read<FinanceService>().currencySymbol;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${cat.name} Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '$sym ',
            labelText: 'Budget Amount',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                cat.budgetAmount = val;
                await context.read<FinanceService>().updateCategory(cat);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Ring Progress ─────────────────────────────────────────────────────────────
class _RingProgress extends StatelessWidget {
  final double percent;
  final Color color;

  const _RingProgress({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 999.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (clamped / 100).clamp(0.0, 1.0)),
      duration: AppTheme.motionSlow * 2,
      curve: AppTheme.motionCurve,
      builder: (_, v, __) => SizedBox(
        width: 52,
        height: 52,
        child: CustomPaint(
          painter: _RingPainter(progress: v, color: color),
          child: Center(
            child: Text(
              '${percent.clamp(0, 999).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 5.0;

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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Transaction Row ───────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final Transaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final sym = context.watch<FinanceService>().currencySymbol;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
      child: Row(
        children: [
          Icon(Icons.receipt_long,
              size: 14, color: scheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(tx.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sym${tx.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.rose,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 17, color: AppTheme.rose.withValues(alpha: 0.7)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () async {
              await context.read<FinanceService>().deleteTransaction(tx.id);
            },
          ),
        ],
      ),
    );
  }
}
