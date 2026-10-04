import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/grading_response.dart';
import 'api_client.dart';
import 'calibration_service.dart';

/// Longest side of the photo sent to the server.
const int kUploadMaxSide = 2048;

/// JPEG quality of the photo sent to the server.
const int kUploadJpegQuality = 95;

/// Sends a cropped, calibrated photo for grading.
class GradingService {
  /// Grades [image] with `POST /grade`. The photo is re-encoded as JPEG
  /// (EXIF orientation applied, longer side at most 2048 px, quality 95).
  ///
  /// [patches]: the session's 6 measured patch means (0-255, capture order).
  /// [referralThreshold]: 0.40-0.90 (fraction, as the server expects).
  /// [requestId]: pass the same id when the user retries the same photo, so
  /// the server returns the original grading instead of a new one.
  ///
  /// Returns ok or a rejection; throws [ApiException] on any other failure.
  static Future<GradingResponse> gradeStone(
    File image, {
    List<List<double>>? patches,
    String? sessionId,
    double? referralThreshold,
    String? requestId,
    void Function(int sent, int total)? onUploadProgress,
    ApiClient? client,
  }) async {
    final Uint8List jpeg;
    try {
      jpeg = await compute(prepareUploadJpeg, await image.readAsBytes());
    } catch (e) {
      if (kDebugMode) debugPrint('Photo preparation failed: $e');
      throw const ApiException(
          ApiErrorCode.badRequest, 'Could not read this photo. Please retake it.');
    }
    final fields = <String, String>{
      'request_id': requestId ?? const Uuid().v4(),
      'app_version': AppConstants.appVersion,
      'device': await CalibrationService.deviceModel(),
      if (patches != null) 'patches': jsonEncode(patches),
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
      if (referralThreshold != null)
        'referral_threshold': referralThreshold.toStringAsFixed(2),
    };
    final json = await (client ?? ApiClient.instance).postMultipart(
      '/grade',
      fields: fields,
      files: () => [
        http.MultipartFile.fromBytes('image', jpeg, filename: 'stone.jpg'),
      ],
      onProgress: onUploadProgress,
    );
    return GradingResponse.fromJson(json,
        capturedImagePath: image.path, sessionId: sessionId);
  }
}

/// Isolate entry: decodes, applies EXIF orientation, downscales so the
/// longer side is at most [kUploadMaxSide] and encodes JPEG
/// [kUploadJpegQuality]. Metadata (including EXIF) is not kept.
Uint8List prepareUploadJpeg(Uint8List bytes) {
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
