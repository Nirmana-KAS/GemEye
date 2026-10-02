import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Minimum Laplacian variance of the central 50% (grayscale, 512 px) for a
/// photo to count as sharp.
// TODO: calibrate kMinBlurVariance on the dataset.
const double kMinBlurVariance = 50;

/// Longest side the photo is downscaled to before the checks.
const int kPhotoCheckSize = 512;

/// A pixel is near-white when every channel is at or above this value.
const int kNearWhiteLevel = 200;

/// Allowed share of non-near-white pixels in the central 70%.
const double kStoneShareMin = 0.05;
const double kStoneShareMax = 0.95;

/// Outcome of the on-device photo checks.
class PhotoCheckResult {
  final double blurVariance;
  final double stoneShare;

  const PhotoCheckResult({
    required this.blurVariance,
    required this.stoneShare,
  });

  bool get isSharp => blurVariance >= kMinBlurVariance;

  bool get stoneInFrame =>
      stoneShare >= kStoneShareMin && stoneShare <= kStoneShareMax;
}

/// On-device sharpness and framing checks run before grading.
class PhotoCheckService {
  static Future<PhotoCheckResult> analyse(File file) async {
    final bytes = await file.readAsBytes();
    final r = await compute(_analyseBytes, bytes);
    return PhotoCheckResult(blurVariance: r[0], stoneShare: r[1]);
  }
}

/// Isolate entry: returns [laplacianVariance, stoneShare].
List<double> _analyseBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unreadable image');
  var image = img.bakeOrientation(decoded);
  if (image.width > kPhotoCheckSize || image.height > kPhotoCheckSize) {
    image = image.width >= image.height
        ? img.copyResize(image, width: kPhotoCheckSize)
        : img.copyResize(image, height: kPhotoCheckSize);
  }
  final rgb = image
      .convert(format: img.Format.uint8, numChannels: 3)
      .getBytes(order: img.ChannelOrder.rgb);
  final w = image.width, h = image.height;

  // Sharpness: variance of the 4-neighbour Laplacian over the central 50%.
  final gray = Float64List(w * h);
  for (var i = 0; i < w * h; i++) {
    gray[i] = 0.299 * rgb[i * 3] + 0.587 * rgb[i * 3 + 1] + 0.114 * rgb[i * 3 + 2];
  }
  final x0 = (w ~/ 4).clamp(1, w - 1), x1 = (w * 3 ~/ 4).clamp(1, w - 1);
  final y0 = (h ~/ 4).clamp(1, h - 1), y1 = (h * 3 ~/ 4).clamp(1, h - 1);
  var sum = 0.0, sumSq = 0.0, n = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * w + x;
      final lap = gray[i - 1] + gray[i + 1] + gray[i - w] + gray[i + w] -
          4 * gray[i];
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  final mean = n == 0 ? 0.0 : sum / n;
  final variance = n == 0 ? 0.0 : sumSq / n - mean * mean;

  // Stone in frame: share of non-near-white pixels in the central 70%.
  final sx0 = (w * 0.15).floor(), sx1 = (w * 0.85).ceil();
  final sy0 = (h * 0.15).floor(), sy1 = (h * 0.85).ceil();
  var stone = 0, total = 0;
  for (var y = sy0; y < sy1; y++) {
    for (var x = sx0; x < sx1; x++) {
      final i = (y * w + x) * 3;
      final white = rgb[i] >= kNearWhiteLevel &&
          rgb[i + 1] >= kNearWhiteLevel &&
          rgb[i + 2] >= kNearWhiteLevel;
      if (!white) stone++;
      total++;
    }
  }
  return [variance, total == 0 ? 0.0 : stone / total];
}
