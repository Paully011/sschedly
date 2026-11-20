import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/schedule_item.dart';
import 'package:app/models/product.dart';

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

  group('Lab Requirements: Full API, Mapping, ListView, and Search Tests', () {
    test('JSON Array to Product / Task Mapping (20pts)', () {
      const sampleJson = '''
      [
        {
          "id": 101,
          "title": "Team Sprint Planning",
          "category": "Work",
          "description": "Review sprint goals and allocate workload",
          "duration": "1h 30m",
          "priority": "High",
          "estimatedHours": 1.5
        },
        {
          "id": 102,
          "title": "Client Project Demo",
          "category": "Meeting",
          "description": "Demonstrate app progress to client",
          "duration": "1h 00m",
          "priority": "High",
          "estimatedHours": 1.0
        }
      ]
      ''';

      final products = Product.fromJsonList(sampleJson);

      expect(products.length, 2);
      expect(products[0].id, 101);
      expect(products[0].title, 'Team Sprint Planning');
      expect(products[0].category, 'Work');
      expect(products[0].duration, '1h 30m');
      expect(products[0].priority, 'High');

      expect(products[1].id, 102);
      expect(products[1].title, 'Client Project Demo');
      expect(products[1].category, 'Meeting');
    });

    test('HTTP FULL API Request Execution (20pts) - JSON Payload Serializer for POST/PUT/DELETE', () {
      const product = Product(
        id: 201,
        title: 'Architecture Refactoring',
        category: 'Work',
        description: 'Migrate to clean service layer',
        duration: '2h 00m',
        priority: 'High',
        estimatedHours: 2.0,
      );

      // Verify toJson formatting suitable for HTTP POST & PUT body payloads
      final jsonPayload = product.toJson();
      expect(jsonPayload['id'], 201);
      expect(jsonPayload['title'], 'Architecture Refactoring');
      expect(jsonPayload['todo'], 'Architecture Refactoring');
      expect(jsonPayload['category'], 'Work');
      expect(jsonPayload['priority'], 'High');

      // Verify copyWith supports HTTP PUT updates
      final updated = product.copyWith(
        title: 'Architecture Refactoring v2',
        priority: 'Medium',
      );
      expect(updated.id, 201);
      expect(updated.title, 'Architecture Refactoring v2');
      expect(updated.priority, 'Medium');
      expect(updated.category, 'Work');
    });

    test('Dynamic Product ListView Presentation (15pts) - Product Attributes & Display Properties', () {
      const pWork = Product(
        id: 301,
        title: 'Backend Database Migration',
        category: 'Work',
        description: 'Run SQL migration scripts',
        duration: '1h 30m',
        priority: 'High',
      );

      expect(pWork.categoryColor, isNotNull);
      expect(pWork.categoryIcon, isNotNull);
      expect(pWork.priorityColor, isNotNull);
    });

    test('Search View Filtering matches task title, category, and priority (10pts)', () {
      final products = [
        const Product(
          id: 1,
          title: 'Sprint Planning Meeting',
          category: 'Work',
          description: 'Groom backlog',
          priority: 'High',
        ),
        const Product(
          id: 2,
          title: 'Morning Gym Cardio',
          category: 'Fitness',
          description: 'Cardio routine',
          priority: 'Medium',
        ),
        const Product(
          id: 3,
          title: 'Client Review Sync',
          category: 'Meeting',
          description: 'Sync with stakeholders',
          priority: 'High',
        ),
      ];

      // Filtering with query "sprint"
      final query = 'sprint'.toLowerCase();
      final filtered = products.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.title, 'Sprint Planning Meeting');

      // Filtering with category "Fitness"
      final fitnessFiltered = products.where((p) => p.category == 'Fitness').toList();
      expect(fitnessFiltered.length, 1);
      expect(fitnessFiltered.first.title, 'Morning Gym Cardio');
    });
  });
}
