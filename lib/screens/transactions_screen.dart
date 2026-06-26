import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/finance_service.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';

// Unifies expense Transactions and Income entries into one ledger so both
// show up side by side in the All Transactions list.
class _LedgerEntry {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool isIncome;
  final String? categoryId;

  const _LedgerEntry({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.isIncome,
    this.categoryId,
  });

  factory _LedgerEntry.fromTransaction(
      Transaction tx, String categoryName, IconData icon, Color color) {
    return _LedgerEntry(
      id: tx.id,
      description: tx.description,
      amount: tx.amount,
      date: tx.date,
      isExpense: tx.isExpense,
      categoryName: categoryName,
      categoryIcon: icon,
      categoryColor: color,
      isIncome: false,
      categoryId: tx.categoryId,
    );
  }

  factory _LedgerEntry.fromIncome(Income income) => _LedgerEntry(
        id: income.id,
        description: income.source,
        amount: income.amount,
        date: income.date,
        isExpense: false,
        categoryName: 'Income',
        categoryIcon: Icons.trending_up,
        categoryColor: AppTheme.emerald,
        isIncome: true,
      );
}

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
        var entries = <_LedgerEntry>[
          ...finance.transactions.map((tx) {
            final cat = finance.categories
                .where((c) => c.id == tx.categoryId)
                .firstOrNull;
            return _LedgerEntry.fromTransaction(
              tx,
              cat?.name ?? 'Unknown',
              cat?.icon ?? Icons.category,
              cat?.color ??
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            );
          }),
          ...finance.incomes.map(_LedgerEntry.fromIncome),
        ]..sort((a, b) => b.date.compareTo(a.date));

        // Filter
        if (_filterType == 'expense') {
          entries = entries.where((e) => e.isExpense).toList();
        } else if (_filterType == 'income') {
          entries = entries.where((e) => !e.isExpense).toList();
        }

        // Search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          entries = entries
              .where((e) =>
                  e.description.toLowerCase().contains(q) ||
                  e.amount.toString().contains(q))
              .toList();
        }

        // Group by date label
        final grouped = _groupEntries(entries);
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
                          final entry = item as _LedgerEntry;
                          return _DismissibleTile(
                            entry: entry,
                            onDelete: () =>
                                _handleDelete(context, finance, entry),
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

  List<Object> _groupEntries(List<_LedgerEntry> entries) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final result = <Object>[];
    String? lastLabel;

    for (final entry in entries) {
      final txDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      String label;
      if (txDate == today) {
        label = 'Today';
      } else if (txDate == yesterday) {
        label = 'Yesterday';
      } else if (txDate.isAfter(weekStart)) {
        label = 'This Week';
      } else {
        label = DateFormat('MMMM yyyy').format(entry.date);
      }

      if (label != lastLabel) {
        result.add(_DateHeader(label));
        lastLabel = label;
      }
      result.add(entry);
    }
    return result;
  }

  Future<void> _handleDelete(
      BuildContext context, FinanceService finance, _LedgerEntry entry) async {
    if (entry.isIncome) {
      await finance.deleteIncome(entry.id);
    } else {
      await finance.deleteTransaction(entry.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${entry.description}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => entry.isIncome
                ? finance.addIncome(Income(
                    id: entry.id,
                    source: entry.description,
                    amount: entry.amount,
                    date: entry.date,
                  ))
                : finance.addTransaction(Transaction(
                    id: entry.id,
                    categoryId: entry.categoryId!,
                    description: entry.description,
                    amount: entry.amount,
                    date: entry.date,
                    isExpense: entry.isExpense,
                  )),
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
class _FilterChip extends StatefulWidget {
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
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: AppTheme.motionFast,
          curve: AppTheme.motionCurve,
          scale: _hovering && !widget.selected ? 1.06 : 1.0,
          child: AnimatedContainer(
            duration: AppTheme.motionFast,
            curve: AppTheme.motionCurve,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.color
                  : _hovering
                      ? widget.color.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.selected
                      ? widget.color
                      : _hovering
                          ? widget.color.withValues(alpha: 0.6)
                          : colorScheme.outline
                              .withValues(alpha: isDark ? 1.0 : 0.5)),
              boxShadow: _hovering && !widget.selected
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.selected
                    ? Colors.white
                    : _hovering
                        ? widget.color
                        : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dismissible Tile ──────────────────────────────────────────────────────────
class _DismissibleTile extends StatelessWidget {
  final _LedgerEntry entry;
  final VoidCallback onDelete;

  const _DismissibleTile({
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(entry.id),
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
            backgroundColor: entry.categoryColor.withValues(alpha: 0.12),
            child: Icon(entry.categoryIcon, color: entry.categoryColor, size: 20),
          ),
          title: Text(
            entry.description,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 14),
          ),
          subtitle: Text(
            '${entry.categoryName} • ${DateFormat('MMM d, yyyy').format(entry.date)}',
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          trailing: Consumer<FinanceService>(
            builder: (_, finance, __) => Text(
              entry.isExpense
                  ? '-${finance.currencySymbol}${entry.amount.toStringAsFixed(2)}'
                  : '+${finance.currencySymbol}${entry.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: entry.isExpense ? AppTheme.rose : AppTheme.emerald,
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
