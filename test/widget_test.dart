import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/schedule_item.dart';

void main() {
  group('ScheduleItem Model Tests', () {
    test('ScheduleItem initialization and time range formatting', () {
      final now = DateTime(2026, 10, 27);
      final item = ScheduleItem(
        id: 'test_1',
        userId: 'user_123',
        title: 'Team Standup',
        description: 'Morning sync',
        date: now,
        startHour: 9,
        startMinute: 30,
        endHour: 10,
        endMinute: 0,
        category: 'Meeting',
        priority: SchedulePriority.high,
      );

      expect(item.id, 'test_1');
      expect(item.userId, 'user_123');
      expect(item.title, 'Team Standup');
      expect(item.formattedTimeRange, '9:30 AM - 10:00 AM');
      expect(item.isCompleted, false);
      expect(item.priority, SchedulePriority.high);
    });

    test('ScheduleItem JSON serialization and deserialization', () {
      final now = DateTime(2026, 10, 27);
      final item = ScheduleItem(
        id: 'test_2',
        userId: 'user_456',
        title: 'Review PR',
        description: 'Check pull request',
        date: now,
        startHour: 14,
        startMinute: 15,
        endHour: 15,
        endMinute: 0,
        category: 'Work',
        priority: SchedulePriority.medium,
        isCompleted: true,
      );

      final json = item.toJson();
      final recreated = ScheduleItem.fromJson(json);

      expect(recreated.id, item.id);
      expect(recreated.userId, item.userId);
      expect(recreated.title, item.title);
      expect(recreated.description, item.description);
      expect(recreated.startHour, 14);
      expect(recreated.startMinute, 15);
      expect(recreated.endHour, 15);
      expect(recreated.endMinute, 0);
      expect(recreated.category, 'Work');
      expect(recreated.priority, SchedulePriority.medium);
      expect(recreated.isCompleted, true);
    });

    test('ScheduleItem copyWith toggles isCompleted', () {
      final item = ScheduleItem(
        id: 'test_3',
        userId: 'user_789',
        title: 'Task',
        date: DateTime(2026, 10, 27),
        startHour: 8,
        startMinute: 0,
        endHour: 9,
        endMinute: 0,
        isCompleted: false,
      );

      final updated = item.copyWith(isCompleted: true);
      expect(updated.isCompleted, true);
      expect(item.isCompleted, false);
    });
  });
}
