import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/savings_goal.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(
                    decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient),
                  )
                : null,
            title: const Text('Savings Goals'),
            automaticallyImplyLeading: false,
          ),
          body: finance.goals.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: finance.goals.length,
                  itemBuilder: (context, index) {
                    final goal = finance.goals[index];
                    return _GoalCard(goal: goal, finance: finance)
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 100 + index * 80),
                          duration: 350.ms,
                        )
                        .slideY(
                          begin: 0.25,
                          delay: Duration(milliseconds: 100 + index * 80),
                          duration: 350.ms,
                          curve: AppTheme.motionCurve,
                        );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _AddGoalDialog(finance: finance),
            ),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Goal',
                style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final FinanceService finance;

  const _GoalCard({required this.goal, required this.finance});

  @override
  Widget build(BuildContext context) {
    final color = goal.isCompleted ? AppTheme.emerald : AppTheme.primary;
    final progress = goal.progressPercent;
    final sym = context.watch<FinanceService>().currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        goal.isCompleted
                            ? Icons.check_circle
                            : Icons.savings,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface),
                          ),
                          if (goal.targetDate != null)
                            Text(
                              'Target: ${DateFormat('MMM yyyy').format(goal.targetDate!)}',
                              style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Complete!',
                    style: TextStyle(
                        color: AppTheme.emerald,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.rose, size: 20),
                  onPressed: () => finance.deleteGoal(goal.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sym${goal.currentAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  Text(
                    'of $sym${goal.targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  Text(
                    '$sym${(goal.targetAmount - goal.currentAmount).clamp(0, double.infinity).toStringAsFixed(0)} remaining',
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: AppTheme.motionCurve,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    _showAddFundsDialog(context, goal),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Funds'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
              prefixIcon: Icon(Icons.attach_money)),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                await finance.addToGoal(goal.id, val);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
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
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first goal',
            style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Add Goal Dialog ───────────────────────────────────────────────────────────
class _AddGoalDialog extends StatefulWidget {
  final FinanceService finance;
  const _AddGoalDialog({required this.finance});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime? _targetDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final goal = SavingsGoal(
      id: widget.finance.generateId(),
      name: _nameCtrl.text.trim(),
      targetAmount: double.parse(_targetCtrl.text),
      targetDate: _targetDate,
    );
    await widget.finance.addGoal(goal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Savings Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  prefixIcon: Icon(Icons.flag_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money)),
              validator: (v) {
                final p = double.tryParse(v ?? '');
                return (p == null || p <= 0)
                    ? 'Enter valid amount'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now()
                      .add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Target Date (optional)',
                    prefixIcon: Icon(Icons.calendar_today)),
                child: Text(_targetDate == null
                    ? 'No date set'
                    : DateFormat('MMM d, yyyy').format(_targetDate!)),
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
