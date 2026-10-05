import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';

class StorageService {
  static const String _historyKey = 'grade_history';
  static const String historyKey = _historyKey;

  static Future<void> saveGradeResult(GradeResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGradeHistory();
    final existingIndex = history.indexWhere((r) => r.id == result.id);
    if (existingIndex >= 0) {
      history[existingIndex] = result;
    } else {
      history.insert(0, result);
    }
    final jsonList = history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  static Future<List<GradeResult>> getGradeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    final results = jsonList
        .map((s) => GradeResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    results.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return results;
  }

  static Future<void> deleteGradeResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGradeHistory();
    history.removeWhere((r) => r.id == id);
    final jsonList = history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Removes all graded stones. With [deletePhotos], their captured photo
  /// files are deleted too (best effort).
  static Future<void> clearHistory({bool deletePhotos = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (deletePhotos) {
      for (final r in await getGradeHistory()) {
        try {
          final f = File(r.capturedImagePath);
          if (await f.exists()) await f.delete();
        } catch (e) {
          if (kDebugMode) debugPrint('Photo delete failed: $e');
        }
      }
    }
    await prefs.remove(_historyKey);
  }

  static Future<GradeResult?> getGradeResultById(String id) async {
    final history = await getGradeHistory();
    try {
      return history.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<int> getGradeCount() async {
    final history = await getGradeHistory();
    return history.length;
  }

  static Future<int> getTodayCount() async {
    final history = await getGradeHistory();
    final now = DateTime.now();
    return history.where((r) =>
        r.capturedAt.year == now.year &&
        r.capturedAt.month == now.month &&
        r.capturedAt.day == now.day).length;
  }
}
