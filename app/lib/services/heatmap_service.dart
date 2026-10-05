import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// A Grad-CAM heatmap from `POST /gradings/{id}/heatmap`.
class HeatmapImage {
  final Uint8List bytes;
  final String method;
  final int targetGrade;

  /// Share of the total heat inside the stone outline (0-1).
  final double stoneHeatFraction;

  const HeatmapImage({
    required this.bytes,
    required this.method,
    required this.targetGrade,
    required this.stoneHeatFraction,
  });
}

/// Loads the Grad-CAM heatmap of a saved grading. The server computes it
/// once and caches the PNG; the app keeps the bytes in memory for the session.
class HeatmapService {
  HeatmapService._();

  static final Map<String, HeatmapImage> _cache = {};

  static void clearCache() => _cache.clear();

  /// Offline, maintenance and session errors come from [ApiClient] as
  /// [ApiException]s with user-friendly messages (the shared session-lost
  /// handler runs there too).
  static Future<HeatmapImage> fetch(String gradingId,
      {ApiClient? client, http.Client? download}) async {
    final cached = _cache[gradingId];
    if (cached != null) return cached;
    final json = await (client ?? ApiClient.instance)
        .postJson('/gradings/${Uri.encodeComponent(gradingId)}/heatmap', null);
    final url = json['url'] as String?;
    if (url == null) {
      throw const ApiException(ApiErrorCode.serverError,
          'The heatmap could not be loaded. Please try again.');
    }
    final bytes = await _download(Uri.parse(url), download);
    final image = HeatmapImage(
      bytes: bytes,
      method: json['method'] as String? ?? '',
      targetGrade: (json['target_grade'] as num?)?.toInt() ?? 0,
      stoneHeatFraction:
          (json['stone_mask_heat_fraction'] as num?)?.toDouble() ?? 0,
    );
    _cache[gradingId] = image;
    return image;
  }

  static Future<Uint8List> _download(Uri url, http.Client? client) async {
    final c = client ?? http.Client();
    try {
      final r = await c.get(url).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) return r.bodyBytes;
      throw const ApiException(ApiErrorCode.serverError,
          'The heatmap could not be loaded. Please try again.');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(ApiErrorCode.timeout,
          'The server is taking too long. Please try again.');
    } catch (e) {
      if (kDebugMode) debugPrint('Heatmap download failed: $e');
      throw const ApiException(ApiErrorCode.offline,
          'No internet connection. Check your connection and try again.');
    } finally {
      if (client == null) c.close();
    }
  }
}
