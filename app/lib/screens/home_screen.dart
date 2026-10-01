import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/notification_bell.dart';
import '../widgets/quick_grade_card.dart';
import '../widgets/recent_grade_tile.dart';
import '../widgets/relative_time.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_banner.dart';
import 'calibration_screen.dart';
import 'capture_screen.dart';
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

  /// Reloads stats, recent grades and the unread badge.
  Future<void> refresh() async {
    try {
      final history = await StorageService.getGradeHistory();
      await NotificationService.list();
      final now = DateTime.now();
      final today = history.where((r) => isSameDay(r.capturedAt, now)).toList();
      if (!mounted) return;
      setState(() {
        _recent = history.take(_recentCount).toList();
        _todayCount = today.length;
        _todayAvgConfidence = today.isEmpty
            ? null
            : today.map((r) => r.confidence).reduce((a, b) => a + b) /
                today.length;
        _todayReferred = today
            .where((r) => r.confidence < ConfidenceBadge.referThreshold)
            .length;
        _loaded = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Home refresh failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
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

  void _openCapture() {
    // TODO(B9): route to Calibration when not calibrated (after C4).
    AppRoutes.push(context, const CaptureScreen());
  }

  void _openResult(GradeResult result) {
    AppRoutes.push(
      context,
      ResultScreen(imagePath: result.capturedImagePath, gradeResult: result),
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
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSpacing.xl),
                // TODO(C4): drive green/amber/red from saved calibration.
                StatusBanner(
                  type: StatusBannerType.error,
                  message: 'Not calibrated. Calibrate before grading.',
                  onTap: () =>
                      AppRoutes.push(context, const CalibrationScreen()),
                ),
                const SizedBox(height: AppSpacing.xl),
                QuickGradeCard(onTap: _openCapture),
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
            value: avg == null ? '—' : '${avg.round()}%',
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
        if (!_loaded)
          const SizedBox(height: 120)
        else if (hasItems)
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
