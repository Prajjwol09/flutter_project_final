import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 3)
class BudgetModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String categoryId;
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final BudgetPeriod period;
  
  @HiveField(5)
  final DateTime startDate;
  
  @HiveField(6)
  final DateTime endDate;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final bool isActive;
  
  @HiveField(9)
  final double alertThreshold;
  
  @HiveField(10)
  final bool enableNotifications;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isActive = true,
    this.alertThreshold = 0.8,
    this.enableNotifications = true,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString() == 'BudgetPeriod.${json['period']}',
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'period': period.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'alertThreshold': alertThreshold,
      'enableNotifications': enableNotifications,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    bool? isActive,
    double? alertThreshold,
    bool? enableNotifications,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  // Helper methods
  bool get isCurrentPeriod {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  double get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays.toDouble();
  }

  double get totalDays {
    return endDate.difference(startDate).inDays.toDouble();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        period,
        startDate,
        endDate,
        createdAt,
        isActive,
        alertThreshold,
        enableNotifications,
      ];
}
