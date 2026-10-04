import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';

class StorageService {
  static const String _historyKey = 'grade_history';
  static const String historyKey = _historyKey;
  static const String _stoneCounterKey = 'stone_counter';
  static const String _demoRemovedKey = 'demo_history_removed_v1';

  /// True after [removeDemoHistory] removed demo results this launch; Home
  /// shows a one-time notice and clears it.
  static bool demoNoticePending = false;

  /// Once per install after the server update: removes the demo results
  /// saved before grading used the server (no server grading id), with
  /// their photos. Returns how many were removed.
  static Future<int> removeDemoHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_demoRemovedKey) ?? false) return 0;
    final history = await getGradeHistory();
    final demo = history.where((r) => r.gradingId == null).toList();
    for (final r in demo) {
      try {
        final f = File(r.capturedImagePath);
        if (await f.exists()) await f.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Demo photo delete failed: $e');
      }
    }
    final kept = history.where((r) => r.gradingId != null).toList();
    await prefs.setStringList(
        _historyKey, kept.map((r) => jsonEncode(r.toJson())).toList());
    await prefs.remove(_stoneCounterKey);
    await prefs.setBool(_demoRemovedKey, true);
    demoNoticePending = demo.isNotEmpty;
    return demo.length;
  }

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
