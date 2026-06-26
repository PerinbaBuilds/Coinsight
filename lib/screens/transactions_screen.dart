import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/finance_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String _filterType = 'all';
  bool _searchExpanded = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        var txs = [...finance.transactions]
          ..sort((a, b) => b.date.compareTo(a.date));

        // Filter
        if (_filterType == 'expense') {
          txs = txs.where((t) => t.isExpense).toList();
        } else if (_filterType == 'income') {
          txs = txs.where((t) => !t.isExpense).toList();
        }

        // Search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          txs = txs
              .where((t) =>
                  t.description.toLowerCase().contains(q) ||
                  t.amount.toString().contains(q))
              .toList();
        }

        // Group by date label
        final grouped = _groupTransactions(txs, finance);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient))
                : null,
            title: const Text('All Transactions'),
            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            actions: [
              IconButton(
                icon: Icon(
                  _searchExpanded ? Icons.search_off : Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
                ),
                onPressed: () {
                  setState(() {
                    _searchExpanded = !_searchExpanded;
                    if (!_searchExpanded) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar (collapsible)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: AppTheme.motionCurve,
                height: _searchExpanded ? 64 : 0,
                color: colorScheme.surface,
                child: _searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            prefixIcon: Icon(Icons.search,
                                color: colorScheme.onSurface.withValues(alpha: 0.4)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: colorScheme.onSurface.withValues(alpha: 0.4)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                          ),
                        ),
                      )
                    : null,
              ),

              // Filter chips
              Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterType == 'all',
                      onTap: () =>
                          setState(() => _filterType = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Expenses',
                      selected: _filterType == 'expense',
                      color: AppTheme.rose,
                      onTap: () =>
                          setState(() => _filterType = 'expense'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Income',
                      selected: _filterType == 'income',
                      color: AppTheme.emerald,
                      onTap: () =>
                          setState(() => _filterType = 'income'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Transaction list
              Expanded(
                child: grouped.isEmpty
                    ? _EmptyState(
                        searchActive: _searchQuery.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                            bottom: 80, top: 8),
                        itemCount: grouped.length,
                        itemBuilder: (context, i) {
                          final item = grouped[i];
                          if (item is _DateHeader) {
                            return _DateGroupHeader(
                                label: item.label);
                          }
                          final tx = item as Transaction;
                          final cat = finance.categories
                              .where((c) => c.id == tx.categoryId)
                              .firstOrNull;
                          return _DismissibleTile(
                            tx: tx,
                            categoryName: cat?.name ?? 'Unknown',
                            categoryIcon:
                                cat?.icon ?? Icons.category,
                            categoryColor:
                                cat?.color ?? colorScheme.onSurface.withValues(alpha: 0.4),
                            onDelete: () =>
                                _handleDelete(context, finance, tx),
                          )
                              .animate()
                              .fadeIn(
                                  duration: 250.ms,
                                  delay: (i * 20).ms)
                              .slideX(begin: 0.03, duration: 250.ms);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Object> _groupTransactions(
      List<Transaction> txs, FinanceService finance) {
    if (txs.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final result = <Object>[];
    String? lastLabel;

    for (final tx in txs) {
      final txDate =
          DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (txDate == today) {
        label = 'Today';
      } else if (txDate == yesterday) {
        label = 'Yesterday';
      } else if (txDate.isAfter(weekStart)) {
        label = 'This Week';
      } else {
        label = DateFormat('MMMM yyyy').format(tx.date);
      }

      if (label != lastLabel) {
        result.add(_DateHeader(label));
        lastLabel = label;
      }
      result.add(tx);
    }
    return result;
  }

  Future<void> _handleDelete(
      BuildContext context, FinanceService finance, Transaction tx) async {
    await finance.deleteTransaction(tx.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${tx.description}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => finance.addTransaction(tx),
          ),
        ),
      );
    }
  }
}

class _DateHeader {
  final String label;
  const _DateHeader(this.label);
}

// ── Date Group Header ─────────────────────────────────────────────────────────
class _DateGroupHeader extends StatelessWidget {
  final String label;
  const _DateGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color = AppTheme.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? color
                  : colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Dismissible Tile ──────────────────────────────────────────────────────────
class _DismissibleTile extends StatelessWidget {
  final Transaction tx;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback onDelete;

  const _DismissibleTile({
    required this.tx,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.rose,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle it ourselves to allow undo
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: categoryColor.withValues(alpha: 0.12),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          title: Text(
            tx.description,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 14),
          ),
          subtitle: Text(
            '$categoryName • ${DateFormat('MMM d, yyyy').format(tx.date)}',
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          trailing: Consumer<FinanceService>(
            builder: (_, finance, __) => Text(
              tx.isExpense
                  ? '-${finance.currencySymbol}${tx.amount.toStringAsFixed(2)}'
                  : '+${finance.currencySymbol}${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: tx.isExpense ? AppTheme.rose : AppTheme.emerald,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool searchActive;
  const _EmptyState({required this.searchActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchActive ? Icons.search_off : Icons.receipt_long,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            searchActive
                ? 'No matching transactions'
                : 'No transactions yet',
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          if (!searchActive) ...[
            const SizedBox(height: 8),
            Text(
              'Add expenses from the dashboard',
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
