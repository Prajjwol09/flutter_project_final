import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 4)
class GoalModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final double targetAmount;

  @HiveField(5)
  final double currentAmount;

  @HiveField(6)
  final DateTime startDate;

  @HiveField(7)
  final DateTime targetDate;

  @HiveField(8)
  final GoalCategory category;

  @HiveField(9)
  final GoalType type;

  @HiveField(10)
  final bool isCompleted;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  @HiveField(14)
  final String? imageUrl;

  @HiveField(15)
  final Map<String, dynamic>? metadata;

  @HiveField(16)
  final List<GoalMilestone> milestones;

  @HiveField(17)
  final double? monthlyContribution;

  @HiveField(18)
  final String currency;

  @HiveField(19)
  final int priority; // 1-5, 5 being highest

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    required this.category,
    required this.type,
    this.isCompleted = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.metadata,
    this.milestones = const [],
    this.monthlyContribution,
    this.currency = 'NPR',
    this.priority = 3,
  });

  // Calculated properties
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, targetAmount);

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  int get totalDays => targetDate.difference(startDate).inDays;

  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  bool get isOnTrack {
    final expectedProgress = (DateTime.now().difference(startDate).inDays / totalDays) * 100;
    return progressPercentage >= expectedProgress * 0.9; // 90% of expected progress
  }

  double get requiredMonthlySavings {
    final remainingMonths = (targetDate.difference(DateTime.now()).inDays / 30.44).ceil();
    if (remainingMonths <= 0) return remainingAmount;
    return remainingAmount / remainingMonths;
  }

  // JSON serialization
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      category: GoalCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GoalCategory.other,
      ),
      type: GoalType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GoalType.savings,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((m) => GoalMilestone.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyContribution: (json['monthlyContribution'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'NPR',
      priority: json['priority'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'category': category.name,
      'type': type.name,
      'isCompleted': isCompleted,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'metadata': metadata,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'monthlyContribution': monthlyContribution,
      'currency': currency,
      'priority': priority,
    };
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    GoalCategory? category,
    GoalType? type,
    bool? isCompleted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    List<GoalMilestone>? milestones,
    double? monthlyContribution,
    String? currency,
    int? priority,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      milestones: milestones ?? this.milestones,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      currency: currency ?? this.currency,
      priority: priority ?? this.priority,
    );
  }
}

@HiveType(typeId: 5)
class GoalMilestone extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double targetAmount;

  @HiveField(4)
  final DateTime targetDate;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final DateTime createdAt;

  GoalMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.targetDate,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  GoalMilestone copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@HiveType(typeId: 13)
enum GoalCategory {
  @HiveField(0)
  emergency,
  @HiveField(1)
  travel,
  @HiveField(2)
  house,
  @HiveField(3)
  car,
  @HiveField(4)
  education,
  @HiveField(5)
  investment,
  @HiveField(6)
  retirement,
  @HiveField(7)
  wedding,
  @HiveField(8)
  health,
  @HiveField(9)
  business,
  @HiveField(10)
  gadgets,
  @HiveField(11)
  vacation,
  @HiveField(12)
  other,
}

@HiveType(typeId: 14)
enum GoalType {
  @HiveField(0)
  savings,
  @HiveField(1)
  debtPayoff,
  @HiveField(2)
  investment,
  @HiveField(3)
  purchase,
  @HiveField(4)
  emergency,
}