import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String currency;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime updatedAt;
  
  @HiveField(6)
  final String? profileImageUrl;
  
  @HiveField(7)
  final double monthlyBudgetTarget;
  
  @HiveField(8)
  final String? phoneNumber;
  
  @HiveField(9)
  final String authProvider; // 'email', 'google', 'phone'

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.currency = 'NPR', // NPR as default currency
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.monthlyBudgetTarget = 0.0,
    this.phoneNumber,
    this.authProvider = 'email',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
      monthlyBudgetTarget: (json['monthlyBudgetTarget'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: json['phoneNumber'] as String?,
      authProvider: json['authProvider'] as String? ?? 'email',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'monthlyBudgetTarget': monthlyBudgetTarget,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
    double? monthlyBudgetTarget,
    String? phoneNumber,
    String? authProvider,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      monthlyBudgetTarget: monthlyBudgetTarget ?? this.monthlyBudgetTarget,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        currency,
        createdAt,
        updatedAt,
        profileImageUrl,
        monthlyBudgetTarget,
        phoneNumber,
        authProvider,
      ];
}
