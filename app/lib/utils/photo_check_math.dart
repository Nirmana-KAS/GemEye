import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'stone_autocrop.dart';

// Pure Dart (package:image only) so tools can run the Photo Check decision
// with `dart run` (tool/photo_check_batch.dart).

/// Longest side the photo is resized to before the blur check (server value).
const int kPhotoCheckSize = 512;

/// Raw Photo Check measurements of the upload bytes.
class PhotoCheckMeasure {
  final double blurVariance;

  /// A stone component was found by the tray-relative detector
  /// (stone_autocrop.dart detectStone, detection only, no crop).
  final bool stoneFound;

  const PhotoCheckMeasure(this.blurVariance, this.stoneFound);
}

/// Blur variance and stone detection of [uploadBytes] (the exact bytes sent
/// to the server).
PhotoCheckMeasure measurePhotoCheck(Uint8List uploadBytes) {
  final decoded = decodeOriented(uploadBytes);
  if (decoded == null) throw const FormatException('Unreadable image');
  final rgb = decoded
      .convert(format: img.Format.uint8, numChannels: 3)
      .getBytes(order: img.ChannelOrder.rgb);
  return PhotoCheckMeasure(
    blurVariance(rgb, decoded.width, decoded.height),
    detectStone(decoded) != null,
  );
}

// ---------------------------------------------------------------------------
// Blur variance, bit-identical to the server (backend/app/pipeline/inference.py
// blur_variance, OpenCV 4.x):
//   gray = cv2.cvtColor(rgb, COLOR_RGB2GRAY)
//   longer side -> 512 with cv2.resize(INTER_AREA)
//   central 50% crop
//   cv2.Laplacian(ksize=1, CV_64F) = kernel [0,1,0; 1,-4,1; 0,1,0], border
//   BORDER_REFLECT_101 on the crop
//   population variance
// Checked against the server in test/photo_check_test.dart.
// ---------------------------------------------------------------------------

/// Laplacian variance of an interleaved RGB image (uint8), as the server.
double blurVariance(Uint8List rgb, int w, int h) {
  final gray = grayFromRgb(rgb, w, h);
  final s = kPhotoCheckSize / math.max(w, h);
  final dw = math.max(1, (w * s).truncate());
  final dh = math.max(1, (h * s).truncate());
  final g = resizeArea(gray, w, h, dw, dh);
  return laplacianVariance(
      g, dw, dh, dw ~/ 4, dh ~/ 4, 3 * dw ~/ 4, 3 * dh ~/ 4);
}

/// cv2.COLOR_RGB2GRAY for uint8 (15-bit fixed point).
Uint8List grayFromRgb(Uint8List rgb, int w, int h) {
  final out = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    out[i] = (rgb[i * 3] * 9798 +
            rgb[i * 3 + 1] * 19235 +
            rgb[i * 3 + 2] * 3735 +
            (1 << 14)) >>
        15;
  }
  return out;
}

/// cv2.resize(src, (dw, dh), interpolation=INTER_AREA) for one uint8 channel.
Uint8List resizeArea(Uint8List src, int sw, int sh, int dw, int dh) {
  if (dw == sw && dh == sh) return Uint8List.fromList(src);
  final scaleX = sw / dw, scaleY = sh / dh;
  if (scaleX >= 1 && scaleY >= 1) {
    final kx = scaleX.toInt(), ky = scaleY.toInt();
    const eps = 2.220446049250313e-16;
    if ((scaleX - kx).abs() < eps && (scaleY - ky).abs() < eps) {
      return _resizeAreaFast(src, sw, dw, dh, kx, ky);
    }
    return _resizeAreaGeneral(src, sw, sh, dw, dh, scaleX, scaleY);
  }
  return _resizeAreaUp(src, sw, sh, dw, dh);
}

final Float32List _f32 = Float32List(1);

/// Rounds to float32 (the OpenCV area path accumulates in float).
double _f(double v) {
  _f32[0] = v;
  return _f32[0];
}

/// cvRound: round half to even.
int _roundEven(double v) {
  final f = v.floorToDouble();
  final d = v - f;
  final i = f.toInt();
  if (d > 0.5) return i + 1;
  if (d < 0.5) return i;
  return i.isEven ? i : i + 1;
}

int _sat8(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);

/// Integer scale (resizeAreaFast): block sum; 2x2 uses (sum + 2) >> 2, other
/// scales round(sum * (1/area)) in float.
Uint8List _resizeAreaFast(
    Uint8List src, int sw, int dw, int dh, int kx, int ky) {
  final out = Uint8List(dw * dh);
  final area = kx * ky;
  final inv = _f(1.0 / area);
  for (var dy = 0; dy < dh; dy++) {
    for (var dx = 0; dx < dw; dx++) {
      var sum = 0;
      for (var y = dy * ky; y < dy * ky + ky; y++) {
        final row = y * sw;
        for (var x = dx * kx; x < dx * kx + kx; x++) {
          sum += src[row + x];
        }
      }
      out[dy * dw + dx] = kx == 2 && ky == 2
          ? (sum + 2) >> 2
          : _sat8(_roundEven(_f(sum * inv)));
    }
  }
  return out;
}

class _AreaTab {
  final int di;
  final int si;
  final double alpha;
  const _AreaTab(this.di, this.si, this.alpha);
}

/// computeResizeAreaTab (alpha as float).
List<_AreaTab> _areaTab(int ssize, int dsize, double scale) {
  final tab = <_AreaTab>[];
  for (var dx = 0; dx < dsize; dx++) {
    final fsx1 = dx * scale;
    final fsx2 = fsx1 + scale;
    final cell = math.min(scale, ssize - fsx1);
    var sx1 = fsx1.ceil();
    var sx2 = fsx2.floor();
    sx2 = math.min(sx2, ssize - 1);
    sx1 = math.min(sx1, sx2);
    if (sx1 - fsx1 > 1e-3) {
      tab.add(_AreaTab(dx, sx1 - 1, _f((sx1 - fsx1) / cell)));
    }
    for (var sx = sx1; sx < sx2; sx++) {
      tab.add(_AreaTab(dx, sx, _f(1.0 / cell)));
    }
    if (fsx2 - sx2 > 1e-3) {
      tab.add(_AreaTab(
          dx, sx2, _f(math.min(math.min(fsx2 - sx2, 1.0), cell) / cell)));
    }
  }
  return tab;
}

/// Non-integer downscale (ResizeArea_Invoker), float32 accumulation.
Uint8List _resizeAreaGeneral(Uint8List src, int sw, int sh, int dw, int dh,
    double scaleX, double scaleY) {
  final xtab = _areaTab(sw, dw, scaleX);
  final ytab = _areaTab(sh, dh, scaleY);
  final out = Uint8List(dw * dh);
  final buf = Float32List(dw);
  final sum = Float32List(dw);
  var prev = ytab.first.di;
  for (final yt in ytab) {
    buf.fillRange(0, dw, 0);
    final row = yt.si * sw;
    for (final t in xtab) {
      buf[t.di] = buf[t.di] + _f(src[row + t.si] * t.alpha);
    }
    final beta = yt.alpha;
    if (yt.di != prev) {
      for (var dx = 0; dx < dw; dx++) {
        out[prev * dw + dx] = _sat8(_roundEven(sum[dx]));
        sum[dx] = beta * buf[dx];
      }
      prev = yt.di;
    } else {
      for (var dx = 0; dx < dw; dx++) {
        sum[dx] = sum[dx] + _f(beta * buf[dx]);
      }
    }
  }
  for (var dx = 0; dx < dw; dx++) {
    out[prev * dw + dx] = _sat8(_roundEven(sum[dx]));
  }
  return out;
}

/// Linear coefficients of INTER_AREA when enlarging (fixed point, 2048).
({List<int> ofs, List<int> c0, List<int> c1, int max}) _linearAreaCoeffs(
    int ssize, int dsize) {
  final inv = dsize / ssize;
  final scale = 1.0 / inv;
  final ofs = <int>[], c0 = <int>[], c1 = <int>[];
  var xmax = dsize;
  for (var dx = 0; dx < dsize; dx++) {
    var sx = (dx * scale).floor();
    var fx = _f((dx + 1) - (sx + 1) * inv);
    fx = fx <= 0 ? 0.0 : _f(fx - fx.floor());
    if (sx < 0) {
      fx = 0;
      sx = 0;
    }
    if (sx + 1 >= ssize) {
      xmax = math.min(xmax, dx);
      if (sx >= ssize - 1) {
        fx = 0;
        sx = ssize - 1;
      }
    }
    ofs.add(sx);
    c0.add(_roundEven(_f(_f(1 - fx) * 2048)));
    c1.add(_roundEven(_f(fx * 2048)));
  }
  return (ofs: ofs, c0: c0, c1: c1, max: xmax);
}

/// INTER_AREA when either side grows: OpenCV's linear resize with area
/// coefficients; the vertical pass uses its SIMD rounding.
Uint8List _resizeAreaUp(Uint8List src, int sw, int sh, int dw, int dh) {
  final xc = _linearAreaCoeffs(sw, dw);
  final yc = _linearAreaCoeffs(sh, dh);
  final hRows = List<Int32List>.generate(sh, (y) {
    final row = Int32List(dw);
    final base = y * sw;
    for (var dx = 0; dx < dw; dx++) {
      final sx = xc.ofs[dx];
      row[dx] = dx < xc.max
          ? src[base + sx] * xc.c0[dx] + src[base + sx + 1] * xc.c1[dx]
          : src[base + sx] * 2048;
    }
    return row;
  });
  final out = Uint8List(dw * dh);
  for (var dy = 0; dy < dh; dy++) {
    final sy = yc.ofs[dy];
    final r0 = hRows[sy.clamp(0, sh - 1)];
    final r1 = hRows[(sy + 1).clamp(0, sh - 1)];
    final b0 = yc.c0[dy], b1 = yc.c1[dy];
    for (var dx = 0; dx < dw; dx++) {
      final v = (((r0[dx] >> 4) * b0) >> 16) + (((r1[dx] >> 4) * b1) >> 16);
      out[dy * dw + dx] = _sat8((v + 2) >> 2);
    }
  }
  return out;
}

/// Population variance of the 4-neighbour Laplacian of the crop
/// [x0, x1) x [y0, y1), with BORDER_REFLECT_101 at the crop edges.
double laplacianVariance(
    Uint8List g, int w, int h, int x0, int y0, int x1, int y1) {
  final cw = x1 - x0, ch = y1 - y0;
  if (cw <= 0 || ch <= 0) return 0;
  int at(int x, int y) {
    // Reflect-101 inside the crop.
    if (x < 0) x = cw > 1 ? -x : 0;
    if (x >= cw) x = cw > 1 ? 2 * cw - x - 2 : 0;
    if (y < 0) y = ch > 1 ? -y : 0;
    if (y >= ch) y = ch > 1 ? 2 * ch - y - 2 : 0;
    return g[(y0 + y) * w + x0 + x];
  }

  final lap = Float64List(cw * ch);
  var sum = 0.0;
  for (var y = 0; y < ch; y++) {
    for (var x = 0; x < cw; x++) {
      final v = (at(x - 1, y) + at(x + 1, y) + at(x, y - 1) + at(x, y + 1) -
              4 * at(x, y))
          .toDouble();
      lap[y * cw + x] = v;
      sum += v;
    }
  }
  final mean = sum / lap.length;
  var sq = 0.0;
  for (final v in lap) {
    sq += (v - mean) * (v - mean);
  }
  return sq / lap.length;
}
