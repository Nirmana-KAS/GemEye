import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import 'login_screen.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _accepted = false;

  static const List<String> _summaryPoints = [
    'Your data is used only for colour grading analysis within this app.',
    'Your gemstone images are stored securely and never shared with third parties.',
    'You can delete your data at any time from Settings.',
    'We do not sell, transfer, or use your images for any purpose outside this app.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.diamond_rounded,
                  size: 40,
                  color: GemEyeColors.primary,
                ),
                SizedBox(width: 10),
                Text(
                  'GemEye',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Privacy Policy & Terms of Use',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GemEyeColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _summaryPoints
                    .map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: GemEyeColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(
                                    fontFamily: GemEyeFonts.body,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: GemEyeColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: GemEyeColors.border,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FutureBuilder<String>(
                    future:
                        rootBundle.loadString('assets/data/privacy_policy.md'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: GemEyeColors.primary,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'Unable to load privacy policy.',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 13,
                            color: GemEyeColors.textSecondary,
                          ),
                        );
                      }

                      return Text(
                        snapshot.data ?? '',
                        style: const TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: GemEyeColors.textSecondary,
                          height: 1.6,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        activeColor: GemEyeColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _accepted = value ?? false;
                          });
                        },
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _accepted = !_accepted;
                            });
                          },
                          child: const Text(
                            'I have read and agree to the Privacy Policy and Terms of Use',
                            style: TextStyle(
                              fontFamily: GemEyeFonts.body,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: GemEyeColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepted
                          ? () {
                              AppRoutes.pushReplacement(
                                  context, const LoginScreen());
                            }
                          : null,
                      child: const Text(
                        'Accept & Continue',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.heading,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
