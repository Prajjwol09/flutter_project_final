import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../services/goal_service.dart';
import 'auth_provider.dart';

// Goal service provider
final goalServiceProvider = Provider<GoalService>((ref) => GoalService());

// Goals provider
final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<GoalModel>>>((ref) {
  return GoalsNotifier(ref);
});

class GoalsNotifier extends StateNotifier<AsyncValue<List<GoalModel>>> {
  GoalsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  final Ref _ref;
  GoalService get _goalService => _ref.read(goalServiceProvider);

  Future<void> _loadGoals() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final goals = await _goalService.getGoalsForUser(userId);
      state = AsyncValue.data(goals);
    } catch (error, stack) {
      // Try to load from local storage
      final localGoals = _goalService.getOfflineGoals(userId);
      state = AsyncValue.data(localGoals);
    }
  }

  Future<void> refreshGoals() async {
    await _loadGoals();
  }

  Future<GoalModel> addGoal(GoalModel goal) async {
    try {
      final addedGoal = await _goalService.addGoal(goal);
      
      // Update the state with the new goal
      final currentGoals = state.value ?? [];
      final updatedGoals = [addedGoal, ...currentGoals];
      state = AsyncValue.data(updatedGoals);
      
      return addedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      final updatedGoal = await _goalService.updateGoal(goal);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goal.id ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalService.deleteGoal(goalId);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.where((g) => g.id != goalId).toList();
      state = AsyncValue.data(updatedGoals);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> updateGoalProgress(String goalId, double amount) async {
    try {
      final updatedGoal = await _goalService.updateGoalProgress(goalId, amount);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goalId ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> addProgressToGoal(String goalId, double amount) async {
    try {
      final updatedGoal = await _goalService.addProgressToGoal(goalId, amount);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goalId ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> completeGoal(String goalId) async {
    try {
      final updatedGoal = await _goalService.completeGoal(goalId);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goalId ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> addMilestone(String goalId, GoalMilestone milestone) async {
    try {
      final updatedGoal = await _goalService.addMilestone(goalId, milestone);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goalId ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<GoalModel> completeMilestone(String goalId, String milestoneId) async {
    try {
      final updatedGoal = await _goalService.completeMilestone(goalId, milestoneId);
      
      // Update the state
      final currentGoals = state.value ?? [];
      final updatedGoals = currentGoals.map((g) {
        return g.id == goalId ? updatedGoal : g;
      }).toList();
      state = AsyncValue.data(updatedGoals);
      
      return updatedGoal;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<List<GoalModel>> searchGoals(String query) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return [];
    
    return _goalService.searchGoals(userId, query);
  }
}

// Active goals provider
final activeGoalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final goalService = ref.read(goalServiceProvider);
  return goalService.getActiveGoals(userId);
});

// Completed goals provider
final completedGoalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final goalService = ref.read(goalServiceProvider);
  return goalService.getCompletedGoals(userId);
});

// Overdue goals provider
final overdueGoalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final goalService = ref.read(goalServiceProvider);
  return goalService.getOverdueGoals(userId);
});

// Goal by ID provider
final goalByIdProvider = FutureProvider.family<GoalModel?, String>((ref, goalId) async {
  final goalService = ref.read(goalServiceProvider);
  return goalService.getGoalById(goalId);
});

// Goals by category provider
final goalsByCategoryProvider = FutureProvider.family<List<GoalModel>, GoalCategory>((ref, category) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final goalService = ref.read(goalServiceProvider);
  return goalService.getGoalsByCategory(userId, category);
});

// Goals progress summary provider
final goalsProgressSummaryProvider = FutureProvider<GoalsProgressSummary>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) {
    return GoalsProgressSummary(
      totalGoals: 0,
      activeGoals: 0,
      completedGoals: 0,
      overdueGoals: 0,
      onTrackGoals: 0,
      totalTargetAmount: 0,
      totalCurrentAmount: 0,
      averageProgress: 0,
    );
  }

  final goalService = ref.read(goalServiceProvider);
  return goalService.getGoalsProgressSummary(userId);
});

// Recommended monthly savings provider
final recommendedMonthlySavingsProvider = FutureProvider<double>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return 0.0;

  final goalService = ref.read(goalServiceProvider);
  return goalService.getRecommendedMonthlySavings(userId);
});

// Priority goals provider (top 3 by priority and deadline)
final priorityGoalsProvider = Provider<List<GoalModel>>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.value == null) return [];

  final activeGoals = goals.value!
      .where((goal) => goal.isActive && !goal.isCompleted)
      .toList();

  // Sort by priority (highest first) then by deadline (nearest first)
  activeGoals.sort((a, b) {
    final priorityComparison = b.priority.compareTo(a.priority);
    if (priorityComparison != 0) return priorityComparison;
    return a.targetDate.compareTo(b.targetDate);
  });

  return activeGoals.take(3).toList();
});

// Goals requiring attention provider (overdue or off-track)
final goalsRequiringAttentionProvider = Provider<List<GoalModel>>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.value == null) return [];

  return goals.value!
      .where((goal) => goal.isActive && !goal.isCompleted && (goal.isOverdue || !goal.isOnTrack))
      .toList();
});

// Goals statistics provider
final goalsStatisticsProvider = Provider<GoalsStatistics>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.value == null) {
    return GoalsStatistics(
      totalGoals: 0,
      activeGoals: 0,
      completedGoals: 0,
      overdueGoals: 0,
      onTrackGoals: 0,
      averageProgress: 0,
      totalTargetAmount: 0,
      totalCurrentAmount: 0,
    );
  }

  final allGoals = goals.value!;
  final activeGoals = allGoals.where((goal) => goal.isActive && !goal.isCompleted).toList();
  final completedGoals = allGoals.where((goal) => goal.isCompleted).toList();
  final overdueGoals = allGoals.where((goal) => goal.isOverdue).toList();
  final onTrackGoals = activeGoals.where((goal) => goal.isOnTrack).toList();

  double totalTargetAmount = 0;
  double totalCurrentAmount = 0;
  double totalProgress = 0;

  for (final goal in activeGoals) {
    totalTargetAmount += goal.targetAmount;
    totalCurrentAmount += goal.currentAmount;
    totalProgress += goal.progressPercentage;
  }

  final averageProgress = activeGoals.isNotEmpty ? totalProgress / activeGoals.length : 0.0;

  return GoalsStatistics(
    totalGoals: allGoals.length,
    activeGoals: activeGoals.length,
    completedGoals: completedGoals.length,
    overdueGoals: overdueGoals.length,
    onTrackGoals: onTrackGoals.length,
    averageProgress: averageProgress,
    totalTargetAmount: totalTargetAmount,
    totalCurrentAmount: totalCurrentAmount,
  );
});

class GoalsStatistics {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int overdueGoals;
  final int onTrackGoals;
  final double averageProgress;
  final double totalTargetAmount;
  final double totalCurrentAmount;

  GoalsStatistics({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.overdueGoals,
    required this.onTrackGoals,
    required this.averageProgress,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
  });

  double get completionRate => totalGoals > 0 ? (completedGoals / totalGoals) * 100 : 0.0;
  double get onTrackRate => activeGoals > 0 ? (onTrackGoals / activeGoals) * 100 : 0.0;
  double get progressRate => totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0.0;
}