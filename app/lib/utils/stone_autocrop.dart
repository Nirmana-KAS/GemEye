import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Pure Dart (package:image only, no Flutter imports) so it also runs with
// `dart run tool/autocrop_batch.dart`.
//
// The app uses only the detector (detectStone, via photo_check_math.dart).
// The ratio-based crop (autoCropStone, kTargetStoneRatio) failed the Phase F1
// accuracy check (docs/autocrop_report.md) and is kept for the batch tool only.

/// Longer side of the working copy used for detection.
const int kAutoCropWorkSize = 512;

/// Width of the border ring used to measure the tray colour (share of each side).
const double kTrayRingFraction = 0.08;

/// A pixel belongs to the stone mask when its RGB Euclidean distance from the
/// tray colour is above this value. 40 (first value) let the darker shade band
/// across the middle of the training tray join the stone (median ratio 0.53);
/// 80 gives tight boxes on all 1008 training/validation images (80-100 stable).
const double kStoneDistance = 80;

/// Component centroid must lie in the central 80% of the image.
const double kCentreMargin = 0.10;

/// Allowed component area as a share of the working image.
const double kMinComponentArea = 0.002;
const double kMaxComponentArea = 0.40;

/// Stone diameter / crop side the crop aims for: median of the training and
/// validation images (1008 images in dataset/merged not in the 112 test
/// images, tool/autocrop_batch.dart --stats, docs/autocrop_report.md):
/// n 1008, median 0.3485, p5 0.1979, p95 0.4560, notFound 0.
const double kTargetStoneRatio = 0.3485;

/// Allowed stone diameter / image side: p1 and p99 of the same training and
/// validation images (used by Photo Check and the tooClose check).
const double kMinStoneRatio = 0.1865;
const double kMaxStoneRatio = 0.5090;

/// Server rejects images whose shorter side is below 300 px.
const int kMinCropSide = 300;

/// JPEG quality of the cropped image.
const int kAutoCropJpegQuality = 100;

enum AutoCropStatus { ok, notFound, tooClose, tooSmallImage }

/// Axis-aligned box in source pixels (after orientation).
class StoneBox {
  final int x;
  final int y;
  final int width;
  final int height;

  const StoneBox(this.x, this.y, this.width, this.height);

  int get diameter => math.max(width, height);

  @override
  String toString() => 'StoneBox($x, $y, $width x $height)';
}

class AutoCropResult {
  final AutoCropStatus status;

  /// Square crop (JPEG quality 100); set for ok and tooClose.
  final Uint8List? croppedJpeg;

  /// Stone bounding box in source pixels; null when notFound.
  final StoneBox? stoneBox;

  /// Stone diameter / crop side (or / shorter image side without a crop).
  final double? stoneWidthRatio;

  /// Side of the square crop in source pixels.
  final int? cropSide;

  const AutoCropResult({
    required this.status,
    this.croppedJpeg,
    this.stoneBox,
    this.stoneWidthRatio,
    this.cropSide,
  });

  bool get isOk => status == AutoCropStatus.ok;
}

/// Detection result in source pixels (no crop).
class StoneDetection {
  final StoneBox box;
  final int imageWidth;
  final int imageHeight;

  const StoneDetection(this.box, this.imageWidth, this.imageHeight);

  /// Stone diameter / shorter image side.
  double get widthRatio =>
      box.diameter / math.min(imageWidth, imageHeight);
}

/// Decodes [bytes] and applies the EXIF orientation. Null when unreadable.
img.Image? decodeOriented(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    return decoded == null ? null : img.bakeOrientation(decoded);
  } catch (_) {
    return null;
  }
}

/// Finds the stone in an oriented image; null when no candidate qualifies.
StoneDetection? detectStone(img.Image image) {
  final w = image.width, h = image.height;
  final scale = kAutoCropWorkSize / math.max(w, h);
  final work = scale < 1
      ? img.copyResize(image,
          width: math.max(1, (w * scale).round()),
          height: math.max(1, (h * scale).round()),
          interpolation: img.Interpolation.average)
      : image;
  final ww = work.width, wh = work.height;
  final rgb = work
      .convert(format: img.Format.uint8, numChannels: 3)
      .getBytes(order: img.ChannelOrder.rgb);

  final tray = _trayColour(rgb, ww, wh);
  final mask = Uint8List(ww * wh);
  const t2 = kStoneDistance * kStoneDistance;
  for (var i = 0; i < ww * wh; i++) {
    final dr = rgb[i * 3] - tray[0];
    final dg = rgb[i * 3 + 1] - tray[1];
    final db = rgb[i * 3 + 2] - tray[2];
    if (dr * dr + dg * dg + db * db > t2) mask[i] = 1;
  }
  final opened = _dilate(_erode(mask, ww, wh), ww, wh);

  final comp = _largestCentralComponent(opened, ww, wh);
  if (comp == null) return null;

  // Work pixel [x0, x1) maps to source [x0 * sx, x1 * sx).
  final sx = w / ww, sy = h / wh;
  final x0 = (comp.x0 * sx).floor().clamp(0, w - 1);
  final y0 = (comp.y0 * sy).floor().clamp(0, h - 1);
  final x1 = ((comp.x1 + 1) * sx).ceil().clamp(x0 + 1, w);
  final y1 = ((comp.y1 + 1) * sy).ceil().clamp(y0 + 1, h);
  return StoneDetection(StoneBox(x0, y0, x1 - x0, y1 - y0), w, h);
}

/// Detects the stone and crops a square of side diameter / [targetRatio]
/// around it from the full-resolution oriented image.
AutoCropResult autoCropStone(Uint8List bytes,
    {double targetRatio = kTargetStoneRatio}) {
  final image = decodeOriented(bytes);
  if (image == null) {
    return const AutoCropResult(status: AutoCropStatus.notFound);
  }
  final det = detectStone(image);
  if (det == null) return const AutoCropResult(status: AutoCropStatus.notFound);

  final w = image.width, h = image.height;
  final box = det.box;
  final d = box.diameter;
  final shorter = math.min(w, h);
  var side = (d / targetRatio).round();
  var status = AutoCropStatus.ok;
  if (side > shorter) {
    side = shorter;
    if (d / side > kMaxStoneRatio) status = AutoCropStatus.tooClose;
  }
  if (side < kMinCropSide) {
    return AutoCropResult(
        status: AutoCropStatus.tooSmallImage,
        stoneBox: box,
        stoneWidthRatio: d / side,
        cropSide: side);
  }

  final cx = box.x + box.width / 2, cy = box.y + box.height / 2;
  final left = (cx - side / 2).round().clamp(0, w - side);
  final top = (cy - side / 2).round().clamp(0, h - side);
  final crop =
      img.copyCrop(image, x: left, y: top, width: side, height: side);
  return AutoCropResult(
    status: status,
    croppedJpeg:
        Uint8List.fromList(img.encodeJpg(crop, quality: kAutoCropJpegQuality)),
    stoneBox: box,
    stoneWidthRatio: d / side,
    cropSide: side,
  );
}

/// Stone diameter / shorter side of [bytes] as given (no crop); null when the
/// stone is not found or the image is unreadable.
double? measureStoneRatio(Uint8List bytes) {
  final image = decodeOriented(bytes);
  if (image == null) return null;
  return detectStone(image)?.widthRatio;
}

/// Per-channel median of the outer border ring.
List<int> _trayColour(Uint8List rgb, int w, int h) {
  final bx = math.max(1, (w * kTrayRingFraction).round());
  final by = math.max(1, (h * kTrayRingFraction).round());
  final hist = List.generate(3, (_) => List<int>.filled(256, 0));
  var n = 0;
  for (var y = 0; y < h; y++) {
    final rowRing = y < by || y >= h - by;
    for (var x = 0; x < w; x++) {
      if (!rowRing && x >= bx && x < w - bx) continue;
      final i = (y * w + x) * 3;
      hist[0][rgb[i]]++;
      hist[1][rgb[i + 1]]++;
      hist[2][rgb[i + 2]]++;
      n++;
    }
  }
  return [for (final c in hist) _median(c, n)];
}

int _median(List<int> hist, int n) {
  final half = (n + 1) ~/ 2;
  var acc = 0;
  for (var v = 0; v < 256; v++) {
    acc += hist[v];
    if (acc >= half) return v;
  }
  return 255;
}

/// 3x3 erosion; pixels outside the image count as background.
Uint8List _erode(Uint8List m, int w, int h) {
  final out = Uint8List(w * h);
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      var all = 1;
      for (var dy = -1; dy <= 1 && all == 1; dy++) {
        final row = (y + dy) * w;
        for (var dx = -1; dx <= 1; dx++) {
          if (m[row + x + dx] == 0) {
            all = 0;
            break;
          }
        }
      }
      out[y * w + x] = all;
    }
  }
  return out;
}

/// 3x3 dilation.
Uint8List _dilate(Uint8List m, int w, int h) {
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (m[y * w + x] == 0) continue;
      for (var dy = -1; dy <= 1; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final xx = x + dx;
          if (xx >= 0 && xx < w) out[yy * w + xx] = 1;
        }
      }
    }
  }
  return out;
}

class _Component {
  final int area;
  final int x0, y0, x1, y1;
  const _Component(this.area, this.x0, this.y0, this.x1, this.y1);
}

/// Largest 8-connected component whose centroid lies in the central 80% and
/// whose area is within [kMinComponentArea, kMaxComponentArea].
_Component? _largestCentralComponent(Uint8List m, int w, int h) {
  final seen = Uint8List(w * h);
  final stack = Int32List(w * h);
  final total = w * h;
  _Component? best;
  for (var start = 0; start < total; start++) {
    if (m[start] == 0 || seen[start] == 1) continue;
    var sp = 0;
    stack[sp++] = start;
    seen[start] = 1;
    var area = 0, sumX = 0, sumY = 0;
    var x0 = w, y0 = h, x1 = -1, y1 = -1;
    while (sp > 0) {
      final p = stack[--sp];
      final px = p % w, py = p ~/ w;
      area++;
      sumX += px;
      sumY += py;
      if (px < x0) x0 = px;
      if (px > x1) x1 = px;
      if (py < y0) y0 = py;
      if (py > y1) y1 = py;
      for (var dy = -1; dy <= 1; dy++) {
        final yy = py + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final xx = px + dx;
          if (xx < 0 || xx >= w) continue;
          final q = yy * w + xx;
          if (m[q] == 1 && seen[q] == 0) {
            seen[q] = 1;
            stack[sp++] = q;
          }
        }
      }
    }
    final share = area / total;
    if (share < kMinComponentArea || share > kMaxComponentArea) continue;
    final cx = sumX / area, cy = sumY / area;
    if (cx < w * kCentreMargin ||
        cx > w * (1 - kCentreMargin) ||
        cy < h * kCentreMargin ||
        cy > h * (1 - kCentreMargin)) {
      continue;
    }
    if (best == null || area > best.area) {
      best = _Component(area, x0, y0, x1, y1);
    }
  }
  return best;
}
