import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// One page of GET /gradings.
class HistoryPage {
  final List<GradeResult> items;
  final String? nextCursor;

  const HistoryPage(this.items, this.nextCursor);
}

typedef _CertInfo = ({String certNo, String? verifyUrl});

/// Grading history. The server is the source of truth (/gradings,
/// /certificates); [StorageService] holds a local cache for offline viewing
/// and for the photo files saved on this device.
class HistoryService {
  HistoryService._();

  static const int pageSize = 50;
  static const String _cacheUidKey = 'history_cache_uid';

  /// Bumped whenever the data changed (sync, delete), so open screens reload.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// True when the last [load] could not reach the server (cache shown).
  static bool lastLoadOffline = false;

  /// Query parameters of GET /gradings for the History screen filters.
  static Map<String, String> query({
    String? cursor,
    int limit = pageSize,
    int? grade,
    bool? referred,
    DateTime? from,
    DateTime? to,
  }) =>
      {
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
        if (grade != null) 'grade': '$grade',
        if (referred != null) 'referred': '$referred',
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      };

  static Map<String, _CertInfo>? _certMemo;
  static DateTime _certMemoAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Call after a certificate was issued, so the next page shows it.
  static void invalidateCertificates() => _certMemo = null;

  /// Valid certificates by grading id (GET /certificates), reused for 10 s
  /// so several pages in a row ask once.
  static Future<Map<String, _CertInfo>> _certificates(ApiClient client) async {
    final memo = _certMemo;
    if (memo != null &&
        DateTime.now().difference(_certMemoAt) < const Duration(seconds: 10)) {
      return memo;
    }
    final out = <String, _CertInfo>{};
    String? cursor;
    do {
      final json = await client.getJson('/certificates',
          query: {'limit': '100', if (cursor != null) 'cursor': cursor});
      for (final c in (json['items'] as List? ?? const [])) {
        final m = (c as Map).cast<String, dynamic>();
        if (m['status'] != 'valid') continue;
        out[m['grading_id'] as String] = (
          certNo: m['cert_no'] as String,
          verifyUrl: m['verify_url'] as String?,
        );
      }
      cursor = json['next_cursor'] as String?;
    } while (cursor != null);
    _certMemo = out;
    _certMemoAt = DateTime.now();
    return out;
  }

  /// One server page with the filters applied by the server. Throws
  /// [ApiException] when the server cannot be reached.
  static Future<HistoryPage> fetchPage({
    String? cursor,
    int limit = pageSize,
    int? grade,
    bool? referred,
    DateTime? from,
    DateTime? to,
    ApiClient? client,
  }) async {
    final c = client ?? ApiClient.instance;
    final json = await c.getJson('/gradings',
        query: query(
            cursor: cursor,
            limit: limit,
            grade: grade,
            referred: referred,
            from: from,
            to: to));
    Map<String, _CertInfo> certs = const {};
    try {
      certs = await _certificates(c);
    } on ApiException catch (e) {
      if (kDebugMode) debugPrint('Certificates not loaded: $e');
    }
    final cached = {for (final r in await _cache()) r.id: r};
    final items = <GradeResult>[];
    for (final raw in (json['items'] as List? ?? const [])) {
      final item = (raw as Map).cast<String, dynamic>();
      final id = item['grading_id'] as String;
      final local = cached[id];
      final r = GradeResult.fromGradingItem(item,
          capturedImagePath: local?.capturedImagePath ?? '');
      final cert = certs[id];
      // A number from before the server issued them stays (offline certificate).
      r.certificateNumber = cert?.certNo ?? local?.certificateNumber;
      r.certificateVerifyUrl =
          cert != null ? cert.verifyUrl : local?.certificateVerifyUrl;
      items.add(r);
    }
    await _merge(items);
    return HistoryPage(items, json['next_cursor'] as String?);
  }

  /// Every grading (all pages), written to the cache. Throws [ApiException]
  /// when the server cannot be reached.
  static Future<List<GradeResult>> refresh({ApiClient? client}) async {
    final all = <GradeResult>[];
    String? cursor;
    do {
      final page = await fetchPage(cursor: cursor, client: client);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    await _writeCache(all);
    changes.value++;
    return all;
  }

  /// Server history (refreshing the cache), or the cache when the server
  /// cannot be reached.
  static Future<List<GradeResult>> load({bool forceRefresh = true}) async {
    if (forceRefresh) {
      try {
        final all = await refresh();
        lastLoadOffline = false;
        return all;
      } catch (e) {
        if (kDebugMode) debugPrint('History from cache: $e');
        lastLoadOffline = true;
      }
    }
    return _cache();
  }

  /// What Home shows: the newest [recentCount] stones and every stone graded
  /// today. From the server, or from the cache when it cannot be reached.
  static Future<({List<GradeResult> recent, List<GradeResult> today})>
      homeSummary({int recentCount = 5}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final recent = (await fetchPage(limit: recentCount)).items;
      final today = <GradeResult>[];
      String? cursor;
      do {
        final p = await fetchPage(from: startOfDay, cursor: cursor);
        today.addAll(p.items);
        cursor = p.nextCursor;
      } while (cursor != null);
      lastLoadOffline = false;
      return (recent: recent, today: today);
    } catch (e) {
      if (kDebugMode) debugPrint('Home from cache: $e');
      lastLoadOffline = true;
      return cachedSummary(recentCount: recentCount);
    }
  }

  /// [homeSummary] from the local cache only (instant, works offline).
  static Future<({List<GradeResult> recent, List<GradeResult> today})>
      cachedSummary({int recentCount = 5}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final all = await _cache();
    return (
      recent: all.take(recentCount).toList(),
      today: all.where((r) => !r.capturedAt.isBefore(startOfDay)).toList(),
    );
  }

  /// DELETE /gradings/{id}, then removes it from the cache. A grading the
  /// server no longer has (404) is removed locally too.
  static Future<void> delete(GradeResult r, {ApiClient? client}) async {
    final id = r.gradingId;
    if (id != null) {
      try {
        await (client ?? ApiClient.instance).delete('/gradings/$id');
      } on ApiException catch (e) {
        if (e.code != ApiErrorCode.notFound) rethrow;
      }
    }
    await StorageService.deleteGradeResult(r.id);
    if (r.capturedImagePath.isNotEmpty) {
      try {
        final f = File(r.capturedImagePath);
        if (await f.exists()) await f.delete();
      } catch (e) {
        if (kDebugMode) debugPrint('Photo delete failed: $e');
      }
    }
    changes.value++;
  }

  /// Cached results; the cache of another account is discarded.
  static Future<List<GradeResult>> _cache() async {
    await _checkOwner();
    return StorageService.getGradeHistory();
  }

  static Future<void> _checkOwner() async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return; // Firebase is not initialised (unit tests)
    }
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(_cacheUidKey);
    if (owner != uid) {
      if (owner != null) await StorageService.clearHistory(deletePhotos: true);
      await prefs.setString(_cacheUidKey, uid);
    }
  }

  /// Adds fetched results to the cache (existing entries are replaced).
  static Future<void> _merge(List<GradeResult> items) async {
    for (final r in items) {
      await StorageService.saveGradeResult(r);
    }
  }

  static Future<void> _writeCache(List<GradeResult> all) async {
    await _checkOwner();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(StorageService.historyKey,
        all.map((r) => jsonEncode(r.toJson())).toList());
  }
}
