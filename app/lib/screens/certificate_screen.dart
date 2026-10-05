import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/certificate_api_service.dart';
import '../services/certificate_service.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/export_buttons.dart';
import '../widgets/gem_app_bar.dart';

/// Certificate Preview: scaled A4 page with pinch to zoom, Save to
/// Downloads, Share and (PDF only) Print. [file] picks the exported file:
/// the PDF, or the page as a PNG image.
class CertificateScreen extends StatefulWidget {
  final GradeResult result;
  final Uint8List stoneImageBytes;
  final Uint8List? gradcamImageBytes;
  final CertificateFile file;

  const CertificateScreen({
    super.key,
    required this.result,
    required this.stoneImageBytes,
    this.gradcamImageBytes,
    this.file = CertificateFile.pdf,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Uint8List? _pdfBytes;
  Uint8List? _pagePng;
  bool _isLoading = true;

  bool get _isImage => widget.file == CertificateFile.image;

  String get _fileName =>
      '${widget.result.certificateNumber ?? 'certificate'}.${_isImage ? 'png' : 'pdf'}';

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      final bytes = await CertificateService.generateCertificatePdf(
        result: widget.result,
        stoneImage: widget.stoneImageBytes,
        gradcamImage: widget.gradcamImageBytes,
      );
      final png = await CertificateService.renderPng(bytes);
      final certNo = widget.result.certificateNumber;
      if (certNo != null && widget.result.certificateVerifyUrl != null) {
        unawaited(CertificateApiService.uploadPdf(certNo, bytes));
      }
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _pagePng = png;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Certificate PDF Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context,
            message: 'Failed to generate the certificate',
            type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _savePdf() async {
    final bytes = _isImage ? _pagePng : _pdfBytes;
    if (bytes == null) return;
    try {
      final certNum = widget.result.certificateNumber ?? 'certificate';
      Directory saveDir;

      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download/GemEye Certificates');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        saveDir = Directory('${appDir.path}/GemEye Certificates');
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final file = File('${saveDir.path}/$_fileName');
      await file.writeAsBytes(bytes);
      await NotificationService.add(
        type: AppNotificationType.success,
        title: 'Certificate saved',
        message: '$certNum ${_isImage ? 'image' : 'PDF'} saved to Downloads.',
        action: AppNotificationAction.openHistory,
        category: NotificationCategory.certificate,
      );
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Saved to Downloads',
            type: AppSnackBarType.success,
            actionLabel: 'OK',
            onAction: () {});
      }
    } catch (e) {
      debugPrint('Certificate save failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to save certificate', type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      if (_isImage) {
        final png = _pagePng;
        if (png == null) return;
        await Share.shareXFiles(
            [XFile.fromData(png, mimeType: 'image/png', name: _fileName)],
            fileNameOverrides: [_fileName]);
        return;
      }
      await Printing.sharePdf(bytes: _pdfBytes!, filename: _fileName);
    } catch (e) {
      debugPrint('Certificate share failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to share certificate',
            type: AppSnackBarType.error);
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(
          name: _fileName, onLayout: (_) async => _pdfBytes!);
    } catch (e) {
      debugPrint('Certificate print failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Failed to open print dialog',
            type: AppSnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _pdfBytes != null && (!_isImage || _pagePng != null);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: _isImage ? 'Certificate Image' : 'Certificate',
        leading: GemAppBarLeading.back,
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 14,
                    child: PrimaryButton(
                      label: 'Save to Downloads',
                      icon: Icons.download_rounded,
                      onPressed: ready ? _savePdf : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 10,
                    child: SecondaryButton(
                      label: 'Share',
                      icon: Icons.share_rounded,
                      onPressed: ready ? _sharePdf : null,
                    ),
                  ),
                  if (!_isImage) ...[
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: AppSpacing.controlHeight,
                      height: AppSpacing.controlHeight,
                      child: OutlinedButton(
                        onPressed: ready ? _printPdf : null,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color:
                                  ready ? AppColors.primary : AppColors.border,
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg)),
                        ),
                        child: const Icon(Icons.print_rounded,
                            size: 20, semanticLabel: 'Print'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text('Generating certificate...',
                style: AppText.body14.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    if (_pdfBytes == null) {
      return Center(
        child: Text('Failed to generate the certificate',
            style: AppText.body14.copyWith(color: AppColors.error)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_fileName,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.monoValue
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(_isImage ? 'PNG · A4 page' : 'A4 · 1 page',
                  style: AppText.secondary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // A4 aspect ratio 1 : 1.4142, fitted to the available space.
              const ratio = 841.89 / 595.28;
              var width = constraints.maxWidth;
              if (width * ratio > constraints.maxHeight) {
                width = constraints.maxHeight / ratio;
              }
              return Center(
                child: Container(
                  width: width,
                  height: width * ratio,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: _pagePng != null
                        ? Image.memory(_pagePng!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high)
                        : PdfPreview(
                            build: (_) async => _pdfBytes!,
                            useActions: false,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pinch_rounded,
                  size: 16, color: AppColors.textSecondary),
              SizedBox(width: AppSpacing.xs),
              Text('Pinch to zoom', style: AppText.secondary),
            ],
          ),
        ],
      ),
    );
  }
}
