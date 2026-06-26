import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/income.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient))
                : null,
            title: const Text('Income'),
            automaticallyImplyLeading: false,
            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            actions: [
              IconButton(
                icon: Icon(Icons.add,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : null),
                onPressed: () =>
                    _showAddDialog(context, finance),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [AppTheme.navyDark, AppTheme.navy, AppTheme.navyLight]
                        : const [Color(0xFF22C55E), Color(0xFF4ADE80), Color(0xFF86EFAC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Income',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.white54, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMMM yyyy')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${finance.incomes.length} source${finance.incomes.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: finance.totalIncome),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => Text(
                        '${finance.currencySymbol}${val.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1),

              // List
              Expanded(
                child: finance.incomes.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: finance.incomes.length,
                        itemBuilder: (context, index) {
                          final income = finance.incomes[index];
                          return _IncomeCard(income: income, finance: finance)
                              .animate()
                              .fadeIn(
                                delay: Duration(
                                    milliseconds: 100 + index * 60),
                                duration: 300.ms,
                              )
                              .slideY(
                                begin: 0.2,
                                delay: Duration(
                                    milliseconds: 100 + index * 60),
                              );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context, finance),
            backgroundColor: AppTheme.navy,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Income',
                style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, FinanceService finance) {
    showDialog(
        context: context,
        builder: (_) => _AddIncomeDialog(finance: finance));
  }
}

// ── Income Card ───────────────────────────────────────────────────────────────
class _IncomeCard extends StatelessWidget {
  final Income income;
  final FinanceService finance;

  const _IncomeCard({required this.income, required this.finance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.rose,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => finance.deleteIncome(income.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.5)),
        ),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_up,
                color: AppTheme.emerald, size: 22),
          ),
          title: Text(
            income.source,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface),
          ),
          subtitle: Text(
            DateFormat('MMM d, yyyy').format(income.date),
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          trailing: Text(
            '+${finance.currencySymbol}${income.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.emerald,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.attach_money,
                size: 40, color: AppTheme.emerald),
          ),
          const SizedBox(height: 16),
          Text(
            'No income entries yet',
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add income',
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Add Income Dialog ─────────────────────────────────────────────────────────
class _AddIncomeDialog extends StatefulWidget {
  final FinanceService finance;
  const _AddIncomeDialog({required this.finance});

  @override
  State<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<_AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sourceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final income = Income(
      id: widget.finance.generateId(),
      source: _sourceCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      date: _date,
    );
    await widget.finance.addIncome(income);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Income'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Source (e.g., Salary)',
                  prefixIcon: Icon(Icons.work_outline)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter source' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money)),
              validator: (v) {
                final p = double.tryParse(v ?? '');
                return (p == null || p <= 0) ? 'Enter valid amount' : null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today)),
                child:
                    Text(DateFormat('MMM d, yyyy').format(_date)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
