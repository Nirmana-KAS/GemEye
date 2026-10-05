import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/auth_service.dart';
import '../services/calibration_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../services/me_service.dart';
import '../services/remote_config_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_buttons.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/quick_grade_card.dart';
import '../widgets/recent_grade_tile.dart';
import '../widgets/relative_time.dart';
import '../widgets/skeleton.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_banner.dart';
import 'calibration_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Switches MainShell to the History tab ("See all").
  final VoidCallback? onOpenHistory;

  /// Opens the Notifications screen from the bell.
  final VoidCallback? onOpenNotifications;

  const HomeScreen({super.key, this.onOpenHistory, this.onOpenNotifications});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with RouteAware {
  static const int _recentCount = 5;

  final AuthService _authService = AuthService();
  List<GradeResult> _recent = [];
  int _todayCount = 0;
  double? _todayAvgConfidence;
  int _todayReferred = 0;
  bool _loaded = false;

  /// The update prompt is shown once per launch.
  static bool _updatePromptShown = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) AppRoutes.routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    AppRoutes.routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when a screen pushed above MainShell is popped.
  @override
  void didPopNext() => refresh();

  /// Shows the "update GemEye" prompt when the server asks for a newer app.
  Future<void> _checkUpdate() async {
    if (_updatePromptShown || !mounted || !RemoteConfigService.updateRequired) {
      return;
    }
    _updatePromptShown = true;
    await AppDialog.alert(
      context,
      title: 'Update GemEye',
      message: 'A newer version of GemEye is required '
          '(${RemoteConfigService.minAppVersion} or later). Please update '
          'the app to keep grading.',
      actionLabel: 'OK',
      type: AppDialogType.warning,
      icon: Icons.system_update_rounded,
    );
  }

  /// Reloads stats, recent grades and the unread badge from the server
  /// (saved results when it cannot be reached).
  Future<void> refresh() async {
    try {
      // Saved results first, so Home never waits for the network.
      if (!_loaded) {
        _apply(await HistoryService.cachedSummary(recentCount: _recentCount));
      }
      unawaited(RemoteConfigService.refresh().then((_) => _checkUpdate()));
      unawaited(MeService.sync());
      unawaited(CalibrationService.syncPending());
      final summary = await HistoryService.homeSummary(recentCount: _recentCount);
      await CalibrationService.remindIfExpired();
      await NotificationService.list();
      _apply(summary);
    } catch (e) {
      if (kDebugMode) debugPrint('Home refresh failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _apply(({List<GradeResult> recent, List<GradeResult> today}) summary) {
    if (!mounted) return;
    final today = summary.today;
    setState(() {
      _recent = summary.recent;
      _todayCount = today.length;
      _todayAvgConfidence = today.isEmpty
          ? null
          : today.map((r) => r.confidence).reduce((a, b) => a + b) /
              today.length;
      _todayReferred = today.where((r) => r.isReferred).length;
      _loaded = true;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _firstName() {
    final name = _authService.getFirstName();
    if (name.isEmpty) return 'User';
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  String _initials() {
    final user = _authService.currentUser;
    final source = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : _firstName();
    final parts = source.split(RegExp(r'\s+'));
    final letters = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'
        : parts.first.substring(0, parts.first.length >= 2 ? 2 : 1);
    return letters.toUpperCase();
  }

  Widget _buildMaintenanceBanner() {
    return ValueListenableBuilder<int>(
      valueListenable: RemoteConfigService.changes,
      builder: (context, _, __) {
        if (!RemoteConfigService.maintenance) return const SizedBox.shrink();
        final message = RemoteConfigService.maintenanceMessage.trim();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: StatusBanner(
            type: StatusBannerType.warning,
            icon: Icons.build_rounded,
            message: message.isEmpty
                ? 'GemEye is under maintenance. Grading may be unavailable.'
                : message,
          ),
        );
      },
    );
  }

  void _openCapture() => CalibrationScreen.openGrading(context);

  Widget _buildCalibrationBanner() {
    return ValueListenableBuilder<CalibrationSession?>(
      valueListenable: CalibrationService.session,
      builder: (context, s, _) {
        final StatusBannerType type;
        final String message;
        if (s == null) {
          type = StatusBannerType.error;
          message = 'Not calibrated. Calibrate before grading.';
        } else if (!s.isValid) {
          type = StatusBannerType.warning;
          message =
              'Calibration is over 8 hours old. Recalibrate for best accuracy.';
        } else {
          final when = isSameDay(s.createdAt, DateTime.now())
              ? 'today ${DateFormat('HH:mm').format(s.createdAt)}'
              : DateFormat('d MMM HH:mm').format(s.createdAt);
          type = StatusBannerType.success;
          message =
              'Calibrated · ${s.deviceModel} · Session ${s.dayNumber} · $when';
        }
        return StatusBanner(
          type: type,
          message: message,
          onTap: () => AppRoutes.push(context, const CalibrationScreen()),
        );
      },
    );
  }

  void _openResult(GradeResult result) {
    AppRoutes.push(
      context,
      ResultScreen(
          imagePath: result.capturedImagePath,
          gradeResult: result,
          fromHistory: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.darkIcons,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
              children: !_loaded
                  ? [_buildSkeleton()]
                  : [
                      _buildHeader(context),
                      const OfflineBanner(
                          padding: EdgeInsets.only(top: AppSpacing.xl)),
                      _buildMaintenanceBanner(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildCalibrationBanner(),
                      const SizedBox(height: AppSpacing.xl),
                      ValueListenableBuilder<bool>(
                        valueListenable: ConnectivityService.online,
                        builder: (context, online, _) =>
                            QuickGradeCard(onTap: online ? _openCapture : null),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStats(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildRecent(),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loading skeleton (System States): header, banner, hero card, stats
  /// and three recent rows.
  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 96, height: 12, radius: 6),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBox(width: 140, height: 20),
                ],
              ),
            ),
            SkeletonBox(height: 40, circle: true),
            SizedBox(width: AppSpacing.md),
            SkeletonBox(height: 40, circle: true),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonBox(height: 48, radius: AppRadius.lg),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonBox(height: 152, radius: AppRadius.xxl),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              const Expanded(
                  child: SkeletonBox(height: 88, radius: AppRadius.lg)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 120, height: 16),
        ),
        for (final w in const [
          [0.7, 0.45],
          [0.6, 0.5],
          [0.75, 0.4],
        ]) ...[
          const SizedBox(height: AppSpacing.xl),
          SkeletonRow(lines: w),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final photoUrl = _authService.currentUser?.photoURL;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_greeting()},',
                  style:
                      AppText.body14.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _firstName(),
                overflow: TextOverflow.ellipsis,
                style: AppText.screenTitle.copyWith(fontSize: 22, height: 1.2),
              ),
            ],
          ),
        ),
        NotificationBell(onPressed: () => widget.onOpenNotifications?.call()),
        Semantics(
          button: true,
          label: 'Open menu',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: Center(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(_initials(),
                          style: AppText.titleSmall
                              .copyWith(color: AppColors.onPrimary))
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final avg = _todayAvgConfidence;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StatCard(
              label: 'Today', value: '$_todayCount', caption: 'stones'),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            label: 'Avg confidence',
            value: avg == null ? '-' : '${avg.round()}%',
            caption: 'today',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
              label: 'Referred',
              value: '$_todayReferred',
              caption: 'borderline'),
        ),
      ],
    );
  }

  Widget _buildRecent() {
    final hasItems = _recent.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.touchTarget,
          child: Row(
            children: [
              const Expanded(
                  child: Text('Recent Grades', style: AppText.sectionHeader)),
              if (hasItems)
                TextLinkButton(
                  label: 'See all',
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: widget.onOpenHistory,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (hasItems)
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _recent.length; i++)
                  RecentGradeTile(
                    result: _recent[i],
                    showTopBorder: i > 0,
                    onTap: () => _openResult(_recent[i]),
                  ),
              ],
            ),
          )
        else
          EmptyState(
            icon: Icons.diamond_rounded,
            title: 'No stones graded yet',
            message:
                'Grade your first sapphire and the report will appear here.',
            actionLabel: 'Grade a stone',
            onAction: _openCapture,
          ),
      ],
    );
  }
}
