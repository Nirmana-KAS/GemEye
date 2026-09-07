import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int _selectedStars = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Send Feedback',
            style: TextStyle(
              fontFamily: GemEyeFonts.heading,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GemEyeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate your experience',
            style: TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 14,
              color: GemEyeColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = starNumber),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starNumber <= _selectedStars ? Icons.star : Icons.star_border,
                    size: 40,
                    color: starNumber <= _selectedStars
                        ? const Color(0xFFD97706)
                        : GemEyeColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your thoughts (optional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GemEyeColors.border),
              ),
            ),
            style: const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedStars == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating')),
                  );
                  return;
                }
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final feedbackList = prefs.getStringList('feedback') ?? [];
                  final feedback = {
                    'rating': _selectedStars,
                    'comment': _commentController.text.trim(),
                    'timestamp': DateTime.now().toIso8601String(),
                  };
                  feedbackList.add(jsonEncode(feedback));
                  await prefs.setStringList('feedback', feedbackList);
                } catch (_) {}

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your feedback!')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit Feedback'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
