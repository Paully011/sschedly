import 'package:flutter/material.dart';

enum SchedulePriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case SchedulePriority.low:
        return 'Low';
      case SchedulePriority.medium:
        return 'Medium';
      case SchedulePriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case SchedulePriority.low:
        return Colors.green;
      case SchedulePriority.medium:
        return Colors.orange;
      case SchedulePriority.high:
        return Colors.redAccent;
    }
  }

  static SchedulePriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return SchedulePriority.high;
      case 'medium':
        return SchedulePriority.medium;
      case 'low':
      default:
        return SchedulePriority.low;
    }
  }
}

class ScheduleItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime date; // Normalized to year, month, day
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String category;
  final SchedulePriority priority;
  final bool isCompleted;

  const ScheduleItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.category = 'General',
    this.priority = SchedulePriority.medium,
    this.isCompleted = false,
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  String formatTimeOfDay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String get formattedTimeRange {
    return '${formatTimeOfDay(startTime)} - ${formatTimeOfDay(endTime)}';
  }

  ScheduleItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? category,
    SchedulePriority? priority,
    bool? isCompleted,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'category': category,
      'priority': priority.displayName,
      'isCompleted': isCompleted,
    };
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final parts = (json['date'] as String).split('-');
      parsedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      parsedDate = DateTime.now();
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    }

    return ScheduleItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      date: parsedDate,
      startHour: json['startHour'] as int? ?? 9,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 10,
      endMinute: json['endMinute'] as int? ?? 0,
      category: json['category'] as String? ?? 'General',
      priority: SchedulePriority.fromString(json['priority'] as String?),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

