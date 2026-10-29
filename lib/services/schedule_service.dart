import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/schedule_item.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  final Map<String, List<ScheduleItem>> _cache = {};

  Future<File> _getFile(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedUserId = userId.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return File('${dir.path}/schedly_schedules_$sanitizedUserId.json');
  }

  Future<List<ScheduleItem>> getSchedules(String userId) async {
    if (_cache.containsKey(userId)) {
      return List<ScheduleItem>.from(_cache[userId]!);
    }

    try {
      final file = await _getFile(userId);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final list = jsonList
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[userId] = list;
        return List<ScheduleItem>.from(list);
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }

    // Default sample schedules for a fresh user
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final sampleList = [
      ScheduleItem(
        id: 'sample_1',
        userId: userId,
        title: 'Project Kickoff Meeting',
        description: 'Discuss architecture and milestones for Schedly with the team',
        date: today,
        startHour: 9,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        category: 'Meeting',
        priority: SchedulePriority.high,
        isCompleted: true,
      ),
      ScheduleItem(
        id: 'sample_2',
        userId: userId,
        title: 'Flutter UI Design Review',
        description: 'Inspect mobile application screens, responsive layout, and transitions',
        date: today,
        startHour: 11,
        startMinute: 30,
        endHour: 12,
        endMinute: 30,
        category: 'Work',
        priority: SchedulePriority.medium,
        isCompleted: false,
      ),
      ScheduleItem(
        id: 'sample_3',
        userId: userId,
        title: 'Gym & Cardio Session',
        description: '45 mins interval training and stretching',
        date: today,
        startHour: 17,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        category: 'Fitness',
        priority: SchedulePriority.low,
        isCompleted: false,
      ),
      ScheduleItem(
        id: 'sample_4',
        userId: userId,
        title: 'Study Cloud & Firebase Auth',
        description: 'Read Firebase Security rules and authentication best practices',
        date: tomorrow,
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 30,
        category: 'Study',
        priority: SchedulePriority.medium,
        isCompleted: false,
      ),
    ];

    _cache[userId] = sampleList;
    await _saveToFile(userId, sampleList);
    return List<ScheduleItem>.from(sampleList);
  }

  Future<void> _saveToFile(String userId, List<ScheduleItem> list) async {
    try {
      final file = await _getFile(userId);
      final jsonString = jsonEncode(list.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving schedules: $e');
    }
  }

  Future<void> addSchedule(ScheduleItem item) async {
    final list = await getSchedules(item.userId);
    list.add(item);
    _cache[item.userId] = list;
    await _saveToFile(item.userId, list);
  }

  Future<void> updateSchedule(ScheduleItem updatedItem) async {
    final list = await getSchedules(updatedItem.userId);
    final index = list.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      list[index] = updatedItem;
      _cache[updatedItem.userId] = list;
      await _saveToFile(updatedItem.userId, list);
    }
  }

  Future<void> deleteSchedule(String id, String userId) async {
    final list = await getSchedules(userId);
    list.removeWhere((item) => item.id == id);
    _cache[userId] = list;
    await _saveToFile(userId, list);
  }

  Future<ScheduleItem?> toggleScheduleCompletion(String id, String userId) async {
    final list = await getSchedules(userId);
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = list[index].copyWith(isCompleted: !list[index].isCompleted);
      list[index] = updated;
      _cache[userId] = list;
      await _saveToFile(userId, list);
      return updated;
    }
    return null;
  }
}

