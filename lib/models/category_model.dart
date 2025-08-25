import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String icon;
  
  @HiveField(3)
  final int color;
  
  @HiveField(4)
  final bool isDefault;
  
  @HiveField(5)
  final String? userId;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final String type; // 'expense' or 'income'
  
  @HiveField(8)
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    this.userId,
    required this.createdAt,
    this.type = 'expense',
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as int,
      isDefault: json['isDefault'] as bool,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: json['type'] as String? ?? 'expense',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'isActive': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    bool? isDefault,
    String? userId,
    DateTime? createdAt,
    String? type,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        isDefault,
        userId,
        createdAt,
        type,
        isActive,
      ];
}
