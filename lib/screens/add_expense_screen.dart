import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction.dart';
import '../services/finance_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? initialCategoryId;
  const AddExpenseScreen({super.key, this.initialCategoryId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final finance = context.read<FinanceService>();
      final tx = Transaction(
        id: finance.generateId(),
        categoryId: _selectedCategoryId!,
        description: _descController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
      );
      await finance.addTransaction(tx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Expense added!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add expense: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceService>();
    final categories = finance.categories;

    final sym = finance.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                hint: const Text('Select category'),
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 20),
                              const SizedBox(width: 10),
                              Text(cat.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Grocery shopping',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              Text('Amount ($sym)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '$sym ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Date',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_selectedCategoryId != null) ...[
                _BudgetPreview(
                    categoryId: _selectedCategoryId!,
                    finance: finance,
                    sym: sym),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Expense',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, duration: 300.ms),
      ),
    );
  }
}

class _BudgetPreview extends StatelessWidget {
  final String categoryId;
  final FinanceService finance;
  final String sym;

  const _BudgetPreview(
      {required this.categoryId, required this.finance, required this.sym});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cat = finance.categories.firstWhere((c) => c.id == categoryId);
    final remaining = cat.variance;
    final isOver = remaining < 0;
    final accentColor = isOver
        ? const Color(0xFFFF4D6A)
        : const Color(0xFF00D9A3);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.warning_amber : Icons.check_circle,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                Text(
                  isOver
                      ? 'Over budget by $sym${remaining.abs().toStringAsFixed(2)}'
                      : '$sym${remaining.toStringAsFixed(2)} remaining',
                  style: TextStyle(color: accentColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$sym${cat.actualAmount.toStringAsFixed(2)} / $sym${cat.budgetAmount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
