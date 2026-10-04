import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/grade_result.dart';
import 'api_client.dart';
import 'history_service.dart';
import 'storage_service.dart';

/// Certificates issued by the server (/certificates). The server owns the
/// number (GE-YYYYMM-NNNNN) and the public verification URL.
class CertificateApiService {
  CertificateApiService._();

  /// Makes sure [r] has its server certificate and returns it with
  /// certificateNumber and certificateVerifyUrl set (and saved in the cache).
  ///
  /// First export: POST /certificates. Re-export: GET /certificates/{no}, so
  /// the number and QR never change. A number the server does not know (issued
  /// before certificates came from the server) is kept as an offline
  /// certificate: verify URL stays null.
  ///
  /// Throws [ApiException] when the server cannot be reached.
  static Future<GradeResult> ensure(GradeResult r, {ApiClient? client}) async {
    final c = client ?? ApiClient.instance;
    final gradingId = r.gradingId;
    if (gradingId == null) {
      throw const ApiException(ApiErrorCode.badRequest,
          'This stone has no server record, so it cannot be certified.');
    }
    final existing = r.certificateNumber;
    if (existing != null) {
      try {
        final json = await c.getJson('/certificates/$existing');
        if (json['grading_id'] == gradingId && json['status'] == 'valid') {
          r.certificateVerifyUrl = json['verify_url'] as String?;
        } else {
          r.certificateVerifyUrl = null;
        }
      } on ApiException catch (e) {
        if (e.code != ApiErrorCode.notFound) rethrow;
        r.certificateVerifyUrl = null;
      }
    } else {
      final json = await c.postJson('/certificates', {'grading_id': gradingId});
      r.certificateNumber = json['cert_no'] as String;
      r.certificateVerifyUrl = json['verify_url'] as String?;
      HistoryService.invalidateCertificates();
    }
    await StorageService.saveGradeResult(r);
    return r;
  }

  /// POST /certificates/{no}/pdf. The server keeps the first PDF only; an
  /// already uploaded one (409) is fine. Other failures are logged, not
  /// shown: the PDF on the device is complete either way.
  static Future<void> uploadPdf(String certNo, Uint8List pdf,
      {ApiClient? client}) async {
    try {
      await (client ?? ApiClient.instance).postMultipart(
        '/certificates/$certNo/pdf',
        fields: const {},
        files: () => [
          http.MultipartFile.fromBytes('file', pdf,
              filename: '$certNo.pdf',
              contentType: MediaType('application', 'pdf')),
        ],
      );
    } on ApiException catch (e) {
      if (e.code != ApiErrorCode.conflict && kDebugMode) {
        debugPrint('Certificate PDF upload failed: $e');
      }
    }
  }
}
