import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../widgets/gem_app_bar.dart';

/// One GEMCLOUD grade from assets/data/colour_grades.json.
class _GuideGrade {
  final int grade;
  final String name;
  final String tradeName;
  final Color colour;
  final String description;
  final String tone;
  final String saturation;
  final String tip;

  const _GuideGrade({
    required this.grade,
    required this.name,
    required this.tradeName,
    required this.colour,
    required this.description,
    required this.tone,
    required this.saturation,
    required this.tip,
  });

  factory _GuideGrade.fromJson(Map<String, dynamic> json) {
    final grade = json['grade'] as int;
    return _GuideGrade(
      grade: grade,
      name: json['name'] as String,
      tradeName: json['tradeName'] as String,
      // Swatch colours come from the theme so they always match the app.
      colour: AppColors.grades[(grade - 1).clamp(0, 6)],
      description: json['description'] as String,
      tone: json['tone'] as String,
      saturation: json['saturation'] as String,
      tip: json['tip'] as String,
    );
  }
}

class GuideScreen extends StatefulWidget {
  /// Pushed on its own (e.g. from Settings): back arrow instead of menu.
  final bool showBack;

  const GuideScreen({super.key, this.showBack = false});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  List<_GuideGrade> _grades = [];
  bool _failed = false;

  /// Index of the expanded card (-1 = none). G3 is open by default.
  int _open = 2;
  final List<GlobalKey> _cardKeys = List.generate(7, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/colour_grades.json');
      final data = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _grades = data.map(_GuideGrade.fromJson).toList());
    } catch (e) {
      debugPrint('Colour grade guide load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _toggle(int i, {bool reveal = false}) {
    setState(() => _open = _open == i && !reveal ? -1 : i);
    if (!reveal) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[i].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Colour Grade Guide',
        leading:
            widget.showBack ? GemAppBarLeading.back : GemAppBarLeading.menu,
        // The drawer belongs to MainShell's Scaffold, above this one.
        onLeadingPressed: widget.showBack
            ? null
            : () => Scaffold.maybeOf(context)?.openEndDrawer(),
      ),
      body: _failed
          ? Center(
              child: Text('Could not load the colour grade guide',
                  style:
                      AppText.body14.copyWith(color: AppColors.textSecondary)),
            )
          : _grades.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStrip(),
                      const SizedBox(height: AppSpacing.md),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Darkest', style: AppText.caption),
                          Text('Lightest', style: AppText.caption),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (var i = 0; i < _grades.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _buildCard(i),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.offline_pin_rounded,
                                size: 18, color: AppColors.success),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Based on the GEMCLOUD 7-Grade Standard · GRS · '
                                'Bellerophon. Works offline.',
                                style: AppText.secondary.copyWith(height: 1.5),
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

  Widget _buildStrip() {
    return Container(
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _grades.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                label: 'Grade ${_grades[i].grade} · ${_grades[i].name}',
                child: GestureDetector(
                  onTap: () => _toggle(i, reveal: true),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _grades[i].colour,
                      border: _open == i
                          ? Border.all(color: AppColors.onPrimary, width: 2)
                          : null,
                    ),
                    child: Text(
                      'G${_grades[i].grade}',
                      style: AppText.titleSmall.copyWith(
                        fontSize: 11,
                        color:
                            i >= 5 ? AppColors.textPrimary : AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(int i) {
    final g = _grades[i];
    final open = _open == i;
    return AnimatedContainer(
      key: _cardKeys[i],
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: open ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggle(i),
              highlightColor: AppColors.surface,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: g.colour,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.swatchOutline),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grade ${g.grade} · ${g.name}',
                              style: AppText.titleSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(g.tradeName, style: AppText.secondary),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more_rounded,
                          size: 24, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.lg),
                  Text(g.description,
                      style: AppText.body14.copyWith(fontSize: 13, height: 1.5)),
                  const SizedBox(height: AppSpacing.lg),
                  // TODO(dataset): add "Lightness L*" and "Chroma C*" tiles with
                  // the real per-grade median L* and C* from the training set.
                  Row(
                    children: [
                      Expanded(child: _tile('Tone', g.tone)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _tile('Saturation', g.saturation)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(g.tip,
                              style: AppText.label.copyWith(
                                  height: 1.45, color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppText.body14Medium.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
