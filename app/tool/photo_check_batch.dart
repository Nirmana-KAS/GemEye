// Runs the Photo Check decision on a folder of photos (development check).
//
//   dart run tool/photo_check_batch.dart IN_DIR [--test NAMES.csv]
//       [--blur THRESHOLD] [--out RESULT.csv]
//
// IN_DIR is searched recursively. Images listed in --test (first CSV column)
// are reported as "test", the rest as "train". For each image:
//   new: bytes -> prepareUploadJpeg -> blur variance >= THRESHOLD and the
//        tray-relative stone detector finds a stone (lib/utils/photo_check_math.dart)
//   old: bytes -> forced re-encode -> blur and the removed near-white share
//        check (non-white share of the central 70% within 5%-95%, a pixel is
//        white when every channel >= 200), kept here only for comparison.
// THRESHOLD defaults to the server's BLUR_MIN_VARIANCE (backend/app/gates.py).
import 'dart:io';
import 'dart:typed_data';

import 'package:gemeye/utils/photo_check_math.dart';
import 'package:gemeye/utils/upload_jpeg.dart';
import 'package:image/image.dart' as img;

const double kServerBlurMinVariance = 29.474166117400628;

/// The removed Photo Check framing rule (EDIT-130 and earlier).
const int kOldNearWhiteLevel = 200;
const double kOldShareMin = 0.05, kOldShareMax = 0.95;

double oldStoneShare(Uint8List rgb, int w, int h) {
  final sx0 = (w * 0.15).floor(), sx1 = (w * 0.85).ceil();
  final sy0 = (h * 0.15).floor(), sy1 = (h * 0.85).ceil();
  var stone = 0, total = 0;
  for (var y = sy0; y < sy1; y++) {
    for (var x = sx0; x < sx1; x++) {
      final i = (y * w + x) * 3;
      final white = rgb[i] >= kOldNearWhiteLevel &&
          rgb[i + 1] >= kOldNearWhiteLevel &&
          rgb[i + 2] >= kOldNearWhiteLevel;
      if (!white) stone++;
      total++;
    }
  }
  return total == 0 ? 0.0 : stone / total;
}

String? _opt(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

void main(List<String> args) {
  if (args.isEmpty || args.first.startsWith('--')) {
    stderr.writeln('usage: dart run tool/photo_check_batch.dart IN_DIR '
        '[--test NAMES.csv] [--blur THRESHOLD] [--out RESULT.csv]');
    exit(64);
  }
  final testPath = _opt(args, '--test');
  final test = testPath == null
      ? <String>{}
      : {
          for (final l in File(testPath).readAsLinesSync().skip(1))
            if (l.trim().isNotEmpty) l.split(',').first.trim()
        };
  final blurT =
      double.parse(_opt(args, '--blur') ?? '$kServerBlurMinVariance');
  final files = Directory(args.first)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => RegExp(r'\.(jpe?g|png)$', caseSensitive: false)
          .hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final csv = StringBuffer('name,set,unchanged_upload,blur_new,stone_found,'
      'pass_new,blur_old,stone_share_old,pass_old\n');
  final counts = <String, Map<String, int>>{};
  final fails = <String>[];
  final shares = <double>[];
  void inc(String set, String key) {
    final m = counts.putIfAbsent(set, () => <String, int>{});
    m[key] = (m[key] ?? 0) + 1;
  }

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final set = test.contains(name) ? 'test' : 'train';
    final bytes = f.readAsBytesSync();
    final up = prepareUploadJpeg(bytes);
    final m = measurePhotoCheck(up);
    final sharpNew = m.blurVariance >= blurT;
    final passNew = sharpNew && m.stoneFound;

    final old = img.decodeJpg(reencodeUploadJpeg(bytes))!;
    final rgb = old
        .convert(format: img.Format.uint8, numChannels: 3)
        .getBytes(order: img.ChannelOrder.rgb);
    final blurOld = blurVariance(rgb, old.width, old.height);
    final share = oldStoneShare(rgb, old.width, old.height);
    shares.add(share);
    final sharpOld = blurOld >= blurT;
    final frameOld = share >= kOldShareMin && share <= kOldShareMax;

    inc(set, 'n');
    if (identical(up, bytes)) inc(set, 'unchanged');
    if (!sharpNew) inc(set, 'new_blur_fail');
    if (!m.stoneFound) inc(set, 'new_framing_fail');
    if (!passNew) inc(set, 'new_reject');
    if (!sharpOld) inc(set, 'old_blur_fail');
    if (!frameOld) inc(set, 'old_framing_fail');
    if (!(sharpOld && frameOld)) inc(set, 'old_reject');
    if (!passNew) {
      fails.add('$name ($set): blur ${m.blurVariance.toStringAsFixed(2)}, '
          'stone ${m.stoneFound ? 'found' : 'not found'}');
    }
    csv.writeln('$name,$set,${identical(up, bytes)},'
        '${m.blurVariance.toStringAsFixed(3)},${m.stoneFound},$passNew,'
        '${blurOld.toStringAsFixed(3)},${share.toStringAsFixed(4)},'
        '${sharpOld && frameOld}');
  }
  final out = _opt(args, '--out');
  if (out != null) File(out).writeAsStringSync(csv.toString());

  shares.sort();
  String q(double p) =>
      shares[((shares.length - 1) * p).round()].toStringAsFixed(3);
  stdout.writeln('blur threshold $blurT');
  for (final e in counts.entries) {
    stdout.writeln('${e.key}: ${e.value}');
  }
  stdout.writeln('old stone share: min ${q(0)}, p1 ${q(0.01)}, '
      'median ${q(0.5)}, p99 ${q(0.99)}, max ${q(1)}');
  stdout.writeln('new rejections (${fails.length}):');
  for (final l in fails) {
    stdout.writeln('  $l');
  }
}
