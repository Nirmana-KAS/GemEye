import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import '../utils/colour_math.dart';
import '../widgets/app_buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/gem_app_bar.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  GradeResult? _stoneA;
  GradeResult? _stoneB;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime t) =>
      '${t.day} ${_months[t.month - 1]}, '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static Color _gradeColour(int grade) =>
      AppColors.grades[(grade - 1).clamp(0, 6)];

  Future<void> _pickStone(bool isA) async {
    List<GradeResult> history;
    try {
      history = await StorageService.getGradeHistory();
    } catch (e) {
      debugPrint('Comparison history load failed: $e');
      history = [];
    }
    if (!mounted) return;

    final picked = await showModalBottomSheet<GradeResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.card,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _StonePickerSheet(
        title: 'Choose Stone ${isA ? 'A' : 'B'}',
        history: history,
        current: isA ? _stoneA : _stoneB,
        other: isA ? _stoneB : _stoneA,
        otherLabel: isA ? 'Stone B' : 'Stone A',
        subtitle: (r) =>
            'Grade ${r.gradeNumber} · ${r.gradeName} · ${_fmtDate(r.capturedAt)}',
      ),
    );

    if (picked != null) {
      setState(() => isA ? _stoneA = picked : _stoneB = picked);
    }
  }

  void _swap() => setState(() {
        final temp = _stoneA;
        _stoneA = _stoneB;
        _stoneB = temp;
      });

  @override
  Widget build(BuildContext context) {
    final a = _stoneA, b = _stoneB;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(
        title: 'Stone Comparison',
        leading: GemAppBarLeading.back,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _picker(true)),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: a != null || b != null ? _swap : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: a != null || b != null
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded,
                          size: 20, semanticLabel: 'Swap stones'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _picker(false)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (a != null && b != null)
                ..._buildComparison(a, b)
              else
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.compare_rounded,
                    title: 'Select two stones',
                    message:
                        'Choose Stone A and Stone B from your grading history to compare their colour.',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _picker(bool isA) {
    final stone = isA ? _stoneA : _stoneB;
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        highlightColor: AppColors.surface,
        onTap: () => _pickStone(isA),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.xs, AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stone ${isA ? 'A' : 'B'}',
                        style: AppText.label.copyWith(fontSize: 11)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(stone?.stoneId ?? 'Choose',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleSmall.copyWith(
                            fontSize: 11,
                            color: stone == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary)),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildComparison(GradeResult a, GradeResult b) {
    final deltaE = ColourMath.deltaE2000(
      Lab(a.labL, a.labA, a.labB),
      Lab(b.labL, b.labA, b.labB),
    );
    final gradesApart = (a.gradeNumber - b.gradeNumber).abs();

    final (Color colour, Color tint, IconData icon, String verdict) =
        deltaE < 2
            ? (
                AppColors.success,
                AppColors.successTint,
                Icons.check_circle_rounded,
                'Visually very similar'
              )
            : deltaE <= 5
                ? (
                    AppColors.warning,
                    AppColors.warningTint,
                    Icons.info_rounded,
                    'Noticeable difference'
                  )
                : (
                    AppColors.error,
                    AppColors.errorTint,
                    Icons.warning_rounded,
                    'Clearly different'
                  );

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _stoneCard(a, 'A')),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: _stoneCard(b, 'B')),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _card(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: colour),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Colour difference', style: AppText.label),
                      const SizedBox(height: AppSpacing.xs),
                      Text.rich(
                        TextSpan(
                          text: 'ΔE₀₀ = ',
                          children: [
                            TextSpan(
                              text: deltaE.toStringAsFixed(1),
                              style: AppText.monoValue.copyWith(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        style: AppText.sectionHeader.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(verdict, style: AppText.body14Medium.copyWith(color: colour)),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Grade difference',
                      style: AppText.body14.copyWith(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
                Text(
                    '$gradesApart grade${gradesApart == 1 ? '' : 's'} apart',
                    style: AppText.titleSmall),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildTable(a, b),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(
        label: 'Compare another',
        icon: Icons.compare_rounded,
        onPressed: () => _pickStone(false),
      ),
    ];
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) =>
      Container(
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _stoneCard(GradeResult r, String tag) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(r.capturedImagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.diamond_rounded,
                        size: 36, color: AppColors.textMuted),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Text(tag,
                        style: AppText.titleSmall.copyWith(
                            fontSize: 11, color: AppColors.onPrimary)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmtDate(r.capturedAt), style: AppText.caption.copyWith(
                    color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                _GradeChip(
                    gradeNumber: r.gradeNumber,
                    gradeName: r.gradeName,
                    colour: _gradeColour(r.gradeNumber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(GradeResult a, GradeResult b) {
    double hueDiff(double x, double y) {
      final d = (x - y).abs() % 360;
      return d > 180 ? 360 - d : d;
    }

    // (label, sub-label, A, B, difference, decimals)
    final rows = <(String, String, double, double, double, int)>[
      ('L*', 'Lightness', a.labL, b.labL, (a.labL - b.labL).abs(), 1),
      ('a*', 'Green-Red', a.labA, b.labA, (a.labA - b.labA).abs(), 1),
      ('b*', 'Blue-Yellow', a.labB, b.labB, (a.labB - b.labB).abs(), 1),
      ('C*', 'Chroma', a.labC, b.labC, (a.labC - b.labC).abs(), 1),
      ('Hue', '°', a.hue, b.hue, hueDiff(a.hue, b.hue), 0),
      ('Saturation', '%', a.saturation, b.saturation,
          (a.saturation - b.saturation).abs(), 0),
      ('Brightness', '%', a.brightness, b.brightness,
          (a.brightness - b.brightness).abs(), 0),
      // TODO(backend): add J (Lightness, CAM) and M (Colourfulness) rows
      // once GradeResult carries CIECAM02 values.
    ];

    const headerStyle = TextStyle(
      fontFamily: AppText.heading,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    Widget line(List<Widget> cells, {double height = 40, Color? colour}) =>
        Container(
          height: height,
          color: colour,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(flex: 13, child: cells[0]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(flex: 10, child: cells[1]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(flex: 10, child: cells[2]),
              const SizedBox(width: AppSpacing.xs),
              Expanded(flex: 10, child: cells[3]),
            ],
          ),
        );

    return _card(
      child: Column(
        children: [
          line(height: 36, colour: AppColors.surface, const [
            Text('Value', style: headerStyle),
            Text('Stone A', textAlign: TextAlign.right, style: headerStyle),
            Text('Stone B', textAlign: TextAlign.right, style: headerStyle),
            Text('Diff.', textAlign: TextAlign.right, style: headerStyle),
          ]),
          for (final r in rows)
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: line([
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1,
                        style: AppText.label
                            .copyWith(color: AppColors.textPrimary)),
                    Text(r.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
                Text(r.$3.toStringAsFixed(r.$6),
                    textAlign: TextAlign.right, style: AppText.monoValue),
                Text(r.$4.toStringAsFixed(r.$6),
                    textAlign: TextAlign.right, style: AppText.monoValue),
                Text(
                  r.$5.toStringAsFixed(r.$6),
                  textAlign: TextAlign.right,
                  style: AppText.monoValue.copyWith(
                    fontWeight: FontWeight.w500,
                    color: r.$5 < 1
                        ? AppColors.success
                        : r.$5 <= 3
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Grade chip: swatch, "G3" and the GEMCLOUD name.
class _GradeChip extends StatelessWidget {
  final int gradeNumber;
  final String gradeName;
  final Color colour;

  const _GradeChip({
    required this.gradeNumber,
    required this.gradeName,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.lg, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('G$gradeNumber',
              style: AppText.titleSmall
                  .copyWith(fontSize: 11, color: AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(gradeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label
                    .copyWith(fontSize: 11, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// History bottom sheet with search, used to choose Stone A or B.
class _StonePickerSheet extends StatefulWidget {
  final String title;
  final List<GradeResult> history;
  final GradeResult? current;
  final GradeResult? other;
  final String otherLabel;
  final String Function(GradeResult) subtitle;

  const _StonePickerSheet({
    required this.title,
    required this.history,
    required this.current,
    required this.other,
    required this.otherLabel,
    required this.subtitle,
  });

  @override
  State<_StonePickerSheet> createState() => _StonePickerSheetState();
}

class _StonePickerSheetState extends State<_StonePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.history
        : widget.history
            .where((r) => r.stoneId.toLowerCase().contains(q))
            .toList();
    final height = MediaQuery.of(context).size.height * 0.62;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.lg, AppSpacing.screen, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppText.sectionHeader),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: AppText.body14,
                    decoration: const InputDecoration(
                      hintText: 'Search by stone ID',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        widget.history.isEmpty
                            ? 'No graded stones yet'
                            : 'No matching stones',
                        style: AppText.body14
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : SafeArea(
                      top: false,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _row(items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(GradeResult r) {
    final isOther = widget.other?.id == r.id;
    final on = widget.current?.id == r.id;
    return Opacity(
      opacity: isOther ? 0.5 : 1,
      child: Material(
        color: on ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: isOther ? null : () => Navigator.pop(context, r),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grades[(r.gradeNumber - 1).clamp(0, 6)],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.swatchOutline),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.stoneId, style: AppText.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.subtitle(r),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.secondary),
                    ],
                  ),
                ),
                if (isOther)
                  Container(
                    height: 20,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(widget.otherLabel,
                        style: AppText.titleSmall.copyWith(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ),
                if (on)
                  const Icon(Icons.check_rounded,
                      size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
