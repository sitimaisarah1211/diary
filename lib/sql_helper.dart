import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SQLHelper {
  static const String _storageKey = 'diary_entries';

  // Create new diary entry
  static Future<int> createDiary(String feeling, String? description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaries = getDiariesFromPrefs(prefs);

      // Generate new ID
      int newId = 1;
      if (diaries.isNotEmpty) {
        newId = (diaries.map((d) => d['id'] as int).reduce((a, b) => a > b ? a : b)) + 1;
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final newDiary = {
        'id': newId,
        'feeling': feeling,
        'description': description ?? '',
        'createdAt': formattedDate,
      };

      diaries.add(newDiary);
      await prefs.setString(_storageKey, jsonEncode(diaries));
      return newId;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating diary: $e');
      rethrow;
    }
  }

  // Read all diaries
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaries = getDiariesFromPrefs(prefs);
      // Sort by ID descending (newest first)
      diaries.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return diaries;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching diaries: $e');
      return [];
    }
  }

  // Helper function to extract diaries from SharedPreferences
  static List<Map<String, dynamic>> getDiariesFromPrefs(SharedPreferences prefs) {
    final jsonString = prefs.getString(_storageKey) ?? '[]';
    try {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing diaries: $e');
      return [];
    }
  }

  // Update an existing diary
  static Future<int> updateDiary(
      int id, String feeling, String? description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaries = getDiariesFromPrefs(prefs);

      final index = diaries.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        diaries[index] = {
          'id': id,
          'feeling': feeling,
          'description': description ?? '',
          'createdAt': formattedDate,
        };

        await prefs.setString(_storageKey, jsonEncode(diaries));
        return 1;
      }
      return 0;
    } catch (e) {
      // ignore: avoid_print
      print('Error updating diary: $e');
      rethrow;
    }
  }

  // Delete a diary by id
  static Future<void> deleteDiary(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaries = getDiariesFromPrefs(prefs);
      diaries.removeWhere((d) => d['id'] == id);
      await prefs.setString(_storageKey, jsonEncode(diaries));
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting diary: $e');
      rethrow;
    }
  }

  // Read a single diary by id
  static Future<List<Map<String, dynamic>>> getDiary(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diaries = getDiariesFromPrefs(prefs);
      return diaries.where((d) => d['id'] == id).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching diary: $e');
      return [];
    }
  }
}