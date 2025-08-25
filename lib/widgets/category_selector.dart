import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlytic/utils/design_tokens.dart';
import 'package:finlytic/theme/app_theme.dart';
import 'package:finlytic/widgets/cards.dart';
import 'package:finlytic/providers/category_provider.dart';
import 'package:finlytic/models/category_model.dart';
import 'package:finlytic/screens/categories/category_management_screen.dart';

class CategorySelector extends ConsumerStatefulWidget {
  final String? selectedCategory;
  final String categoryType; // 'expense' or 'income' or 'all'
  final ValueChanged<String>? onCategorySelected;
  final bool showManageButton;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    this.categoryType = 'expense',
    this.onCategorySelected,
    this.showManageButton = true,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  String? _selectedCategory;
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Food & Dining', 'icon': '🍽️', 'color': AppTheme.success, 'type': 'expense'},
    {'name': 'Transportation', 'icon': '🚗', 'color': DesignTokens.accent, 'type': 'expense'},
    {'name': 'Shopping', 'icon': '🛒', 'color': AppTheme.warning, 'type': 'expense'},
    {'name': 'Entertainment', 'icon': '🎬', 'color': DesignTokens.accent, 'type': 'expense'},
    {'name': 'Health & Medical', 'icon': '🏥', 'color': AppTheme.error, 'type': 'expense'},
    {'name': 'Education', 'icon': '📚', 'color': Colors.purple, 'type': 'expense'},
    {'name': 'Utilities', 'icon': '💡', 'color': Colors.orange, 'type': 'expense'},
    {'name': 'Travel', 'icon': '✈️', 'color': Colors.pink, 'type': 'expense'},
    {'name': 'Personal Care', 'icon': '💄', 'color': Colors.teal, 'type': 'expense'},
    {'name': 'Home & Garden', 'icon': '🏠', 'color': Colors.green, 'type': 'expense'},
    {'name': 'Salary', 'icon': '💰', 'color': AppTheme.success, 'type': 'income'},
    {'name': 'Freelance', 'icon': '💻', 'color': DesignTokens.accent, 'type': 'income'},
    {'name': 'Investment', 'icon': '📈', 'color': AppTheme.warning, 'type': 'income'},
    {'name': 'Business', 'icon': '🏢', 'color': AppTheme.primary, 'type': 'income'},
    {'name': 'Other Income', 'icon': '💵', 'color': Colors.green, 'type': 'income'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return categoriesAsync.when(
      data: (userCategories) => _buildSelector(userCategories),
      loading: () => _buildLoadingSelector(),
      error: (error, stack) => _buildErrorSelector(),
    );
  }

  Widget _buildSelector(List<CategoryModel> userCategories) {
    final availableCategories = _getAvailableCategories(userCategories);
    final selectedCategoryData = _getSelectedCategoryData(availableCategories);

    return AppCard(
      child: Column(
        children: [
          // Selected Category Display
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                if (selectedCategoryData != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selectedCategoryData['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        selectedCategoryData['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                ] else ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                ],
                Expanded(
                  child: Text(
                    selectedCategoryData?['name'] ?? 'Select Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selectedCategoryData != null 
                          ? null 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          
          // Expanded Category Grid
          if (_isExpanded) ...[
            const SizedBox(height: DesignTokens.space4),
            const Divider(),
            const SizedBox(height: DesignTokens.space4),
            _buildCategoryGrid(availableCategories),
            if (widget.showManageButton) ...[
              const SizedBox(height: DesignTokens.space4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openCategoryManagement,
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Categories'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSelector() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          const Expanded(
            child: Text('Loading categories...'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSelector() {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          const Expanded(
            child: Text('Error loading categories'),
          ),
          IconButton(
            onPressed: () => ref.invalidate(categoriesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Map<String, dynamic>> categories) {
    final filteredCategories = categories.where((cat) {
      if (widget.categoryType == 'all') return true;
      return cat['type'] == widget.categoryType;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: DesignTokens.space2,
        crossAxisSpacing: DesignTokens.space2,
        childAspectRatio: 1,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        final isSelected = category['name'] == _selectedCategory;
        
        return GestureDetector(
          onTap: () => _selectCategory(category['name']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? category['color'].withValues(alpha: 0.2)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: isSelected 
                  ? Border.all(color: category['color'], width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category['icon'],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? category['color'] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getAvailableCategories(List<CategoryModel> userCategories) {
    final allCategories = <Map<String, dynamic>>[];
    
    // Add user categories
    for (final category in userCategories) {
      allCategories.add({
        'name': category.name,
        'icon': category.icon,
        'color': Color(category.color),
        'type': category.type,
        'isDefault': false,
      });
    }
    
    // Add default categories that don't exist in user categories
    for (final defaultCat in _defaultCategories) {
      if (!userCategories.any((cat) => cat.name == defaultCat['name'])) {
        allCategories.add({
          ...defaultCat,
          'isDefault': true,
        });
      }
    }
    
    return allCategories;
  }

  Map<String, dynamic>? _getSelectedCategoryData(List<Map<String, dynamic>> categories) {
    if (_selectedCategory == null) return null;
    
    try {
      return categories.firstWhere((cat) => cat['name'] == _selectedCategory);
    } catch (e) {
      return null;
    }
  }

  void _selectCategory(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      _isExpanded = false;
    });
    
    widget.onCategorySelected?.call(categoryName);
  }

  void _openCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    ).then((_) {
      // Refresh categories when returning from management screen
      ref.invalidate(categoriesProvider);
    });
  }
}

/// Compact category selector for smaller spaces
class CompactCategorySelector extends ConsumerWidget {
  final String? selectedCategory;
  final String categoryType;
  final ValueChanged<String>? onCategorySelected;

  const CompactCategorySelector({
    super.key,
    this.selectedCategory,
    this.categoryType = 'expense',
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return categoriesAsync.when(
      data: (userCategories) => _buildCompactSelector(context, userCategories),
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: const Center(
          child: Text('Error loading categories'),
        ),
      ),
    );
  }

  Widget _buildCompactSelector(BuildContext context, List<CategoryModel> userCategories) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userCategories.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == userCategories.length) {
            // Add category button
            return Padding(
              padding: const EdgeInsets.only(right: DesignTokens.space2),
              child: GestureDetector(
                onTap: () => _openCategoryManagement(context),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.all(DesignTokens.space2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final category = userCategories[index];
          final isSelected = category.name == selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.space2),
            child: GestureDetector(
              onTap: () => onCategorySelected?.call(category.name),
              child: Container(
                width: 60,
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Color(category.color).withValues(alpha: 0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: isSelected 
                      ? Border.all(color: Color(category.color), width: 2)
                      : Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Color(category.color) : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCategoryManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }
}