import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';

/// Send feedback bottom sheet (22c): rating, categories and a comment.
/// Stored locally under 'feedback'.
// TODO(backend): send feedback to the server (MongoDB feedback collection).
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  static const int maxComment = 500;
  static const List<String> categories = [
    'Accuracy',
    'App',
    'Calibration',
    'Other',
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FeedbackSheet(),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  static const List<String> _ratingLabels = [
    'Tap to rate',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  int _rating = 0;
  final Set<String> _categories = {};
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackList = prefs.getStringList('feedback') ?? [];
      feedbackList.add(jsonEncode({
        'rating': _rating,
        'categories': _categories.toList(),
        'comment': _commentController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList('feedback', feedbackList);
    } catch (e) {
      if (kDebugMode) debugPrint('Feedback save failed: $e');
    }
    if (!mounted) return;
    // The app-level messenger shows it on the screen below the sheet.
    AppSnackBar.show(context,
        message: 'Thank you for your feedback', type: AppSnackBarType.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Send feedback', style: AppText.sectionHeader),
              const SizedBox(height: AppSpacing.xs),
              const Text('Help us improve GemEye', style: AppText.secondary),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var n = 1; n <= 5; n++)
                    IconButton(
                      tooltip: '$n star${n == 1 ? '' : 's'}',
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(
                            AppSpacing.touchTarget, AppSpacing.touchTarget),
                      ),
                      onPressed: () => setState(() => _rating = n),
                      icon: Icon(
                        n <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color:
                            n <= _rating ? AppColors.warning : AppColors.border,
                      ),
                    ),
                ],
              ),
              Text(_ratingLabels[_rating],
                  textAlign: TextAlign.center, style: AppText.label),
              const SizedBox(height: AppSpacing.xl),
              const Text('Category', style: AppText.label),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final c in FeedbackSheet.categories) _chip(c),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Comment', style: AppText.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: FeedbackSheet.maxComment,
                style: AppText.body14.copyWith(height: 1.5),
                decoration: const InputDecoration(
                  hintText: "Tell us what worked or what didn't",
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                    '${_commentController.text.length}/${FeedbackSheet.maxComment}',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Send',
                icon: Icons.send_rounded,
                isLoading: _sending,
                onPressed: _rating > 0 ? _send : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final on = _categories.contains(label);
    return Material(
      color: on ? AppColors.primary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: on ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => setState(
            () => on ? _categories.remove(label) : _categories.add(label)),
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: AppSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (on) ...[
                const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.onPrimary),
                const SizedBox(width: AppSpacing.md),
              ],
              Text(label,
                  style: AppText.label.copyWith(
                      color: on ? AppColors.onPrimary : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
