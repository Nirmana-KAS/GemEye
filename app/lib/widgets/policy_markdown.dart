import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../config/theme.dart';
import 'loading_indicator.dart';

/// Renders assets/data/privacy_policy.md. Shared by the Privacy Agreement
/// and Privacy Policy screens so both always show the same text.
class PolicyMarkdown extends StatefulWidget {
  static const String assetPath = 'assets/data/privacy_policy.md';

  const PolicyMarkdown({super.key});

  @override
  State<PolicyMarkdown> createState() => _PolicyMarkdownState();
}

class _PolicyMarkdownState extends State<PolicyMarkdown> {
  late final Future<String> _policy = _load();

  Future<String> _load() async {
    try {
      return await rootBundle.loadString(PolicyMarkdown.assetPath);
    } catch (e) {
      if (kDebugMode) debugPrint('PolicyMarkdown: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _policy,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.huge),
            child: Center(child: LoadingIndicator(size: 24)),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Unable to load the privacy policy.',
            style: AppText.body14.copyWith(color: AppColors.textSecondary),
          );
        }
        return MarkdownBody(
          data: snapshot.data ?? '',
          styleSheet: MarkdownStyleSheet(
            h1: AppText.sectionHeader,
            h1Padding: EdgeInsets.zero,
            h2: AppText.titleSmall,
            h2Padding: const EdgeInsets.only(top: AppSpacing.xxl),
            p: AppText.body14
                .copyWith(height: 1.55, color: AppColors.textSecondary),
            em: AppText.secondary.copyWith(fontStyle: FontStyle.normal),
            strong: AppText.body14Medium,
            listBullet:
                AppText.body14.copyWith(color: AppColors.textSecondary),
            blockSpacing: AppSpacing.sm,
          ),
        );
      },
    );
  }
}
