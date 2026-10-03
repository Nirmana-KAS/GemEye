import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';
import 'calibration_service.dart';
import 'notification_service.dart';
import 'profile_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Account-wide data operations: CSV export and wiping local data.
class AccountService {
  AccountService._();

  /// Removes everything GemEye keeps on this device: grading history and
  /// photos, calibration sessions, notifications, profile and preferences.
  // TODO(backend): delete the user's server data (grades, certificates,
  // feedback, S3 images) before the Firebase user is deleted.
  static Future<void> clearLocalData() async {
    await StorageService.clearHistory(deletePhotos: true);
    await CalibrationService.clearAll();
    await NotificationService.clearAll();
    await ProfileService.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('Prefs clear failed: $e');
    }
    await SettingsService.init();
  }

  static String _csvCell(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(RegExp(r'[",\n\r]'))) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// CSV of every graded stone (one row per stone).
  static String buildCsv(List<GradeResult> history) {
    const header = [
      'Stone ID', 'Grade', 'Grade Name', 'Trade Name', 'Confidence (%)',
      'Uncertainty (grade)', 'Referred', 'L*', 'a*', 'b*', 'C*', 'Hue',
      'Saturation (%)', 'Brightness (%)', 'Delta E (dE00)', 'Measured Hex',
      'Certificate No', 'Session ID', 'Captured At',
    ];
    final buffer = StringBuffer()..writeln(header.join(','));
    for (final r in history) {
      buffer.writeln([
        r.stoneId,
        r.gradeNumber,
        r.gradeName,
        r.tradeName,
        r.confidence.toStringAsFixed(1),
        r.uncertaintyRange,
        SettingsService.isReferred(r.confidence) ? 'Yes' : 'No',
        r.labL,
        r.labA,
        r.labB,
        r.labC,
        r.hue,
        r.saturation,
        r.brightness,
        r.deltaE,
        r.measuredHex,
        r.certificateNumber ?? '',
        r.sessionId,
        r.capturedAt.toIso8601String(),
      ].map(_csvCell).join(','));
    }
    return buffer.toString();
  }

  /// Writes the CSV to Downloads/GemEye (Android) or app documents (iOS)
  /// and returns the file. Throws when there is nothing to export.
  static Future<File> exportCsv() async {
    final history = await StorageService.getGradeHistory();
    if (history.isEmpty) throw StateError('empty');
    final Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/GemEye');
    } else {
      dir = Directory('${(await getApplicationDocumentsDirectory()).path}/GemEye');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'gemeye_export_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(buildCsv(history));
    return file;
  }
}
