import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../utils/constants.dart';
import 'local_storage_service.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static const String goalsCollection = 'goals';

  // Add goal
  Future<GoalModel> addGoal(GoalModel goal) async {
    try {
      // Save to Firestore
      await _firestore
          .collection(goalsCollection)
          .doc(goal.id)
          .set(goal.toJson());

      // Save to local storage
      await LocalStorageService.saveGoal(goal);

      return goal;
    } catch (e) {
      throw Exception('Failed to add goal: ${e.toString()}');
    }
  }

  // Update goal
  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      // Update in Firestore
      await _firestore
          .collection(goalsCollection)
          .doc(goal.id)
          .update(goal.toJson());

      // Update in local storage
      await LocalStorageService.saveGoal(goal);

      return goal;
    } catch (e) {
      throw Exception('Failed to update goal: ${e.toString()}');
    }
  }

  // Delete goal
  Future<void> deleteGoal(String goalId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection(goalsCollection)
          .doc(goalId)
          .delete();

      // Delete from local storage
      await LocalStorageService.deleteGoal(goalId);
    } catch (e) {
      throw Exception('Failed to delete goal: ${e.toString()}');
    }
  }

  // Get goals for user
  Future<List<GoalModel>> getGoalsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(goalsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: false)
          .get();

      final List<GoalModel> goals = snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Save to local storage
      await LocalStorageService.saveGoals(goals);

      return goals;
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getGoalsByUserId(userId);
    }
  }

  // Get active goals
  Future<List<GoalModel>> getActiveGoals(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(goalsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .orderBy('priority', descending: true)
          .orderBy('targetDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return local active goals if network fails
      final localGoals = LocalStorageService.getGoalsByUserId(userId);
      return localGoals.where((goal) => goal.isActive && !goal.isCompleted).toList();
    }
  }

  // Get completed goals
  Future<List<GoalModel>> getCompletedGoals(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(goalsCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return local completed goals if network fails
      final localGoals = LocalStorageService.getGoalsByUserId(userId);
      return localGoals.where((goal) => goal.isCompleted).toList();
    }
  }

  // Get goal by ID
  Future<GoalModel?> getGoalById(String goalId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(goalsCollection)
          .doc(goalId)
          .get();

      if (doc.exists) {
        final goal = GoalModel.fromJson(doc.data() as Map<String, dynamic>);
        await LocalStorageService.saveGoal(goal);
        return goal;
      }
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getGoalById(goalId);
    }
    return null;
  }

  // Update goal progress
  Future<GoalModel> updateGoalProgress(String goalId, double amount) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final updatedGoal = goal.copyWith(
        currentAmount: amount,
        isCompleted: amount >= goal.targetAmount,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      throw Exception('Failed to update goal progress: ${e.toString()}');
    }
  }

  // Add progress to goal
  Future<GoalModel> addProgressToGoal(String goalId, double amount) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final newAmount = goal.currentAmount + amount;
      return await updateGoalProgress(goalId, newAmount);
    } catch (e) {
      throw Exception('Failed to add progress to goal: ${e.toString()}');
    }
  }

  // Complete goal
  Future<GoalModel> completeGoal(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final updatedGoal = goal.copyWith(
        isCompleted: true,
        currentAmount: goal.targetAmount,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      throw Exception('Failed to complete goal: ${e.toString()}');
    }
  }

  // Get goals by category
  Future<List<GoalModel>> getGoalsByCategory(String userId, GoalCategory category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(goalsCollection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.name)
          .orderBy('priority', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return local goals filtered by category
      final localGoals = LocalStorageService.getGoalsByUserId(userId);
      return localGoals.where((goal) => goal.category == category).toList();
    }
  }

  // Get overdue goals
  Future<List<GoalModel>> getOverdueGoals(String userId) async {
    try {
      final now = DateTime.now();
      final allGoals = await getActiveGoals(userId);
      return allGoals.where((goal) => goal.isOverdue).toList();
    } catch (e) {
      throw Exception('Failed to get overdue goals: ${e.toString()}');
    }
  }

  // Get goals progress summary
  Future<GoalsProgressSummary> getGoalsProgressSummary(String userId) async {
    try {
      final allGoals = await getGoalsForUser(userId);
      final activeGoals = allGoals.where((goal) => goal.isActive && !goal.isCompleted).toList();
      final completedGoals = allGoals.where((goal) => goal.isCompleted).toList();
      final overdueGoals = allGoals.where((goal) => goal.isOverdue).toList();

      double totalTargetAmount = 0;
      double totalCurrentAmount = 0;
      double totalProgress = 0;

      for (final goal in activeGoals) {
        totalTargetAmount += goal.targetAmount;
        totalCurrentAmount += goal.currentAmount;
        totalProgress += goal.progressPercentage;
      }

      final averageProgress = activeGoals.isNotEmpty ? totalProgress / activeGoals.length : 0.0;

      return GoalsProgressSummary(
        totalGoals: allGoals.length,
        activeGoals: activeGoals.length,
        completedGoals: completedGoals.length,
        overdueGoals: overdueGoals.length,
        totalTargetAmount: totalTargetAmount,
        totalCurrentAmount: totalCurrentAmount,
        averageProgress: averageProgress,
        onTrackGoals: activeGoals.where((goal) => goal.isOnTrack).length,
      );
    } catch (e) {
      throw Exception('Failed to get goals progress summary: ${e.toString()}');
    }
  }

  // Add milestone to goal
  Future<GoalModel> addMilestone(String goalId, GoalMilestone milestone) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final updatedMilestones = [...goal.milestones, milestone];
      final updatedGoal = goal.copyWith(
        milestones: updatedMilestones,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      throw Exception('Failed to add milestone: ${e.toString()}');
    }
  }

  // Complete milestone
  Future<GoalModel> completeMilestone(String goalId, String milestoneId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      final updatedMilestones = goal.milestones.map((milestone) {
        if (milestone.id == milestoneId) {
          return milestone.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        }
        return milestone;
      }).toList();

      final updatedGoal = goal.copyWith(
        milestones: updatedMilestones,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      throw Exception('Failed to complete milestone: ${e.toString()}');
    }
  }

  // Get recommended monthly savings
  Future<double> getRecommendedMonthlySavings(String userId) async {
    try {
      final activeGoals = await getActiveGoals(userId);
      double totalRequired = 0;

      for (final goal in activeGoals) {
        totalRequired += goal.requiredMonthlySavings;
      }

      return totalRequired;
    } catch (e) {
      throw Exception('Failed to calculate recommended monthly savings: ${e.toString()}');
    }
  }

  // Sync local data with Firestore
  Future<void> syncLocalData(String userId) async {
    try {
      // Get all goals from Firestore
      await getGoalsForUser(userId);
      
      // Update last sync time
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      throw Exception('Failed to sync goals: ${e.toString()}');
    }
  }

  // Get offline goals
  List<GoalModel> getOfflineGoals(String userId) {
    return LocalStorageService.getGoalsByUserId(userId);
  }

  // Search goals
  Future<List<GoalModel>> searchGoals(String userId, String query) async {
    try {
      final allGoals = await getGoalsForUser(userId);
      return allGoals.where((goal) {
        return goal.title.toLowerCase().contains(query.toLowerCase()) ||
               goal.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search goals: ${e.toString()}');
    }
  }

  // Bulk delete goals
  Future<void> bulkDeleteGoals(List<String> goalIds) async {
    try {
      final WriteBatch batch = _firestore.batch();

      for (final id in goalIds) {
        batch.delete(_firestore.collection(goalsCollection).doc(id));
      }

      await batch.commit();

      // Delete from local storage
      for (final id in goalIds) {
        await LocalStorageService.deleteGoal(id);
      }
    } catch (e) {
      throw Exception('Failed to bulk delete goals: ${e.toString()}');
    }
  }
}

class GoalsProgressSummary {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int overdueGoals;
  final int onTrackGoals;
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double averageProgress;

  GoalsProgressSummary({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.overdueGoals,
    required this.onTrackGoals,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.averageProgress,
  });

  double get completionRate => totalGoals > 0 ? (completedGoals / totalGoals) * 100 : 0.0;
  double get progressRate => totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0.0;
}