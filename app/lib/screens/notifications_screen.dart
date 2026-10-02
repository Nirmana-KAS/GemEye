import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/notification_tile.dart';
import '../widgets/relative_time.dart';
import 'calibration_screen.dart';
import 'capture_screen.dart';
import 'privacy_screen.dart';
import 'result_screen.dart';

class NotificationsScreen extends StatefulWidget {
  /// Called after this screen closes for [AppNotificationAction.openHistory]
  /// so MainShell can switch to the History tab.
  final VoidCallback? onOpenHistory;

  const NotificationsScreen({super.key, this.onOpenHistory});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loaded = false;

  bool get _hasUnread => _items.any((n) => !n.read);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.list();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loaded = true;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    await _load();
  }

  Future<void> _delete(AppNotification n) async {
    setState(() => _items.removeWhere((i) => i.id == n.id));
    await NotificationService.delete(n.id);
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) {
      await NotificationService.markRead(n.id);
      await _load();
    }
    if (!mounted) return;
    switch (n.action) {
      case AppNotificationAction.none:
        break;
      case AppNotificationAction.openResult:
        await _openResult(n.payload);
      case AppNotificationAction.openCalibration:
        AppRoutes.push(context, const CalibrationScreen());
      case AppNotificationAction.openCapture:
        AppRoutes.push(context, const CaptureScreen());
      case AppNotificationAction.openHistory:
        Navigator.of(context).pop();
        widget.onOpenHistory?.call();
      case AppNotificationAction.openPrivacy:
        AppRoutes.push(context, const PrivacyScreen());
    }
  }

  Future<void> _openResult(String? stoneId) async {
    final history = await StorageService.getGradeHistory();
    final matches = history.where((r) => r.stoneId == stoneId);
    if (!mounted) return;
    if (matches.isEmpty) {
      AppSnackBar.show(context,
          message: 'This record is no longer in your history',
          type: AppSnackBarType.info);
      return;
    }
    final result = matches.first;
    AppRoutes.push(
      context,
      ResultScreen(imagePath: result.capturedImagePath, gradeResult: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: 'Notifications',
        style: GemAppBarStyle.surface,
        leading: GemAppBarLeading.back,
        actions: [
          TextButton(
            onPressed: _hasUnread ? _markAllRead : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textMuted,
              textStyle: AppText.button.copyWith(fontSize: 13),
              minimumSize: const Size(AppSpacing.touchTarget, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text('Mark all as read'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_loaded) return const SizedBox.shrink();
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            icon: Icons.notifications_off_rounded,
            title: "You're all caught up",
            message:
                'Referrals, calibration reminders and report updates will appear here.',
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = _items.where((n) => isSameDay(n.createdAt, now)).toList();
    final earlier = _items.where((n) => !isSameDay(n.createdAt, now)).toList();

    return ListView(
      children: [
        if (today.isNotEmpty) ..._section('Today', today),
        if (earlier.isNotEmpty) ..._section('Earlier', earlier),
      ],
    );
  }

  List<Widget> _section(String title, List<AppNotification> items) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
        child: Text(
          title.toUpperCase(),
          style: AppText.label.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
      ),
      for (final n in items)
        NotificationTile(
          notification: n,
          onTap: () => _open(n),
          onDelete: () => _delete(n),
        ),
    ];
  }
}
