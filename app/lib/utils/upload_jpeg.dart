import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Pure Dart (package:image only) so tools can run it with `dart run`.

/// Longest side of the photo sent to the server.
const int kUploadMaxSide = 2048;

/// JPEG quality of the photo sent to the server when it is re-encoded.
const int kUploadJpegQuality = 95;

/// Largest file sent unchanged (server limit, backend config max_upload_mb).
const int kUploadMaxBytes = 15 * 1024 * 1024;

/// True when [bytes] can be uploaded as they are: a JPEG that needs no EXIF
/// rotation (orientation 1 or missing), longer side at most [kUploadMaxSide]
/// and at most [kUploadMaxBytes].
bool canUploadUnchanged(Uint8List bytes) {
  if (bytes.length > kUploadMaxBytes) return false;
  if (bytes.length < 3 ||
      bytes[0] != 0xFF ||
      bytes[1] != 0xD8 ||
      bytes[2] != 0xFF) {
    return false;
  }
  try {
    final info = img.JpegDecoder().startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) return false;
    if (info.width > kUploadMaxSide || info.height > kUploadMaxSide) {
      return false;
    }
    final orientation = img.decodeJpgExif(bytes)?.imageIfd.orientation;
    return orientation == null || orientation == 1;
  } catch (_) {
    return false;
  }
}

/// The bytes sent to `POST /grade`. A JPEG that [canUploadUnchanged] is
/// returned as it is (no decode or re-encode); anything else goes through
/// [reencodeUploadJpeg].
Uint8List prepareUploadJpeg(Uint8List bytes) =>
    canUploadUnchanged(bytes) ? bytes : reencodeUploadJpeg(bytes);

/// Decodes, applies EXIF orientation, downscales so the longer side is at
/// most [kUploadMaxSide] and encodes JPEG [kUploadJpegQuality]. Metadata
/// (including EXIF) is not kept.
Uint8List reencodeUploadJpeg(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unreadable image');
  var image = img.bakeOrientation(decoded);
  final longer = image.width >= image.height ? image.width : image.height;
  if (longer > kUploadMaxSide) {
    image = image.width >= image.height
        ? img.copyResize(image,
            width: kUploadMaxSide, interpolation: img.Interpolation.average)
        : img.copyResize(image,
            height: kUploadMaxSide, interpolation: img.Interpolation.average);
  }
  image.exif = img.ExifData();
  return img.encodeJpg(image, quality: kUploadJpegQuality);
}
