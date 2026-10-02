import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/app_buttons.dart';
import '../widgets/card_container.dart';
import 'main_shell.dart';

/// Four-slide introduction shown after every successful sign-in, then
/// MainShell. In [replay] mode (from Settings or the drawer) Skip and
/// Get Started just return to the previous screen.
class OnboardingScreen extends StatefulWidget {
  final bool replay;

  const OnboardingScreen({super.key, this.replay = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_SlideText> _slides = [
    _SlideText(
      'Grade blue sapphires objectively',
      'Classify 1–5 mm blue sapphires into the 7 GEMCLOUD colour grades using your phone.',
    ),
    _SlideText(
      'What you need',
      'Set up this kit before your first grading session.',
    ),
    _SlideText(
      'Calibrate once per session',
      'Photograph the 6 card patches one by one. GemEye corrects your phone’s colours.',
    ),
    _SlideText(
      'A full colour report',
      'Grade, confidence, all colour values and a PDF certificate. Borderline stones are flagged for a gemologist’s review.',
    ),
  ];

  bool get _isLast => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.replay) {
      Navigator.of(context).pop();
    } else {
      AppRoutes.pushReplacement(context, const MainShell());
    }
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkIcons,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child:
                            TextLinkButton(label: 'Skip', onPressed: _finish),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => _SlidePage(
                    text: _slides[index],
                    visual: switch (index) {
                      0 => const _GradeRingVisual(),
                      1 => const _KitVisual(),
                      2 => const _CalibrationVisual(),
                      _ => const _ReportVisual(),
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                    AppSpacing.xl, AppSpacing.screen, AppSpacing.huge),
                child: Column(
                  children: [
                    _buildDots(),
                    const SizedBox(height: AppSpacing.xxxl),
                    PrimaryButton(
                      label: _isLast ? 'Get Started' : 'Next',
                      trailingIcon: _isLast
                          ? Icons.arrow_forward_rounded
                          : Icons.chevron_right_rounded,
                      onPressed:
                          _isLast ? _finish : () => _goTo(_currentPage + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _slides.length; i++)
          Semantics(
            button: true,
            label: 'Go to slide ${i + 1}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _goTo(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 3, vertical: AppSpacing.lg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SlideText {
  final String title;
  final String description;

  const _SlideText(this.title, this.description);
}

class _SlidePage extends StatelessWidget {
  final _SlideText text;
  final Widget visual;

  const _SlidePage({required this.text, required this.visual});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
      child: Column(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: 320, child: visual),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          Text(
            text.title,
            textAlign: TextAlign.center,
            style: AppText.screenTitle,
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              text.description,
              textAlign: TextAlign.center,
              style: AppText.body14
                  .copyWith(height: 1.55, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 1: the 7 GEMCLOUD grades around a sapphire
// -----------------------------------------------------------------------------

class _GradeRingVisual extends StatelessWidget {
  const _GradeRingVisual();

  @override
  Widget build(BuildContext context) {
    const size = 264.0;
    const centre = size / 2;
    const orbit = 112.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 32,
                top: 32,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _DashedCirclePainter(),
                ),
              ),
              Positioned(
                left: 76,
                top: 76,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.diamond_rounded,
                      size: 64, color: AppColors.primary),
                ),
              ),
              for (var k = 0; k < AppColors.grades.length; k++)
                Builder(builder: (context) {
                  final angle = -math.pi / 2 + k * 2 * math.pi / 7;
                  return Positioned(
                    left: centre + orbit * math.cos(angle) - 23,
                    top: centre + orbit * math.sin(angle) - 30,
                    child: Column(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.grades[k],
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border:
                                  Border.all(color: AppColors.swatchOutline),
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'G${k + 1}',
                          style: AppText.titleSmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final radius = size.width / 2;
    final centre = Offset(radius, radius);
    const dashes = 72;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), i * sweep,
          sweep * 0.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Slide 2: grading kit checklist
// -----------------------------------------------------------------------------

class _KitVisual extends StatelessWidget {
  const _KitVisual();

  static const List<(IconData, String)> _items = [
    (Icons.center_focus_strong_rounded, '100 mm macro lens'),
    (Icons.filter_tilt_shift_rounded, 'CPL filter'),
    (Icons.photo_camera_rounded, 'Tripod'),
    (Icons.crop_square_rounded, 'White gem tray'),
    (Icons.palette_rounded, 'GemEye calibration card'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (icon, label) in _items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: CardContainer(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: Row(
                children: [
                  _IconTile(icon: icon),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: Text(label, style: AppText.body14Medium)),
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const _IconTile({required this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: size * 0.55, color: AppColors.primary),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 3: calibration card with 6 patches
// -----------------------------------------------------------------------------

class _CalibrationVisual extends StatelessWidget {
  const _CalibrationVisual();

  static const List<(String, Color)> _patches = [
    ('White', AppColors.patchWhite),
    ('Black', AppColors.patchBlack),
    ('18% Grey', AppColors.patchGrey18),
    ('50% Grey', AppColors.patchGrey50),
    ('Blue', AppColors.patchBlue),
    ('Red', AppColors.patchRed),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CardContainer(
          radius: AppRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text('GemEye calibration card',
                        style: AppText.titleSmall),
                  ),
                  Text('6 patches', style: AppText.caption),
                ],
              ),
              const SizedBox(height: 14),
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    for (var col = 0; col < 3; col++) ...[
                      if (col > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _Patch(
                          number: row * 3 + col + 1,
                          name: _patches[row * 3 + col].$1,
                          color: _patches[row * 3 + col].$2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text('One photo per patch, in order',
                style: AppText.label.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _Patch extends StatelessWidget {
  final int number;
  final String name;
  final Color color;

  const _Patch({required this.number, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.all(AppSpacing.sm),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$number',
              style: AppText.titleSmall
                  .copyWith(fontSize: 10, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name,
            style: AppText.caption.copyWith(
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 4: sample grade report
// -----------------------------------------------------------------------------

class _ReportVisual extends StatelessWidget {
  const _ReportVisual();

  static const List<(String, String, double)> _values = [
    ('L*', '24.81', 0.25),
    ('C*', '41.36', 0.52),
    ('h°', '268.4', 0.68),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGradeCard(),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var i = 0; i < _values.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildValueTile(_values[i])),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        CardContainer(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              const _IconTile(icon: Icons.picture_as_pdf_rounded, size: 36),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PDF certificate',
                        style: AppText.titleSmall.copyWith(fontSize: 12)),
                    Text('GE-202610-00042',
                        style: AppText.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.download_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CardContainer(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.warningTint,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  'Borderline · flagged for gemologist review',
                  style: AppText.label
                      .copyWith(color: AppColors.textPrimary, height: 1.35),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.grade3,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.onPrimarySubtle),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GEMCLOUD GRADE',
                        style: AppText.titleSmall.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: AppColors.grade7,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Grade 3',
                        style: AppText.display.copyWith(
                            fontSize: 30,
                            height: 1.05,
                            color: AppColors.onPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Vivid — Royal Blue',
                        style:
                            AppText.label.copyWith(color: AppColors.onPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md + AppSpacing.xs),
                      Row(
                        children: [
                          _pill(const Text('± 0.22 grade'), bordered: true),
                          const SizedBox(width: AppSpacing.sm),
                          _pill(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Text('High · 94%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimaryRing,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grade3,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(Widget child, {bool bordered = false}) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onPrimaryFaint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: bordered ? Border.all(color: AppColors.onPrimaryLine) : null,
      ),
      child: DefaultTextStyle(
        style: AppText.titleSmall
            .copyWith(fontSize: 11, color: AppColors.onPrimary),
        child: child,
      ),
    );
  }

  Widget _buildValueTile((String, String, double) value) {
    final (label, number, fraction) = value;
    return CardContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label.copyWith(fontSize: 11)),
          const SizedBox(height: AppSpacing.sm),
          Text(number, style: AppText.monoValue),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}
