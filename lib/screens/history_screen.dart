import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/finance_service.dart';
import '../models/month_snapshot.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        final history = finance.monthHistory;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Monthly History'),
            automaticallyImplyLeading: false,
          ),
          body: history.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final snap = history[index];
                    return _HistoryCard(snap: snap)
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 100 + index * 60),
                          duration: 300.ms,
                        )
                        .slideY(
                          begin: 0.2,
                          delay: Duration(milliseconds: 100 + index * 60),
                        );
                  },
                ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MonthSnapshot snap;
  const _HistoryCard({required this.snap});

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = int.tryParse(parts[1]) ?? 0;
    return '${months[month]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cs = context.watch<FinanceService>().currencySymbol;
    final isGood = snap.netSavings >= 0;
    final spentPct = snap.totalBudget == 0
        ? 0.0
        : (snap.totalSpent / snap.totalBudget).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isGood
                ? AppTheme.emerald.withValues(alpha: 0.1)
                : AppTheme.rose.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isGood ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
            color: isGood ? AppTheme.emerald : AppTheme.rose,
            size: 20,
          ),
        ),
        title: Text(
          _formatMonthKey(snap.monthKey),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              'Net: ${isGood ? '+' : ''}$cs${snap.netSavings.toStringAsFixed(0)}',
              style: TextStyle(
                color: isGood ? AppTheme.emerald : AppTheme.rose,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(spentPct * 100).toStringAsFixed(0)}% used',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: spentPct,
                    minHeight: 6,
                    backgroundColor: scheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGood ? AppTheme.emerald : AppTheme.rose,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Summary row
                _SummaryRow('Budget', '$cs${snap.totalBudget.toStringAsFixed(0)}', scheme.onSurface.withValues(alpha: 0.8)),
                _SummaryRow('Spent', '$cs${snap.totalSpent.toStringAsFixed(0)}', isGood ? AppTheme.emerald : AppTheme.rose),
                _SummaryRow('Income', '$cs${snap.totalIncome.toStringAsFixed(0)}', AppTheme.sky),
                _SummaryRow(
                  'Variance',
                  '${snap.variance >= 0 ? '+' : ''}$cs${snap.variance.toStringAsFixed(0)}',
                  snap.variance >= 0 ? AppTheme.emerald : AppTheme.rose,
                ),
                // Category breakdown
                if (snap.categorySpending.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'By Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...snap.categorySpending.entries.map((e) {
                    final budget = snap.categoryBudgets[e.key];
                    final pct = budget != null && budget > 0
                        ? (e.value / budget).clamp(0.0, 1.5)
                        : null;
                    final isOver = budget != null && e.value > budget;
                    final barColor = isOver ? AppTheme.rose : AppTheme.emerald;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$cs${e.value.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isOver ? AppTheme.rose : scheme.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (budget != null) ...[
                                    Text(
                                      ' / $cs${budget.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: scheme.onSurface.withValues(alpha: 0.45),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (pct != null) ...[
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor: scheme.outline.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  barColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
                // Transaction details
                if (snap.transactions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(color: scheme.outline.withValues(alpha: 0.25)),
                  const SizedBox(height: 4),
                  Text(
                    '${snap.transactions.length} Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...snap.transactions.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['desc']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface.withValues(alpha: 0.85),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${tx['cat'] ?? ''} · ${tx['date'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurface.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$cs${(tx['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.rose,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 40, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reset month to save a snapshot here',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
