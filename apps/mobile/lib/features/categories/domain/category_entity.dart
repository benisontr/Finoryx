import 'package:flutter/material.dart';

enum CategoryType {
  income,
  expense;

  static CategoryType fromString(String val) {
    return val.toLowerCase() == 'income' ? CategoryType.income : CategoryType.expense;
  }

  String toApiString() => this == CategoryType.income ? 'income' : 'expense';

  String get displayName => this == CategoryType.income ? 'Income' : 'Expense';
}

class CategoryEntity {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String colorHex;
  final CategoryType type;
  final String? parentId;
  final bool isSystem;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    this.parentId,
    required this.isSystem,
    required this.createdAt,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6366F1);
  }

  IconData get iconData {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'bolt':
        return Icons.bolt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'spa':
        return Icons.spa;
      case 'payments':
        return Icons.payments;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'apartment':
        return Icons.apartment;
      case 'local_cafe':
        return Icons.local_cafe;
      default:
        return Icons.category;
    }
  }

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'],
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      colorHex: json['colorHex'] ?? json['color_hex'] ?? '#6366F1',
      type: CategoryType.fromString(json['type'] ?? 'expense'),
      parentId: json['parentId'] ?? json['parent_id'],
      isSystem: json['isSystem'] ?? json['is_system'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now()),
    );
  }
}
