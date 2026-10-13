// Batch auto-crop (lib/utils/stone_autocrop.dart) for development checks.
//
//   dart run tool/autocrop_batch.dart IN_DIR OUT_DIR [--stats]
//       [--only NAMES.csv] [--exclude NAMES.csv]
//
// IN_DIR is searched recursively for .jpg/.jpeg/.png. Without --stats each
// image is auto-cropped to OUT_DIR/<same name> (status ok or tooClose; other
// statuses write nothing) and OUT_DIR/autocrop.csv lists name, status,
// stoneWidthRatio. With --stats nothing is cropped: the stone width ratio of
// the original images (diameter / shorter side) goes to OUT_DIR/stats.csv and
// n, median, p1, p5, p95, p99 and the notFound count are printed.
// --only / --exclude take a CSV whose first column is the image name.
import 'dart:io';
import 'dart:typed_data';

import 'package:gemeye/utils/stone_autocrop.dart';

Set<String> _names(String path) {
  final lines = File(path).readAsLinesSync();
  return {
    for (final l in lines.skip(1))
      if (l.trim().isNotEmpty) l.split(',').first.trim()
  };
}

double _pct(List<double> sorted, double p) {
  // Linear interpolation (numpy default).
  final pos = (sorted.length - 1) * p / 100;
  final lo = pos.floor(), hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

String? _opt(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

void main(List<String> args) {
  final pos = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--only' || args[i] == '--exclude') {
      i++;
    } else if (!args[i].startsWith('--')) {
      pos.add(args[i]);
    }
  }
  if (pos.length != 2) {
    stderr.writeln('usage: dart run tool/autocrop_batch.dart IN_DIR OUT_DIR '
        '[--stats] [--only NAMES.csv] [--exclude NAMES.csv]');
    exit(64);
  }
  final stats = args.contains('--stats');
  final onlyPath = _opt(args, '--only'), excludePath = _opt(args, '--exclude');
  final only = onlyPath == null ? null : _names(onlyPath);
  final exclude = excludePath == null ? <String>{} : _names(excludePath);
  final out = Directory(pos[1])..createSync(recursive: true);

  final files = Directory(pos[0])
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => RegExp(r'\.(jpe?g|png)$', caseSensitive: false)
          .hasMatch(f.path))
      .where((f) {
    final n = f.uri.pathSegments.last;
    return (only == null || only.contains(n)) && !exclude.contains(n);
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final csv = StringBuffer(stats
      ? 'name,status,stoneWidthRatio\n'
      : 'name,status,stoneWidthRatio,cropSide\n');
  final ratios = <double>[];
  final counts = <String, int>{};
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final Uint8List bytes = f.readAsBytesSync();
    if (stats) {
      final r = measureStoneRatio(bytes);
      final status = r == null ? 'notFound' : 'ok';
      counts[status] = (counts[status] ?? 0) + 1;
      if (r != null) ratios.add(r);
      csv.writeln('$name,$status,${r?.toStringAsFixed(4) ?? ''}');
    } else {
      final r = autoCropStone(bytes);
      final status = r.status.name;
      counts[status] = (counts[status] ?? 0) + 1;
      if (r.croppedJpeg != null) {
        File('${out.path}/$name').writeAsBytesSync(r.croppedJpeg!);
      }
      csv.writeln('$name,$status,'
          '${r.stoneWidthRatio?.toStringAsFixed(4) ?? ''},${r.cropSide ?? ''}');
    }
  }
  File('${out.path}/${stats ? 'stats.csv' : 'autocrop.csv'}')
      .writeAsStringSync(csv.toString());

  stdout.writeln('images ${files.length}; status counts $counts');
  if (stats && ratios.isNotEmpty) {
    ratios.sort();
    String f(double v) => v.toStringAsFixed(4);
    stdout.writeln('n ${ratios.length}, median ${f(_pct(ratios, 50))}, '
        'p1 ${f(_pct(ratios, 1))}, p5 ${f(_pct(ratios, 5))}, '
        'p95 ${f(_pct(ratios, 95))}, p99 ${f(_pct(ratios, 99))}, '
        'min ${f(ratios.first)}, max ${f(ratios.last)}, '
        'notFound ${counts['notFound'] ?? 0}');
  }
}
