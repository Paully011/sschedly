import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;

class BackendService {
  // 10.0.2.2 connects your Android Emulator to localhost:3000 on your PC
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<String> fetchDailyTip() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tip'] ?? 'Stay organized with Schedly!';
      }
    } catch (_) {
      return 'Offline mode: Start Node.js server for live tips.';
    }
    return 'Stay organized with Schedly!';
  }

  static Future<Map<String, dynamic>> processSchedule({
    required String title,
    required String category,
    required DateTime date,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/schedules/process'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'category': category,
              'dateIso': date.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Server validation failed');
      }
    } catch (e) {
      if (e.toString().contains('3 characters') ||
          e.toString().contains('Server validation')) {
        rethrow;
      }
      return {'processedTitle': title.trim(), 'priority': 'Normal'};
    }
  }
}