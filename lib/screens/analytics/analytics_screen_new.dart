import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../utils/formatters.dart';
import '../../utils/design_tokens.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import 'dart:math' as math;

/// Enhanced Analytics Screen with Dynamic Firebase Data
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'This Month';
  late TabController _tabController;
  
  final List<String> _periods = ['This Week', 'This Month', 'This Year'];

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
    final expensesAsync = ref.watch(expensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.pie_chart, size: 16)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 16)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb_outline, size: 16)),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.neutral500,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(expensesAsync, categoriesAsync, budgetsAsync),
          _buildTrendsTab(expensesAsync, categoriesAsync),
          _buildInsightsTab(expensesAsync, categoriesAsync, budgetsAsync),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    AsyncValue<List<ExpenseModel>> expensesAsync,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    AsyncValue<List<BudgetModel>> budgetsAsync,
  ) {
    return expensesAsync.when(
      data: (expenses) => categoriesAsync.when(
        data: (categories) => budgetsAsync.when(
          data: (budgets) => _buildOverviewContent(expenses, categories, budgets),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState('Failed to load budgets'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState('Failed to load categories'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState('Failed to load expenses'),
    );
  }

  Widget _buildTrendsTab(
    AsyncValue<List<ExpenseModel>> expensesAsync,
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return expensesAsync.when(
      data: (expenses) => categoriesAsync.when(
        data: (categories) => _buildTrendsContent(expenses, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState('Failed to load categories'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState('Failed to load expenses'),
    );
  }

  Widget _buildInsightsTab(
    AsyncValue<List<ExpenseModel>> expensesAsync,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    AsyncValue<List<BudgetModel>> budgetsAsync,
  ) {
    return expensesAsync.when(
      data: (expenses) => categoriesAsync.when(
        data: (categories) => budgetsAsync.when(
          data: (budgets) => _buildInsightsContent(expenses, categories, budgets),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState('Failed to load budgets'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState('Failed to load categories'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState('Failed to load expenses'),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(expensesProvider);
              ref.invalidate(categoriesProvider);
              ref.invalidate(budgetsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(
    List<ExpenseModel> expenses,
    List<CategoryModel> categories,
    List<BudgetModel> budgets,
  ) {
    final filteredExpenses = _getFilteredExpenses(expenses);
    final totalSpending = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final categoryTotals = _getCategoryTotals(filteredExpenses, categories);
    final averageDaily = _getAverageDaily(filteredExpenses);
    final transactionCount = filteredExpenses.length;

    return CustomScrollView(
      slivers: [
        // Period Selector
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildPeriodSelector(),
          ),
        ),

        // Summary Cards
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSummaryCards(totalSpending, transactionCount, averageDaily),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Spending Chart
        if (categoryTotals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                boxShadow: DesignTokens.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildPieChart(categoryTotals, categories),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Category List
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                boxShadow: DesignTokens.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categoryTotals.entries.take(5).map((entry) {
                    final category = categories.firstWhere(
                      (cat) => cat.id == entry.key,
                      orElse: () => CategoryModel(
                        id: entry.key,
                        name: 'Unknown',
                        icon: '📦',
                        color: AppTheme.neutral400.value,
                        isDefault: false,
                        createdAt: DateTime.now(),
                      ),
                    );
                    final percentage = totalSpending > 0
                        ? (entry.value / totalSpending) * 100
                        : 0.0;

                    return _buildCategoryItem(category, entry.value.toDouble(), percentage.toDouble());
                  }).toList(),
                ],
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: _periods.map((period) {
        final isSelected = period == _selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.neutral300,
                ),
              ),
              child: Text(
                period.replaceFirst('This ', ''),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.neutral700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(double totalSpending, int transactionCount, double averageDaily) {
    return Column(
      children: [
        // Total Spending Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: DesignTokens.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Spent',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.formatCurrency(totalSpending),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$transactionCount transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stats Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                  boxShadow: DesignTokens.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Average',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(averageDaily),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                  boxShadow: DesignTokens.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Largest Purchase',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getLargestPurchase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCategoryItem(CategoryModel category, double amount, double percentage) {
    final categoryColor = Color(category.color);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals, List<CategoryModel> categories) {
    final sections = categoryTotals.entries.take(6).map((entry) {
      final category = categories.firstWhere(
        (cat) => cat.id == entry.key,
        orElse: () => CategoryModel(
          id: entry.key,
          name: 'Unknown',
          icon: '📦',
          color: AppTheme.neutral400.value,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      );
      
      final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
      final percentage = total > 0 ? (entry.value / total) * 100 : 0;
      
      return PieChartSectionData(
        color: Color(category.color),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildTrendsContent(List<ExpenseModel> expenses, List<CategoryModel> categories) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: AppTheme.neutral400),
          SizedBox(height: 16),
          Text(
            'Trends Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Weekly and monthly spending trends will be available here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(
    List<ExpenseModel> expenses,
    List<CategoryModel> categories,
    List<BudgetModel> budgets,
  ) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: AppTheme.neutral400),
          SizedBox(height: 16),
          Text(
            'Insights Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI-powered spending insights and recommendations will be available here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return expenses.where((e) => e.transactionDate.isAfter(startOfWeek)).toList();
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return expenses.where((e) => e.transactionDate.isAfter(startOfMonth)).toList();
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        return expenses.where((e) => e.transactionDate.isAfter(startOfYear)).toList();
      default:
        return expenses;
    }
  }

  Map<String, double> _getCategoryTotals(List<ExpenseModel> expenses, List<CategoryModel> categories) {
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      if (expense.type == ExpenseType.expense) {
        categoryTotals[expense.categoryId] = (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      }
    }
    
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  double _getAverageDaily(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return 0;
    
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final days = _getDaysInPeriod();
    
    return days > 0 ? totalAmount / days : 0;
  }

  int _getDaysInPeriod() {
    switch (_selectedPeriod) {
      case 'This Week':
        return 7;
      case 'This Month':
        final now = DateTime.now();
        return DateTime(now.year, now.month + 1, 0).day;
      case 'This Year':
        final now = DateTime.now();
        return DateTimeExtension.isLeapYear(now.year) ? 366 : 365;
      default:
        return 30; // Default fallback
    }
  }

  String _getLargestPurchase() {
    // This would need to be calculated from filtered expenses
    // For now, return a placeholder
    return 'Rs. 0';
  }
}

extension DateTimeExtension on DateTime {
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
  }
}
