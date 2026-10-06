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
  /// Throws [ApiException] when the server cannot be reached, or when the
  /// certificate was revoked or withdrawn.
  static Future<GradeResult> ensure(GradeResult r, {ApiClient? client}) async {
    final c = client ?? ApiClient.instance;
    final gradingId = r.gradingId;
    if (gradingId == null) {
      throw const ApiException(ApiErrorCode.badRequest,
          'This stone has no server record, so it cannot be certified.');
    }
    var number = r.certificateNumber;
    if (number == null) {
      final issued =
          await c.postJson('/certificates', {'grading_id': gradingId});
      number = issued['cert_no'] as String;
      HistoryService.invalidateCertificates();
    }
    // Owner fields and status come from the stored certificate. The same
    // number and verify URL come back on every export.
    try {
      final json = await c.getJson('/certificates/$number');
      if (json['grading_id'] == gradingId) {
        final status = json['status'];
        if (status == 'revoked') {
          throw const ApiException(ApiErrorCode.conflict,
              'This certificate was revoked, so it cannot be exported again.');
        }
        if (status != 'valid') {
          throw const ApiException(ApiErrorCode.conflict,
              'This certificate is no longer valid, so it cannot be exported.');
        }
        final owner = (json['owner'] as Map?)?.cast<String, dynamic>();
        r.certificateNumber = number;
        r.certificateVerifyUrl = json['verify_url'] as String?;
        r.certificateOwnerName = owner?['display_name'] as String?;
        r.certificateOwnerCompany = owner?['company'] as String?;
        r.applyCertificateSnapshot(
            (json['snapshot'] as Map?)?.cast<String, dynamic>());
      } else {
        // The number belongs to another stone: it was issued on this device
        // before certificates came from the server.
        _offline(r, number);
      }
    } on ApiException catch (e) {
      // No server record: a certificate issued before this update.
      if (e.code != ApiErrorCode.notFound) rethrow;
      _offline(r, number);
    }
    await StorageService.saveGradeResult(r);
    return r;
  }

  static void _offline(GradeResult r, String number) {
    r.certificateNumber = number;
    r.certificateVerifyUrl = null;
    r.certificateOwnerName = null;
    r.certificateOwnerCompany = null;
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
