import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/photo_check_math.dart';
import 'grading_service.dart';
import 'remote_config_service.dart';

export '../utils/photo_check_math.dart';

/// Outcome of the on-device photo checks.
class PhotoCheckResult {
  final double blurVariance;

  /// The tray-relative detector found a stone (no size limit).
  final bool stoneFound;

  /// Blur threshold in use when the photo was checked (server `/config`).
  final double blurThreshold;

  const PhotoCheckResult({
    required this.blurVariance,
    required this.stoneFound,
    required this.blurThreshold,
  });

  bool get isSharp => blurVariance >= blurThreshold;

  bool get stoneInFrame => stoneFound;
}

/// On-device sharpness and framing checks run before grading. They use the
/// photo exactly as it will be uploaded ([prepareUploadJpeg]).
class PhotoCheckService {
  static Future<PhotoCheckResult> analyse(File file) async {
    final bytes = await file.readAsBytes();
    final m = await compute(_analyseBytes, bytes);
    return PhotoCheckResult(
      blurVariance: m.blurVariance,
      stoneFound: m.stoneFound,
      blurThreshold: RemoteConfigService.blurMinVariance,
    );
  }
}

/// Isolate entry: measures the upload bytes.
PhotoCheckMeasure _analyseBytes(Uint8List bytes) =>
    measurePhotoCheck(prepareUploadJpeg(bytes));
