// Writes the bytes the app uploads (lib/utils/upload_jpeg.dart) for a set of
// photos, for the server parity check (run_parity.py --image-dir).
//
//   dart run tool/upload_batch.dart IN_DIR OUT_DIR --only NAMES.csv
//       [--force-reencode]
//
// Default: prepareUploadJpeg (upright JPEG <= 2048 px and <= 15 MB sent
// unchanged). --force-reencode: the old path, always decode + re-encode.
// Writes OUT_DIR/<same name> and OUT_DIR/upload.csv (name, unchanged) and
// prints how many files are byte-identical to the input.
import 'dart:io';
import 'dart:typed_data';

import 'package:gemeye/utils/upload_jpeg.dart';

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main(List<String> args) {
  final i = args.indexOf('--only');
  if (args.length < 2 || i < 0 || i + 1 >= args.length) {
    stderr.writeln('usage: dart run tool/upload_batch.dart IN_DIR OUT_DIR '
        '--only NAMES.csv [--force-reencode]');
    exit(64);
  }
  final only = {
    for (final l in File(args[i + 1]).readAsLinesSync().skip(1))
      if (l.trim().isNotEmpty) l.split(',').first.trim()
  };
  final force = args.contains('--force-reencode');
  final out = Directory(args[1])..createSync(recursive: true);
  final files = Directory(args[0])
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => only.contains(f.uri.pathSegments.last))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final csv = StringBuffer('name,unchanged\n');
  var same = 0;
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final bytes = f.readAsBytesSync();
    final up = force ? reencodeUploadJpeg(bytes) : prepareUploadJpeg(bytes);
    final unchanged = _same(up, bytes);
    if (unchanged) same++;
    File('${out.path}/$name').writeAsBytesSync(up);
    csv.writeln('$name,$unchanged');
  }
  File('${out.path}/upload.csv').writeAsStringSync(csv.toString());
  stdout.writeln('${force ? 'forced re-encode' : 'prepareUploadJpeg'}: '
      '${files.length} images, $same byte-identical to the input');
}
