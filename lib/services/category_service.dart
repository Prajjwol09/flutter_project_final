import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';
import 'local_storage_service.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Initialize default categories
  Future<void> initializeDefaultCategories() async {
    try {
      final List<CategoryModel> defaultCategories = [];

      for (final categoryData in AppConstants.defaultCategories) {
        final category = CategoryModel(
          id: _uuid.v4(),
          name: categoryData['name'] as String,
          icon: categoryData['icon'] as String,
          color: categoryData['color'] as int,
          isDefault: true,
          createdAt: DateTime.now(),
        );
        defaultCategories.add(category);
      }

      // Save to Firestore
      final WriteBatch batch = _firestore.batch();
      for (final category in defaultCategories) {
        batch.set(
          _firestore.collection(AppConstants.categoriesCollection).doc(category.id),
          category.toJson(),
        );
      }
      await batch.commit();

      // Save to local storage
      await LocalStorageService.saveCategories(defaultCategories);
    } catch (e) {
      throw Exception('Failed to initialize default categories: ${e.toString()}');
    }
  }

  // Add custom category
  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      // Save to Firestore
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .set(category.toJson());

      // Save to local storage
      await LocalStorageService.saveCategory(category);

      return category;
    } catch (e) {
      throw Exception('Failed to add category: ${e.toString()}');
    }
  }

  // Update category
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      // Update in Firestore
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .update(category.toJson());

      // Update in local storage
      await LocalStorageService.saveCategory(category);

      return category;
    } catch (e) {
      throw Exception('Failed to update category: ${e.toString()}');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Check if category is default
      final category = await getCategoryById(categoryId);
      if (category?.isDefault == true) {
        throw Exception('Cannot delete default category');
      }

      // Delete from Firestore
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .delete();

      // Delete from local storage
      await LocalStorageService.deleteCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }

  // Get all categories for user
  Future<List<CategoryModel>> getCategoriesForUser(String? userId) async {
    try {
      // Get default categories
      final QuerySnapshot defaultSnapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('isDefault', isEqualTo: true)
          .get();

      final List<CategoryModel> categories = defaultSnapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Get user custom categories if userId is provided
      if (userId != null) {
        final QuerySnapshot userSnapshot = await _firestore
            .collection(AppConstants.categoriesCollection)
            .where('userId', isEqualTo: userId)
            .where('isDefault', isEqualTo: false)
            .get();

        categories.addAll(
          userSnapshot.docs
              .map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
      }

      // Save to local storage
      await LocalStorageService.saveCategories(categories);

      // Sort categories by name
      categories.sort((a, b) => a.name.compareTo(b.name));

      return categories;
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getCategoriesByUserId(userId);
    }
  }

  // Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        final category = CategoryModel.fromJson(doc.data() as Map<String, dynamic>);
        await LocalStorageService.saveCategory(category);
        return category;
      }
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getCategoryById(categoryId);
    }
    return null;
  }

  // Get default categories only
  Future<List<CategoryModel>> getDefaultCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('isDefault', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      // Return local default categories if network fails
      final localCategories = LocalStorageService.getAllCategories();
      return localCategories.where((category) => category.isDefault).toList();
    }
  }

  // Get user custom categories only
  Future<List<CategoryModel>> getUserCustomCategories(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: false)
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      // Return local user categories if network fails
      final localCategories = LocalStorageService.getAllCategories();
      return localCategories
          .where((category) => !category.isDefault && category.userId == userId)
          .toList();
    }
  }

  // Check if category name exists
  Future<bool> categoryNameExists(String name, String? userId, {String? excludeId}) async {
    try {
      final categories = await getCategoriesForUser(userId);
      return categories.any((category) => 
          category.name.toLowerCase() == name.toLowerCase() && 
          category.id != excludeId);
    } catch (e) {
      return false;
    }
  }

  // Search categories
  Future<List<CategoryModel>> searchCategories(String query, String? userId) async {
    try {
      final categories = await getCategoriesForUser(userId);
      return categories
          .where((category) =>
              category.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search categories: ${e.toString()}');
    }
  }

  // Get offline categories
  List<CategoryModel> getOfflineCategories(String? userId) {
    return LocalStorageService.getCategoriesByUserId(userId);
  }

  // Sync local data with Firestore
  Future<void> syncLocalData(String? userId) async {
    try {
      await getCategoriesForUser(userId);
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      throw Exception('Failed to sync categories: ${e.toString()}');
    }
  }
}
