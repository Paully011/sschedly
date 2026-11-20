import 'dart:convert';
import 'package:flutter/material.dart';

// Typedef alias so both 'Product' (assignment rubric) and 'ScheduleTask' are supported
typedef ScheduleTask = Product;

class Product {
  final int id;
  final String title;
  final String category; // 'Work', 'Meeting', 'Study', 'Fitness', 'Personal'
  final String description;
  final String duration; // e.g. '1h 30m'
  final String priority; // 'High', 'Medium', 'Low'
  final double estimatedHours;
  final double price; // Rubric compatibility (estimated hours/points)
  final String image;

  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.duration = '1h 00m',
    this.priority = 'Medium',
    this.estimatedHours = 1.0,
    this.price = 1.0,
    this.image = '',
  });

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.indigo;
      case 'meeting':
        return Colors.blue;
      case 'study':
        return Colors.deepOrange;
      case 'fitness':
        return Colors.green;
      case 'personal':
      default:
        return Colors.purple;
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'meeting':
        return Icons.groups_outlined;
      case 'study':
        return Icons.menu_book_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'personal':
      default:
        return Icons.task_alt_rounded;
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'low':
        return Colors.green;
      case 'medium':
      default:
        return Colors.orange;
    }
  }

  // JSON Object to Product Mapping (20pts)
  factory Product.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final titleVal = json['title'] as String? ??
        json['todo'] as String? ??
        'Scheduled Task';

    final categoryVal =
        json['category'] as String? ?? _inferCategory(titleVal);

    final descVal = json['description'] as String? ??
        'Productivity task item scheduled for $categoryVal category.';

    final durationVal = json['duration'] as String? ?? '1h 00m';
    final priorityVal = json['priority'] as String? ?? 'Medium';

    double hours = 1.0;
    if (json['estimatedHours'] != null) {
      hours = (json['estimatedHours'] is num)
          ? (json['estimatedHours'] as num).toDouble()
          : double.tryParse(json['estimatedHours'].toString()) ?? 1.0;
    } else if (json['price'] != null) {
      hours = (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 1.0;
    }

    return Product(
      id: idVal,
      title: titleVal,
      category: categoryVal,
      description: descVal,
      duration: durationVal,
      priority: priorityVal,
      estimatedHours: hours,
      price: hours,
      image: json['image'] as String? ?? '',
    );
  }

  static String _inferCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('meeting') ||
        lower.contains('sync') ||
        lower.contains('call') ||
        lower.contains('demo') ||
        lower.contains('consult')) {
      return 'Meeting';
    }
    if (lower.contains('study') ||
        lower.contains('learn') ||
        lower.contains('read') ||
        lower.contains('course') ||
        lower.contains('exam')) {
      return 'Study';
    }
    if (lower.contains('gym') ||
        lower.contains('workout') ||
        lower.contains('run') ||
        lower.contains('fitness') ||
        lower.contains('cardio') ||
        lower.contains('hike')) {
      return 'Fitness';
    }
    if (lower.contains('work') ||
        lower.contains('sprint') ||
        lower.contains('project') ||
        lower.contains('code') ||
        lower.contains('review') ||
        lower.contains('report') ||
        lower.contains('budget')) {
      return 'Work';
    }
    return 'Personal';
  }

  Product copyWith({
    int? id,
    String? title,
    String? category,
    String? description,
    String? duration,
    String? priority,
    double? estimatedHours,
    double? price,
    String? image,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      price: price ?? this.price,
      image: image ?? this.image,
    );
  }

  // JSON Array to Product Mapping (20pts)
  static List<Product> fromJsonList(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['todos'] is List) {
      list = decoded['todos'] as List<dynamic>;
    } else if (decoded is Map && decoded['products'] is List) {
      list = decoded['products'] as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'todo': title, // compatibility with dummyjson.com todos API
      'category': category,
      'description': description,
      'duration': duration,
      'priority': priority,
      'estimatedHours': estimatedHours,
      'price': price,
      'image': image,
      'completed': false,
      'userId': 1,
    };
  }
}
