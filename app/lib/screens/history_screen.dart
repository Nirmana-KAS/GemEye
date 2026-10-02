import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import '../services/certificate_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/skeleton.dart';
import 'calibration_screen.dart';
import 'result_screen.dart';

/// Sort orders for the history list.
enum HistorySort {
  newest('Newest first', 'Date', Icons.arrow_downward_rounded),
  oldest('Oldest first', 'Date', Icons.arrow_upward_rounded),
  gradeAsc('G1 to G7', 'Grade', Icons.arrow_downward_rounded),
  gradeDesc('G7 to G1', 'Grade', Icons.arrow_upward_rounded),
  confidenceDesc('Highest first', 'Confidence', Icons.arrow_downward_rounded),
  confidenceAsc('Lowest first', 'Confidence', Icons.arrow_upward_rounded);

  final String label;
  final String group;
  final IconData icon;
  const HistorySort(this.label, this.group, this.icon);
}

enum _ConfidenceFilter { all, high, borderline }

enum _CertificateFilter { all, exported, notExported }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _allSessions = 'All sessions';

  List<GradeResult> _allHistory = [];
  bool _loaded = false;
  List<GradeResult> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();

  /// 0 = All, 1-7 = grade, 8 = Referred.
  int _chip = 0;

  // Filter sheet state
  DateTime? _dateFrom;
  DateTime? _dateTo;
  _ConfidenceFilter _confidenceFilter = _ConfidenceFilter.all;
  _CertificateFilter _certificateFilter = _CertificateFilter.all;
  String _sessionFilter = _allSessions;
  HistorySort _sort = HistorySort.newest;

  // Batch selection
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_applyFilters);
    // Referred follows the threshold set in Settings.
    SettingsService.referralThreshold.addListener(_applyFilters);
  }

  @override
  void dispose() {
    SettingsService.referralThreshold.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await StorageService.getGradeHistory();
      if (!mounted) return;
      setState(() {
        _allHistory = history;
        _loaded = true;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('History load failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  List<GradeResult> _filter({
    required DateTime? from,
    required DateTime? to,
    required _ConfidenceFilter confidence,
    required _CertificateFilter certificate,
    required String session,
  }) {
    var results = List<GradeResult>.from(_allHistory);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      results = results
          .where((r) => r.stoneId.toLowerCase().contains(query))
          .toList();
    }

    if (_chip >= 1 && _chip <= 7) {
      results = results.where((r) => r.gradeNumber == _chip).toList();
    } else if (_chip == 8) {
      results = results.where(_isReferred).toList();
    }

    if (from != null) {
      final start = DateTime(from.year, from.month, from.day);
      results = results.where((r) => !r.capturedAt.isBefore(start)).toList();
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      results = results.where((r) => !r.capturedAt.isAfter(endOfDay)).toList();
    }

    switch (confidence) {
      case _ConfidenceFilter.high:
        results = results.where((r) => !_isReferred(r)).toList();
      case _ConfidenceFilter.borderline:
        results = results.where(_isReferred).toList();
      case _ConfidenceFilter.all:
        break;
    }

    switch (certificate) {
      case _CertificateFilter.exported:
        results = results.where((r) => r.certificateNumber != null).toList();
      case _CertificateFilter.notExported:
        results = results.where((r) => r.certificateNumber == null).toList();
      case _CertificateFilter.all:
        break;
    }

    if (session != _allSessions) {
      results = results.where((r) => r.sessionId == session).toList();
    }
    return results;
  }

  void _applyFilters() {
    final results = _filter(
      from: _dateFrom,
      to: _dateTo,
      confidence: _confidenceFilter,
      certificate: _certificateFilter,
      session: _sessionFilter,
    );

    switch (_sort) {
      case HistorySort.oldest:
        results.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      case HistorySort.gradeAsc:
        results.sort((a, b) => a.gradeNumber.compareTo(b.gradeNumber));
      case HistorySort.gradeDesc:
        results.sort((a, b) => b.gradeNumber.compareTo(a.gradeNumber));
      case HistorySort.confidenceDesc:
        results.sort((a, b) => b.confidence.compareTo(a.confidence));
      case HistorySort.confidenceAsc:
        results.sort((a, b) => a.confidence.compareTo(b.confidence));
      case HistorySort.newest:
        results.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    }

    setState(() => _filteredHistory = results);
  }

  static bool _isReferred(GradeResult r) =>
      r.confidence < ConfidenceBadge.referThreshold;

  int get _activeFilterCount {
    int count = 0;
    if (_dateFrom != null || _dateTo != null) count++;
    if (_confidenceFilter != _ConfidenceFilter.all) count++;
    if (_certificateFilter != _CertificateFilter.all) count++;
    if (_sessionFilter != _allSessions) count++;
    return count;
  }

  List<String> get _sessions {
    final ids = <String>{for (final r in _allHistory) r.sessionId}.toList()
      ..sort((a, b) => b.compareTo(a));
    return ids;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  String get _countText {
    final n = _filteredHistory.length;
    final stones = '$n stone${n == 1 ? '' : 's'}';
    if (_dateFrom == null && _dateTo == null) return '$stones · All time';
    final from = _dateFrom != null ? _fmtDate(_dateFrom!) : 'Start';
    final to = _dateTo != null ? _fmtDate(_dateTo!) : 'Today';
    return '$stones · $from to $to';
  }

  String _meta(GradeResult r) {
    final level = r.confidence >= ConfidenceBadge.referThreshold
        ? 'High'
        : r.confidence >= ConfidenceBadge.lowThreshold
            ? 'Borderline'
            : 'Low';
    final t = r.capturedAt;
    final now = DateTime.now();
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    final when = sameDay ? hm : '${t.day} ${_months[t.month - 1]}, $hm';
    return '$level ${r.confidence.round()}% · $when';
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(GradeResult result) {
    setState(() {
      if (_selectedIds.contains(result.id)) {
        _selectedIds.remove(result.id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(result.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete stones?',
      message:
          'Delete $count selected stone${count > 1 ? 's' : ''}? This cannot be undone.',
      confirmLabel: 'Delete',
      type: AppDialogType.danger,
      icon: Icons.delete_rounded,
    );
    if (!confirmed) return;
    try {
      for (final id in _selectedIds) {
        await StorageService.deleteGradeResult(id);
      }
    } catch (e) {
      debugPrint('Batch delete failed: $e');
    }
    _exitSelectionMode();
    await _loadHistory();
    if (mounted) {
      AppSnackBar.show(context,
          message: '$count stone${count > 1 ? 's' : ''} deleted',
          type: AppSnackBarType.success);
    }
  }

  Future<void> _exportSelected() async {
    final selectedResults =
        _filteredHistory.where((r) => _selectedIds.contains(r.id)).toList();
    if (selectedResults.isEmpty) return;
    int generated = 0;

    for (final result in selectedResults) {
      try {
        if (result.certificateNumber == null) {
          result.certificateNumber =
              await CertificateService.generateCertificateNumber();
          await StorageService.saveGradeResult(result);
        }

        Uint8List stoneImageBytes;
        try {
          stoneImageBytes = await File(result.capturedImagePath).readAsBytes();
        } catch (_) {
          stoneImageBytes = Uint8List(0);
        }

        final pdfBytes = await CertificateService.generateCertificatePdf(
          result: result,
          stoneImage: stoneImageBytes,
        );

        final dir = await getApplicationDocumentsDirectory();
        final certDir = Directory('${dir.path}/GemEye Certificates');
        if (!await certDir.exists()) {
          await certDir.create(recursive: true);
        }
        final file = File('${certDir.path}/${result.certificateNumber}.pdf');
        await file.writeAsBytes(pdfBytes);
        generated++;
      } catch (e) {
        debugPrint('Export failed for ${result.stoneId}: $e');
      }
    }

    _exitSelectionMode();
    await _loadHistory();
    if (mounted) {
      AppSnackBar.show(context,
          message: '$generated certificate${generated == 1 ? '' : 's'} saved',
          type:
              generated > 0 ? AppSnackBarType.success : AppSnackBarType.error);
    }
  }

  Future<void> _shareSelected() async {
    final selectedResults =
        _filteredHistory.where((r) => _selectedIds.contains(r.id)).toList();
    final files = <XFile>[];
    for (final result in selectedResults) {
      final file = File(result.capturedImagePath);
      if (await file.exists()) {
        files.add(XFile(file.path));
      }
    }
    if (files.isEmpty) {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'No images available to share',
            type: AppSnackBarType.warning);
      }
      return;
    }
    try {
      await Share.shareXFiles(files, text: 'GemEye graded stones');
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Could not share the selected stones',
            type: AppSnackBarType.error);
      }
    }
  }

  Future<bool> _deleteItem(GradeResult result) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete ${result.stoneId}?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      type: AppDialogType.danger,
      icon: Icons.delete_rounded,
    );
    if (!confirmed) return false;
    try {
      await StorageService.deleteGradeResult(result.id);
    } catch (e) {
      debugPrint('Delete failed: $e');
      return false;
    }
    await _loadHistory();
    if (mounted) {
      AppSnackBar.show(context,
          message: '${result.stoneId} deleted', type: AppSnackBarType.success);
    }
    return false;
  }

  Future<void> _openResult(GradeResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imagePath: result.capturedImagePath,
          gradeResult: result,
        ),
      ),
    );
    _loadHistory();
  }

  // Sheets

  Widget _sheetHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Future<T?> _showSheet<T>(WidgetBuilder builder) => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: AppColors.card,
        barrierColor: AppColors.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: builder,
      );

  void _showSortSheet() {
    final groups = <String, List<HistorySort>>{};
    for (final s in HistorySort.values) {
      (groups[s.group] ??= []).add(s);
    }
    _showSheet<void>((ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl,
                      AppSpacing.lg, AppSpacing.md),
                  child: Text('Sort by', style: AppText.sectionHeader),
                ),
                for (final g in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                    child: Text(g.key.toUpperCase(),
                        style: AppText.titleSmall.copyWith(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            color: AppColors.textSecondary)),
                  ),
                  for (final s in g.value) _sortOption(ctx, s),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _sortOption(BuildContext ctx, HistorySort s) {
    final on = s == _sort;
    final colour = on ? AppColors.primary : AppColors.textPrimary;
    return Material(
      color: on ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          setState(() => _sort = s);
          _applyFilters();
          Navigator.pop(ctx);
        },
        child: SizedBox(
          height: AppSpacing.touchTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(s.icon,
                    size: 20,
                    color: on ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(s.label,
                      style: on
                          ? AppText.titleSmall.copyWith(color: colour)
                          : AppText.body14.copyWith(color: colour)),
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

  void _showFilterSheet() {
    DateTime? tempFrom = _dateFrom;
    DateTime? tempTo = _dateTo;
    var tempConfidence = _confidenceFilter;
    var tempCertificate = _certificateFilter;
    var tempSession = _sessionFilter;
    final sessions = [_allSessions, ..._sessions];

    _showSheet<void>((ctx) => StatefulBuilder(builder: (ctx, setSheet) {
          final matches = _filter(
            from: tempFrom,
            to: tempTo,
            confidence: tempConfidence,
            certificate: tempCertificate,
            session: tempSession,
          ).length;

          Future<void> pick(bool isFrom) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: (isFrom ? tempFrom : tempTo) ?? now,
              firstDate: DateTime(2024),
              lastDate: now,
            );
            if (picked != null) {
              setSheet(() => isFrom ? tempFrom = picked : tempTo = picked);
            }
          }

          Widget dateField(bool isFrom) {
            final value = isFrom ? tempFrom : tempTo;
            return Expanded(
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => pick(isFrom),
                  child: SizedBox(
                    height: AppSpacing.controlHeight,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              '${isFrom ? 'From' : 'To'} '
                              '${value != null ? _fmtDate(value) : 'Any'}',
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body14.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                    AppSpacing.md, AppSpacing.screen, AppSpacing.screen),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(
                            child:
                                Text('Filters', style: AppText.sectionHeader)),
                        TextLinkButton(
                          label: 'Reset',
                          onPressed: () => setSheet(() {
                            tempFrom = null;
                            tempTo = null;
                            tempConfidence = _ConfidenceFilter.all;
                            tempCertificate = _CertificateFilter.all;
                            tempSession = _allSessions;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text('Date range', style: AppText.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      dateField(true),
                      const SizedBox(width: AppSpacing.md),
                      dateField(false),
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text('Confidence', style: AppText.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    _SegmentRow<_ConfidenceFilter>(
                      options: const {
                        _ConfidenceFilter.all: 'All',
                        _ConfidenceFilter.high: 'High only',
                        _ConfidenceFilter.borderline: 'Borderline only',
                      },
                      selected: tempConfidence,
                      onChanged: (v) => setSheet(() => tempConfidence = v),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text('Certificate', style: AppText.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    _SegmentRow<_CertificateFilter>(
                      options: const {
                        _CertificateFilter.all: 'All',
                        _CertificateFilter.exported: 'Exported',
                        _CertificateFilter.notExported: 'Not exported',
                      },
                      selected: tempCertificate,
                      onChanged: (v) => setSheet(() => tempCertificate = v),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    DropdownField<String>(
                      label: 'Session',
                      items: sessions,
                      value: tempSession,
                      onChanged: (v) => setSheet(() => tempSession = v),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: PrimaryButton(
                            label:
                                'Show $matches stone${matches == 1 ? '' : 's'}',
                            onPressed: () {
                              setState(() {
                                _dateFrom = tempFrom;
                                _dateTo = tempTo;
                                _confidenceFilter = tempConfidence;
                                _certificateFilter = tempCertificate;
                                _sessionFilter = tempSession;
                              });
                              _applyFilters();
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }));
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
        body: SafeArea(
          top: false,
          child: !_loaded
              ? _buildSkeleton()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                      child: TextField(
                        controller: _searchController,
                        style: AppText.body14,
                        decoration: const InputDecoration(
                          hintText: 'Search by stone ID',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                        children: [
                          for (int i = 0; i <= 8; i++) _buildChip(i),
                        ],
                      ),
                    ),
                    Container(
                      height: 32,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      decoration: const BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_countText,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label),
                          ),
                          Text('${_sort.group} · ${_sort.label.toLowerCase()}',
                              style: AppText.secondary),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredHistory.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: _filteredHistory.length,
                              itemBuilder: (context, index) =>
                                  _buildHistoryItem(_filteredHistory[index]),
                            ),
                    ),
                    if (_isSelectionMode) _buildBatchActionBar(),
                  ],
                ),
        ),
      ),
    );
  }

  /// Loading skeleton (System States): search, chips and seven rows.
  Widget _buildSkeleton() {
    const widths = [
      [0.56, 0.40, 0.48],
      [0.52, 0.36, 0.30],
      [0.60, 0.44, 0.38],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: SkeletonBox(height: 48, radius: AppRadius.lg),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
          child: Row(
            children: [
              for (final w in const [48.0, 48.0, 48.0, 48.0, 72.0]) ...[
                SkeletonBox(width: w, height: 32, radius: 16),
                const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 7,
              itemBuilder: (context, i) => Container(
                height: 80,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: SkeletonRow(lines: widths[i % 3]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    final filters = _activeFilterCount;
    return GemAppBar(
      title: 'Grading History',
      leading: GemAppBarLeading.menu,
      // The drawer belongs to MainShell's Scaffold, above this one.
      onLeadingPressed: () => Scaffold.maybeOf(context)?.openEndDrawer(),
      actions: [
        IconButton(
          tooltip: 'Sort',
          color: AppColors.onPrimary,
          icon: const Icon(Icons.swap_vert_rounded),
          onPressed: _showSortSheet,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Filters',
              color: AppColors.onPrimary,
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showFilterSheet,
            ),
            if (filters > 0)
              Positioned(
                right: 5,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Text('$filters',
                        style: AppText.titleSmall.copyWith(
                            fontSize: 10,
                            height: 1,
                            color: AppColors.onPrimary)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    final allSelected = _filteredHistory.isNotEmpty &&
        _selectedIds.length == _filteredHistory.length;
    return GemAppBar(
      title: '${_selectedIds.length} selected',
      leading: GemAppBarLeading.back,
      onLeadingPressed: _exitSelectionMode,
      actions: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onPrimary,
            textStyle: AppText.button.copyWith(fontSize: 13),
            minimumSize: const Size(0, AppSpacing.touchTarget),
          ),
          icon: Icon(
              allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
              size: 20),
          label: Text(allSelected ? 'None' : 'All'),
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedIds.clear();
                _isSelectionMode = false;
              } else {
                _selectedIds.addAll(_filteredHistory.map((r) => r.id));
              }
            });
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildChip(int index) {
    final on = _chip == index;
    final label = index == 0
        ? 'All'
        : index == 8
            ? 'Referred'
            : 'G$index';
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Material(
        color: on ? AppColors.primary : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: on ? AppColors.primary : AppColors.border),
        ),
        child: InkWell(
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () {
            setState(() => _chip = index);
            _applyFilters();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (on) ...[
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (index >= 1 && index <= 7) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.grades[index - 1],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: on
                              ? AppColors.onPrimaryRing
                              : AppColors.swatchOutline),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Text(label,
                    style: AppText.label.copyWith(
                        color:
                            on ? AppColors.onPrimary : AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(GradeResult result) {
    final selected = _selectedIds.contains(result.id);
    final referred = _isReferred(result);

    return Dismissible(
      key: Key(result.id),
      direction: _isSelectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.25},
      confirmDismiss: (_) => _deleteItem(result),
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        child: const SizedBox(
          width: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_rounded, size: 22, color: AppColors.onPrimary),
              SizedBox(height: AppSpacing.xs),
              Text('Delete',
                  style: TextStyle(
                      fontFamily: AppText.heading,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary)),
            ],
          ),
        ),
      ),
      child: Material(
        color: selected ? AppColors.surface : AppColors.card,
        child: InkWell(
          onLongPress: _isSelectionMode
              ? null
              : () => setState(() {
                    _isSelectionMode = true;
                    _selectedIds.add(result.id);
                  }),
          onTap: () =>
              _isSelectionMode ? _toggleSelected(result) : _openResult(result),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_isSelectionMode) ...[
                  _SelectBox(checked: selected),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        AppColors.grades[(result.gradeNumber - 1).clamp(0, 6)],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.swatchOutline),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(result.stoneId,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.titleSmall),
                          ),
                          if (referred) const _ReferredPill(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Grade ${result.gradeNumber} · ${result.gradeName}',
                          style: AppText.label
                              .copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_meta(result), style: AppText.secondary),
                      if (result.certificateNumber != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _CertificatePill(number: result.certificateNumber!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar() {
    final enabled = _selectedIds.isNotEmpty;
    Widget action(IconData icon, String label, VoidCallback onTap,
        {bool danger = false}) {
      final colour = !enabled
          ? AppColors.textMuted
          : danger
              ? AppColors.error
              : AppColors.primary;
      return Expanded(
        child: InkWell(
          onTap: enabled ? onTap : null,
          highlightColor: danger ? AppColors.errorTint : AppColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: colour),
              const SizedBox(height: AppSpacing.xs),
              Text(label,
                  style:
                      AppText.titleSmall.copyWith(fontSize: 11, color: colour)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          action(
              Icons.workspace_premium_rounded, 'Export Batch', _exportSelected),
          action(Icons.share_rounded, 'Share', _shareSelected),
          action(Icons.delete_rounded, 'Delete', _deleteSelected, danger: true),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final noStones = _allHistory.isEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, AppSpacing.xl),
      child: noStones
          ? EmptyState(
              icon: Icons.diamond_outlined,
              title: 'No stones graded yet',
              message:
                  'Grade your first sapphire and the report will appear here.',
              actionLabel: 'Grade a stone',
              onAction: () => CalibrationScreen.openGrading(context),
            )
          : EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching stones',
              message: 'Try a different search, grade chip or filter.',
              actionLabel: 'Clear filters',
              onAction: () {
                _searchController.clear();
                setState(() {
                  _chip = 0;
                  _dateFrom = null;
                  _dateTo = null;
                  _confidenceFilter = _ConfidenceFilter.all;
                  _certificateFilter = _CertificateFilter.all;
                  _sessionFilter = _allSessions;
                });
                _applyFilters();
              },
            ),
    );
  }
}

/// Square selection checkbox for history rows.
class _SelectBox extends StatelessWidget {
  final bool checked;

  const _SelectBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
            color: checked ? AppColors.primary : AppColors.textMuted, width: 2),
      ),
      child: checked
          ? const Icon(Icons.check_rounded,
              size: 14, color: AppColors.onPrimary)
          : null,
    );
  }
}

class _ReferredPill extends StatelessWidget {
  const _ReferredPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: AppColors.warning, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Referred', style: AppText.titleSmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _CertificatePill extends StatelessWidget {
  final String number;

  const _CertificatePill({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(number,
              style: AppText.monoValue
                  .copyWith(fontSize: 10, color: AppColors.primary)),
        ],
      ),
    );
  }
}

/// Compact segmented control used in the filter sheet (13 px labels).
class _SegmentRow<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.controlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in options.entries.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Material(
                color:
                    e.key == selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(i == 0 ? AppRadius.lg : 0),
                  right: Radius.circular(
                      i == options.length - 1 ? AppRadius.lg : 0),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(e.key),
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          e.value,
                          style: e.key == selected
                              ? AppText.button.copyWith(
                                  fontSize: 13, color: AppColors.onPrimary)
                              : AppText.body14Medium.copyWith(
                                  fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
