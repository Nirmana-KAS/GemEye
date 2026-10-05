import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'app_buttons.dart';

/// File type of a certificate export.
enum CertificateFile { pdf, image }

/// Certificate export button(s) following Settings > Default export format:
/// PDF or Image gives one button, Both gives "Export PDF" and "Export Image".
class ExportButtons extends StatelessWidget {
  final ValueChanged<CertificateFile>? onExport;

  /// The file type being prepared, shown as "Preparing...".
  final CertificateFile? busy;

  const ExportButtons({super.key, required this.onExport, this.busy});

  static List<CertificateFile> filesFor(ExportFormat f) => switch (f) {
        ExportFormat.pdf => const [CertificateFile.pdf],
        ExportFormat.image => const [CertificateFile.image],
        ExportFormat.both => const [CertificateFile.pdf, CertificateFile.image],
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExportFormat>(
      valueListenable: SettingsService.exportFormat,
      builder: (context, format, _) {
        final files = filesFor(format);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < files.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              SecondaryButton(
                label: busy == files[i]
                    ? 'Preparing...'
                    : files[i] == CertificateFile.pdf
                        ? 'Export PDF'
                        : 'Export Image',
                icon: files[i] == CertificateFile.pdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                onPressed: busy != null || onExport == null
                    ? null
                    : () => onExport!(files[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}
