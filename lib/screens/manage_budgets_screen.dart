import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/category.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

class ManageBudgetsScreen extends StatelessWidget {
  const ManageBudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) {
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient))
                : null,
            title: const Text('Manage Budgets'),
            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            actions: [
              if (!finance.isBudgetLocked)
                IconButton(
                  icon: Icon(Icons.add,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null),
                  onPressed: () => _showCategoryDialog(context, finance),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (finance.isBudgetLocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Budgets are locked after the 7th — wait until next month to make changes.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _TotalBudgetCard(finance: finance)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.05, duration: 300.ms),
              const SizedBox(height: 16),
              Text('Categories',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              ...finance.categories.indexed.map((entry) {
                final (i, cat) = entry;
                return _CategoryTile(
                  category: cat,
                  isLocked: finance.isBudgetLocked,
                  onEdit: () =>
                      _showCategoryDialog(context, finance, category: cat),
                  onDelete: () => _confirmDelete(context, finance, cat),
                )
                    .animate()
                    .fadeIn(duration: 250.ms, delay: (i * 30).ms)
                    .slideX(begin: 0.03, duration: 250.ms);
              }),
            ],
          ),
          floatingActionButton: finance.isBudgetLocked
              ? null
              : FloatingActionButton(
                  onPressed: () => _showCategoryDialog(context, finance),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, FinanceService finance,
      {BudgetCategory? category}) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(finance: finance, category: category),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, FinanceService finance, BudgetCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${cat.name}?'),
        content: const Text(
            'This will also delete all transactions for this category.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await finance.deleteCategory(cat.id);
    }
  }
}

class _TotalBudgetCard extends StatefulWidget {
  final FinanceService finance;
  const _TotalBudgetCard({required this.finance});

  @override
  State<_TotalBudgetCard> createState() => _TotalBudgetCardState();
}

class _TotalBudgetCardState extends State<_TotalBudgetCard> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.finance
            .toDisplay(widget.finance.totalMonthlyBudget)
            .toStringAsFixed(2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Monthly Budget',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _editing
                      ? TextFormField(
                          controller: _ctrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        )
                      : Text(
                          '${widget.finance.currencySymbol} ${widget.finance.toDisplay(widget.finance.totalMonthlyBudget).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary),
                        ),
                ),
                const SizedBox(width: 12),
                if (_editing) ...[
                  ElevatedButton(
                    onPressed: () async {
                      final val = double.tryParse(_ctrl.text);
                      if (val != null && val > 0) {
                        await widget.finance
                            .updateTotalBudget(widget.finance.toBase(val));
                        setState(() => _editing = false);
                      }
                    },
                    child: const Text('Save'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('Cancel'),
                  ),
                ] else if (widget.finance.isBudgetLocked)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.primary),
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final BudgetCategory category;
  final bool isLocked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.isLocked,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withAlpha(25),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            'Budget: ${finance.currencySymbol}${finance.toDisplay(category.budgetAmount).toStringAsFixed(2)} | Spent: ${finance.currencySymbol}${finance.toDisplay(category.actualAmount).toStringAsFixed(2)}'),
        trailing: isLocked
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.lock_outline, color: Colors.orange, size: 20),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit),
                  IconButton(
                      icon: Icon(Icons.delete, color: AppTheme.rose),
                      onPressed: onDelete),
                ],
              ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final FinanceService finance;
  final BudgetCategory? category;

  const _CategoryDialog({required this.finance, this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _budgetCtrl;
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = const Color(0xFF22C55E);

  static const _iconOptions = [
    Icons.home, Icons.restaurant, Icons.directions_car,
    Icons.health_and_safety, Icons.movie, Icons.shopping_bag,
    Icons.bolt, Icons.savings, Icons.school, Icons.flight,
    Icons.fitness_center, Icons.pets, Icons.wifi, Icons.phone,
  ];

  // A curated, brand-harmonious palette (instead of raw Material swatches)
  // so categories read as a cohesive set rather than clashing primary colors.
  static const _colorOptions = [
    Color(0xFF22C55E), // green (brand)
    Color(0xFF0EA5E9), // sky
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // rose
    Color(0xFF8B5CF6), // violet
    Color(0xFF14B8A6), // teal
    Color(0xFFEC4899), // pink
    Color(0xFF6366F1), // indigo
    Color(0xFFF97316), // orange
    Color(0xFF06B6D4), // cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.category?.name ?? '');
    _budgetCtrl = TextEditingController(
        text: widget.category != null
            ? widget.finance
                .toDisplay(widget.category!.budgetAmount)
                .toStringAsFixed(2)
            : '');
    _selectedIcon = widget.category?.icon ?? Icons.category;
    _selectedColor = widget.category?.color ?? const Color(0xFF22C55E);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final finance = widget.finance;

    if (widget.category != null) {
      widget.category!
        ..name = _nameCtrl.text.trim()
        ..budgetAmount = finance.toBase(double.parse(_budgetCtrl.text))
        ..icon = _selectedIcon
        ..color = _selectedColor;
      await finance.updateCategory(widget.category!);
    } else {
      await finance.addCategory(BudgetCategory(
        id: finance.generateId(),
        name: _nameCtrl.text.trim(),
        budgetAmount: finance.toBase(double.parse(_budgetCtrl.text)),
        icon: _selectedIcon,
        color: _selectedColor,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title:
          Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Budget Amount (${widget.finance.currencySymbol})',
                    prefixText: '${widget.finance.currencySymbol} ',
                    border: const OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final p = double.tryParse(v);
                  if (p == null || p < 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Icon',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions
                    .map((icon) => GestureDetector(
                          onTap: () => setState(() => _selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedIcon == icon
                                  ? _selectedColor.withAlpha(51)
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedIcon == icon
                                    ? _selectedColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(icon,
                                color: _selectedIcon == icon
                                    ? _selectedColor
                                    : Colors.grey),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Color',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions
                    .map((color) => GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: _selectedColor == color
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
