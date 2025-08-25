import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlytic/providers/budget_provider.dart';
import 'package:finlytic/providers/auth_provider.dart';
import 'package:finlytic/providers/category_provider.dart';
import 'package:finlytic/models/budget_model.dart';
import 'package:finlytic/models/category_model.dart';
import 'package:finlytic/utils/constants.dart';

class CreateBudgetScreen extends ConsumerStatefulWidget {
  final BudgetModel? budget;
  
  const CreateBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedPeriod = 'Monthly';
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _periods = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    
    if (widget.budget != null) {
      final budget = widget.budget!;
      _nameController.text = budget.categoryId;
      _amountController.text = budget.amount.toString();
      _selectedCategoryId = budget.categoryId;
      _selectedPeriod = _budgetPeriodToString(budget.period);
      _startDate = budget.startDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = ref.read(userProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.budget != null) {
        // Update existing budget
        final updatedBudget = widget.budget!.copyWith(
          amount: double.parse(_amountController.text),
          categoryId: _selectedCategoryId!,
          period: _stringToBudgetPeriod(_selectedPeriod),
          startDate: _startDate,
          endDate: _calculateEndDate(_startDate, _selectedPeriod),
        );
        
        await ref.read(budgetsProvider.notifier).updateBudget(updatedBudget);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new budget
        final budget = BudgetModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.id,
          categoryId: _selectedCategoryId!,
          amount: double.parse(_amountController.text),
          period: _stringToBudgetPeriod(_selectedPeriod),
          startDate: _startDate,
          endDate: _calculateEndDate(_startDate, _selectedPeriod),
          enableNotifications: true,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await ref.read(budgetsProvider.notifier).addBudget(budget);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _calculateEndDate(DateTime startDate, String period) {
    switch (period) {
      case 'Weekly':
        return startDate.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'Quarterly':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case 'Yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  String _budgetPeriodToString(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  BudgetPeriod _stringToBudgetPeriod(String period) {
    switch (period) {
      case 'Weekly':
        return BudgetPeriod.weekly;
      case 'Monthly':
        return BudgetPeriod.monthly;
      case 'Quarterly':
        return BudgetPeriod.quarterly;
      case 'Yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.budget != null ? 'Edit Budget' : 'Create Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBudget,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Budget Name
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a budget name';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                hintText: 'e.g., Monthly Food Budget',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                hintText: 'Enter budget limit',
                prefixText: '\$ ',
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Category
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, _) {
                final categoriesAsync = ref.watch(categoriesProvider);
                
                return categoriesAsync.when(
                  data: (allCategories) {
                    final categories = allCategories.where((cat) => cat.name.toLowerCase() != 'income').toList();
                    
                    if (categories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'No categories available. Please create categories first.',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    
                    // Set initial category if not set
                    if (_selectedCategoryId == null && categories.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedCategoryId = categories.first.id;
                        });
                      });
                    }
                    
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: categories.map((category) {
                        final isSelected = category.id == _selectedCategoryId;
                        final color = Color(category.color);
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = category.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? color 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? color 
                                        : Colors.grey[700],
                                    fontWeight: isSelected 
                                        ? FontWeight.w600 
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Error loading categories: $error',
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Period
            Text(
              'Budget Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _periods.map((period) {
                final isSelected = period == _selectedPeriod;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = period),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Start Date
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(_startDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _selectStartDate,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBudget,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.budget != null ? 'Update Budget' : 'Create Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}