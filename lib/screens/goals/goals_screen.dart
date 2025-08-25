import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Goals & Savings Tracking Screen - Modern & Clean
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.flag, size: 16)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle, size: 16)),
            Tab(text: 'All', icon: Icon(Icons.list, size: 16)),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.neutral500,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveGoalsTab(),
          _buildCompletedGoalsTab(),
          _buildAllGoalsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "goals_fab",
        onPressed: _showCreateGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActiveGoalsTab() {
    final activeGoalsAsync = ref.watch(activeGoalsProvider);
    
    return activeGoalsAsync.when(
      data: (activeGoals) {
        if (activeGoals.isEmpty) {
          return _buildEmptyState(
            'No active goals',
            'Create your first savings goal to start tracking your progress',
            Icons.flag_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: activeGoals.length,
          itemBuilder: (context, index) => _buildGoalCard(activeGoals[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error', style: TextStyle(color: AppTheme.error)),
      ),
    );
  }

  Widget _buildCompletedGoalsTab() {
    final completedGoalsAsync = ref.watch(completedGoalsProvider);
    
    return completedGoalsAsync.when(
      data: (completedGoals) {
        if (completedGoals.isEmpty) {
          return _buildEmptyState(
            'No completed goals yet',
            'Keep working towards your goals to see them here',
            Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: completedGoals.length,
          itemBuilder: (context, index) => _buildGoalCard(completedGoals[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error', style: TextStyle(color: AppTheme.error)),
      ),
    );
  }

  Widget _buildAllGoalsTab() {
    final goalsAsync = ref.watch(goalsProvider);
    
    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return _buildEmptyState(
            'No goals yet',
            'Create your first goal to start tracking your progress',
            Icons.flag_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: goals.length,
          itemBuilder: (context, index) => _buildGoalCard(goals[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error', style: TextStyle(color: AppTheme.error)),
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final progress = goal.progressPercentage / 100;
    final isCompleted = goal.isCompleted;
    final daysLeft = goal.daysRemaining;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowSm,
        border: isCompleted 
            ? Border.all(color: AppTheme.success, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(goal.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryIcon(goal.category),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutral900,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.category.name.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                PopupMenuButton<String>(
                  onSelected: (action) => _handleGoalAction(action, goal),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (!isCompleted)
                      const PopupMenuItem(
                        value: 'add_money',
                        child: ListTile(
                          leading: Icon(Icons.add_circle),
                          title: Text('Add Money'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatCurrency(goal.currentAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _getCategoryColor(goal.category),
                      ),
                    ),
                    Text(
                      'of ${Formatters.formatCurrency(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.neutral200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(goal.category)),
                    minHeight: 8,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.progressPercentage.toStringAsFixed(1)}% complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutral700,
                      ),
                    ),
                    Text(
                      daysLeft > 0 
                          ? '$daysLeft days left'
                          : isCompleted 
                              ? 'Goal achieved!'
                              : 'Overdue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: daysLeft > 0 
                            ? AppTheme.neutral700
                            : isCompleted 
                                ? AppTheme.success
                                : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              
              // Quick Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMoneyDialog(goal),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Add Money'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(goal.category).withValues(alpha: 0.1),
                    foregroundColor: _getCategoryColor(goal.category),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleGoalAction(String action, GoalModel goal) {
    switch (action) {
      case 'edit':
        _showEditGoalDialog(goal);
        break;
      case 'add_money':
        _showAddMoneyDialog(goal);
        break;
      case 'delete':
        _showDeleteConfirmation(goal);
        break;
    }
  }

  Color _getCategoryColor(GoalCategory category) {
    switch (category) {
      case GoalCategory.emergency:
        return const Color(0xFF10B981); // Green
      case GoalCategory.travel:
        return const Color(0xFF3B82F6); // Blue
      case GoalCategory.house:
        return const Color(0xFF8B5CF6); // Purple
      case GoalCategory.car:
        return const Color(0xFFF59E0B); // Amber
      case GoalCategory.education:
        return const Color(0xFF06B6D4); // Cyan
      case GoalCategory.investment:
        return const Color(0xFFEF4444); // Red
      case GoalCategory.retirement:
        return const Color(0xFF84CC16); // Lime
      case GoalCategory.wedding:
        return const Color(0xFFEC4899); // Pink
      case GoalCategory.health:
        return const Color(0xFF14B8A6); // Teal
      case GoalCategory.business:
        return const Color(0xFF6366F1); // Indigo
      case GoalCategory.gadgets:
        return const Color(0xFF8B5CF6); // Violet
      case GoalCategory.vacation:
        return const Color(0xFFF97316); // Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.emergency:
        return '🛡️';
      case GoalCategory.travel:
        return '✈️';
      case GoalCategory.house:
        return '🏠';
      case GoalCategory.car:
        return '🚗';
      case GoalCategory.education:
        return '📚';
      case GoalCategory.investment:
        return '📈';
      case GoalCategory.retirement:
        return '🏖️';
      case GoalCategory.wedding:
        return '💒';
      case GoalCategory.health:
        return '⚕️';
      case GoalCategory.business:
        return '💼';
      case GoalCategory.gadgets:
        return '💻';
      case GoalCategory.vacation:
        return '🏝️';
      default:
        return '🎯';
    }
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateGoalDialog(),
    );
  }

  void _showEditGoalDialog(GoalModel goal) {
    showDialog(
      context: context,
      builder: (context) => _EditGoalDialog(goal: goal),
    );
  }

  void _showAddMoneyDialog(GoalModel goal) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: ${Formatters.formatCurrency(goal.currentAmount)}',
              style: TextStyle(color: AppTheme.neutral600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to add',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                try {
                  await ref.read(goalsProvider.notifier)
                      .addProgressToGoal(goal.id, amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Money added successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(GoalModel goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Goal "${goal.title}" deleted'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting goal: $e'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateGoalDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends ConsumerState<_CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _uuid = const Uuid();
  
  GoalCategory _selectedCategory = GoalCategory.other;
  GoalType _selectedType = GoalType.savings;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  int _priority = 3;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Goal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: GoalCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Target Date'),
                subtitle: Text(Formatters.formatDisplayDate(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _targetDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createGoal,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createGoal() async {
    if (_formKey.currentState!.validate()) {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final goal = GoalModel(
        id: _uuid.v4(),
        userId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        targetAmount: double.parse(_targetAmountController.text),
        startDate: DateTime.now(),
        targetDate: _targetDate,
        category: _selectedCategory,
        type: _selectedType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        priority: _priority,
      );

      try {
        await ref.read(goalsProvider.notifier).addGoal(goal);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

class _EditGoalDialog extends ConsumerStatefulWidget {
  final GoalModel goal;
  
  const _EditGoalDialog({required this.goal});

  @override
  ConsumerState<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends ConsumerState<_EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetAmountController;
  
  late GoalCategory _selectedCategory;
  late GoalType _selectedType;
  late DateTime _targetDate;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(text: widget.goal.description);
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _selectedCategory = widget.goal.category;
    _selectedType = widget.goal.type;
    _targetDate = widget.goal.targetDate;
    _priority = widget.goal.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Goal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: GoalCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Target Date'),
                subtitle: Text(Formatters.formatDisplayDate(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _targetDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateGoal,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateGoal() async {
    if (_formKey.currentState!.validate()) {
      final updatedGoal = widget.goal.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        targetAmount: double.parse(_targetAmountController.text),
        targetDate: _targetDate,
        category: _selectedCategory,
        type: _selectedType,
        priority: _priority,
        updatedAt: DateTime.now(),
      );

      try {
        await ref.read(goalsProvider.notifier).updateGoal(updatedGoal);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating goal: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}