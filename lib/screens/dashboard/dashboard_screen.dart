import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense_model.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../services/budget_service.dart';
import '../../utils/formatters.dart';
import '../../utils/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../expenses/add_expense_screen.dart';
import '../goals/goals_screen.dart';
import '../categories/category_management_screen.dart';

/// Modern Minimal Dashboard Screen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final expensesAsync = ref.watch(expensesProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Clean Modern Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: userAsync.when(
                        data: (user) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${user != null ? user.name.split(' ').first : 'User'}! 👋',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Here\'s your financial overview',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.neutral600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        loading: () => Container(
                          height: 50,
                          width: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.neutral200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        error: (_, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi there! 👋',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Here\'s your financial overview',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.neutral600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Clean Notification Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.neutral100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.neutral200,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _showNotifications(context),
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.neutral600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Enhanced Quick Actions
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _buildEnhancedQuickActions(context),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Budget Overview Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildBudgetOverview(context),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Financial Overview Cards
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: expensesAsync.when(
                  data: (expenses) => _buildEnhancedOverviewCards(context, expenses),
                  loading: () => _buildLoadingCards(),
                  error: (error, _) => _buildErrorCard(error.toString()),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Section Title with Action
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral900,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToExpenses(context),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Transaction List
            expensesAsync.when(
              data: (expenses) => _buildTransactionList(expenses),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "dashboard_fab",
        onPressed: () => _navigateToAddExpense(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
    );
  }



  Widget _buildLoadingCards() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<ExpenseModel> expenses) {
    final recentExpenses = expenses.take(5).toList();
    
    if (recentExpenses.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first expense',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = recentExpenses[index];
          return Container(
            margin: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.categoryId),
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final categoriesMap = ref.watch(categoriesMapProvider);
                          final categoryName = categoriesMap[expense.categoryId]?.name ?? 'Unknown';
                          return Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCurrency(expense.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: recentExpenses.length,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.bolt;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  // Enhanced Homepage UI/UX Methods
  Widget _buildEnhancedQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: AppTheme.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedQuickActionItem(
                  icon: Icons.add_circle_rounded,
                  label: 'Add Expense',
                  subtitle: 'Track spending',
                  color: AppTheme.primary,
                  onTap: () => _navigateToAddExpense(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedQuickActionItem(
                  icon: Icons.flag_rounded,
                  label: 'Goals',
                  subtitle: 'View progress',
                  color: AppTheme.success,
                  onTap: () => _navigateToGoals(context),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEnhancedQuickActionItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  subtitle: 'Manage tags',
                  color: AppTheme.warning,
                  onTap: () => _navigateToCategories(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedQuickActionItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  subtitle: 'View insights',
                  color: AppTheme.accent,
                  onTap: () => _navigateToAnalytics(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActionItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final budgetSummaryAsync = ref.watch(budgetSummaryProvider);
        final budgetsAsync = ref.watch(budgetsProvider);
        
        return budgetSummaryAsync.when(
          data: (summary) => budgetsAsync.when(
            data: (budgets) => _buildBudgetOverviewContent(context, summary, budgets),
            loading: () => _buildBudgetLoadingState(),
            error: (error, _) => _buildBudgetErrorState(),
          ),
          loading: () => _buildBudgetLoadingState(),
          error: (error, _) => _buildBudgetErrorState(),
        );
      },
    );
  }

  Widget _buildBudgetOverviewContent(BuildContext context, BudgetSummary summary, List<BudgetModel> budgets) {
    final activeBudgets = budgets.where((budget) => budget.isActive && budget.isCurrentPeriod).take(4).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success.withValues(alpha: 0.1),
            AppTheme.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Budget Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: summary.isOverBudget 
                      ? AppTheme.error.withValues(alpha: 0.2)
                      : AppTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  summary.isOverBudget ? 'Over Budget' : 'On Track',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: summary.isOverBudget ? AppTheme.error : AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (activeBudgets.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppTheme.neutral400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active budgets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create budgets to track your spending',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            )
          else
            // Budget items
            for (int i = 0; i < activeBudgets.length; i += 2)
              Padding(
                padding: EdgeInsets.only(bottom: i + 2 < activeBudgets.length ? 16 : 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, _) => _buildBudgetItem(
                          activeBudgets[i],
                          ref.watch(budgetSpendingStatusProvider(activeBudgets[i])).value,
                        ),
                      ),
                    ),
                    if (i + 1 < activeBudgets.length) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) => _buildBudgetItem(
                            activeBudgets[i + 1],
                            ref.watch(budgetSpendingStatusProvider(activeBudgets[i + 1])).value,
                          ),
                        ),
                      ),
                    ] else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBudgetLoadingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBudgetErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading budgets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, BudgetSpendingStatus? status) {
    final spentAmount = status?.spentAmount ?? 0.0;
    final percentage = budget.amount > 0 ? spentAmount / budget.amount : 0.0;
    final isOverBudget = percentage > 1.0;
    
    return Consumer(
      builder: (context, ref, _) {
        final categoryColors = ref.watch(categoryColorsProvider);
        final categoriesMap = ref.watch(categoriesMapProvider);
        final categoryName = categoriesMap[budget.categoryId]?.name ?? 'Unknown Category';
        final displayColor = isOverBudget 
            ? AppTheme.error 
            : Color(categoryColors[budget.categoryId] ?? 0xFF6B7280);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: displayColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: displayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                Formatters.formatCurrency(spentAmount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: displayColor,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                'of ${Formatters.formatCurrency(budget.amount)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.neutral600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: AppTheme.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                minHeight: 4,
              ),
            ],
          ),
        );
      },
    );
  }





  Widget _buildEnhancedOverviewCards(BuildContext context, List<ExpenseModel> expenses) {
    final thisMonth = expenses.where((expense) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return expense.transactionDate.isAfter(startOfMonth);
    }).toList();
    
    final totalThisMonth = thisMonth.fold(0.0, (sum, expense) => sum + expense.amount);
    final transactionCount = thisMonth.length;
    final avgTransaction = thisMonth.isNotEmpty ? totalThisMonth / thisMonth.length : 0.0;
    
    final lastMonth = expenses.where((expense) {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      return expense.transactionDate.isAfter(startOfLastMonth) && 
             expense.transactionDate.isBefore(endOfLastMonth);
    }).toList();
    
    final totalLastMonth = lastMonth.fold(0.0, (sum, expense) => sum + expense.amount);
    final percentageChange = totalLastMonth > 0 
        ? ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100 
        : 0.0;
    
    return Column(
      children: [
        // Main spending card with gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.neutral50,
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: percentageChange >= 0 
                          ? AppTheme.error.withValues(alpha: 0.1)
                          : AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          percentageChange >= 0 
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: percentageChange >= 0 
                              ? AppTheme.error
                              : AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentageChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: percentageChange >= 0 
                                ? AppTheme.error
                                : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                Formatters.formatCurrency(totalThisMonth),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: AppTheme.neutral900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$transactionCount transactions',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Enhanced stats row
        Row(
          children: [
            // Average transaction with icon
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  boxShadow: DesignTokens.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Icon(
                            Icons.trending_up_rounded,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Average',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Formatters.formatCurrency(avgTransaction),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Transactions count with icon
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  boxShadow: DesignTokens.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Icon(
                            Icons.receipt_rounded,
                            size: 16,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$transactionCount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  void _navigateToGoals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoalsScreen(),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    // Navigate to analytics tab (index 4 in main navigation)
    // This would require passing a callback or using a navigation controller
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics feature coming soon!')),
    );
  }

  void _navigateToExpenses(BuildContext context) {
    // Navigate to expenses tab (index 1 in main navigation)
    // This would require passing a callback or using a navigation controller
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Go to main navigation to view all expenses')),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}