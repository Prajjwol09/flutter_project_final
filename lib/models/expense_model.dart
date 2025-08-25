import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class ExpenseModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String categoryId;
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final String paymentMethod;
  
  @HiveField(6)
  final DateTime transactionDate;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final String? receiptUrl;
  
  @HiveField(9)
  final ExpenseType type;
  
  @HiveField(10)
  final String? notes;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.transactionDate,
    required this.createdAt,
    this.receiptUrl,
    this.type = ExpenseType.expense,
    this.notes,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      paymentMethod: json['paymentMethod'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      receiptUrl: json['receiptUrl'] as String?,
      type: ExpenseType.values.firstWhere(
        (e) => e.toString() == 'ExpenseType.${json['type']}',
        orElse: () => ExpenseType.expense,
      ),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'receiptUrl': receiptUrl,
      'type': type.toString().split('.').last,
      'notes': notes,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? description,
    String? paymentMethod,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? receiptUrl,
    ExpenseType? type,
    String? notes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        description,
        paymentMethod,
        transactionDate,
        createdAt,
        receiptUrl,
        type,
        notes,
      ];
}
