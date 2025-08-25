import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';

// Category service provider
final categoryServiceProvider = Provider<CategoryService>((ref) => CategoryService());

// Categories provider
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  return CategoriesNotifier(ref);
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoriesNotifier(this._ref) : super(const AsyncValue.data([])) {
    // Delay loading to avoid circular dependencies
    Future.microtask(_loadCategories);
  }

  final Ref _ref;
  CategoryService get _categoryService => _ref.read(categoryServiceProvider);

  Future<void> _loadCategories() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      
      if (userId == null) {
        // Load default categories if no user
        final defaultCategories = await _categoryService.getDefaultCategories();
        state = AsyncValue.data(defaultCategories);
        return;
      }

      final categories = await _categoryService.getCategoriesForUser(userId);
      state = AsyncValue.data(categories);
    } catch (error) {
      // Try to load from local storage
      try {
        final userId = _ref.read(currentUserIdProvider);
        final localCategories = _categoryService.getOfflineCategories(userId);
        state = AsyncValue.data(localCategories);
      } catch (_) {
        // Fallback to default categories
        final defaultCategories = await _categoryService.getDefaultCategories();
        state = AsyncValue.data(defaultCategories);
      }
    }
  }

  Future<void> refreshCategories() async {
    await _loadCategories();
  }

  Future<void> initializeDefaultCategories() async {
    try {
      await _categoryService.initializeDefaultCategories();
      await _loadCategories();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      final addedCategory = await _categoryService.addCategory(category);
      
      // Update the state with the new category
      final currentCategories = state.value ?? [];
      final updatedCategories = [...currentCategories, addedCategory];
      updatedCategories.sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updatedCategories);
      
      return addedCategory;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final updatedCategory = await _categoryService.updateCategory(category);
      
      // Update the state
      final currentCategories = state.value ?? [];
      final updatedCategories = currentCategories.map((c) {
        return c.id == category.id ? updatedCategory : c;
      }).toList();
      updatedCategories.sort((a, b) => a.name.compareTo(b.name));
      state = AsyncValue.data(updatedCategories);
      
      return updatedCategory;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoryService.deleteCategory(categoryId);
      
      // Update the state
      final currentCategories = state.value ?? [];
      final updatedCategories = currentCategories.where((c) => c.id != categoryId).toList();
      state = AsyncValue.data(updatedCategories);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    final userId = _ref.read(currentUserIdProvider);
    return _categoryService.categoryNameExists(name, userId, excludeId: excludeId);
  }

  Future<List<CategoryModel>> searchCategories(String query) async {
    final userId = _ref.read(currentUserIdProvider);
    return _categoryService.searchCategories(query, userId);
  }
}

// Default categories provider
final defaultCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final categoryService = ref.read(categoryServiceProvider);
  return categoryService.getDefaultCategories();
});

// User custom categories provider
final userCustomCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final categoryService = ref.read(categoryServiceProvider);
  return categoryService.getUserCustomCategories(userId);
});

// Category by ID provider
final categoryByIdProvider = FutureProvider.family<CategoryModel?, String>((ref, categoryId) async {
  final categoryService = ref.read(categoryServiceProvider);
  return categoryService.getCategoryById(categoryId);
});

// Expense categories only (excluding income category)
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categories = ref.watch(categoriesProvider);
  if (categories.value == null) return [];
  
  // Filter out income category if it exists
  return categories.value!.where((category) => category.name.toLowerCase() != 'income').toList();
});

// Income categories only
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categories = ref.watch(categoriesProvider);
  if (categories.value == null) return [];
  
  // Find income category or return all if no specific income category
  final incomeCategory = categories.value!.where((category) => category.name.toLowerCase() == 'income').toList();
  return incomeCategory.isNotEmpty ? incomeCategory : categories.value!;
});

// Categories map (id -> category) for quick lookups
final categoriesMapProvider = Provider<Map<String, CategoryModel>>((ref) {
  final categories = ref.watch(categoriesProvider);
  if (categories.value == null) return {};
  
  return {
    for (final category in categories.value!) category.id: category
  };
});

// Category colors provider (for charts)
final categoryColorsProvider = Provider<Map<String, int>>((ref) {
  final categories = ref.watch(categoriesProvider);
  if (categories.value == null) return {};
  
  return {
    for (final category in categories.value!) category.id: category.color
  };
});

// Check if categories are initialized
final categoriesInitializedProvider = Provider<bool>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.value?.isNotEmpty ?? false;
});
