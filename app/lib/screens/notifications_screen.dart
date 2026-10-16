import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../widgets/app_dialog.dart';
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

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  static const Duration _undoWindow = Duration(seconds: 4);

  List<AppNotification> _items = [];
  bool _loaded = false;

  /// Clears waiting for the Undo window to pass before they are sent.
  final Map<String, Timer> _pendingClears = {};

  bool get _hasUnread => _items.any((n) => !n.read);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the screen ends the Undo window.
    for (final id in _pendingClears.keys.toList()) {
      _pendingClears.remove(id)!.cancel();
      unawaited(NotificationService.clear(id));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.list();
    if (!mounted) return;
    setState(() {
      _items =
          items.where((n) => !_pendingClears.containsKey(n.id)).toList();
      _loaded = true;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    await _load();
  }

  void _clear(AppNotification n) {
    setState(() => _items.removeWhere((i) => i.id == n.id));
    _pendingClears[n.id]?.cancel();
    _pendingClears[n.id] = Timer(_undoWindow, () {
      _pendingClears.remove(n.id);
      unawaited(NotificationService.clear(n.id));
    });
    AppSnackBar.show(
      context,
      message: 'Notification cleared',
      type: AppSnackBarType.info,
      actionLabel: 'Undo',
      duration: _undoWindow,
      onAction: () {
        _pendingClears.remove(n.id)?.cancel();
        if (mounted) _load();
      },
    );
  }

  Future<void> _clearAll() async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Clear all notifications?',
      message: "You won't see them again.",
      confirmLabel: 'Clear all',
      type: AppDialogType.danger,
      icon: Icons.clear_all_rounded,
    );
    if (!ok) return;
    for (final t in _pendingClears.values) {
      t.cancel();
    }
    _pendingClears.clear();
    await NotificationService.clearAll();
    await _load();
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
        Navigator.of(context).push(CaptureScreen.route());
      case AppNotificationAction.openHistory:
        Navigator.of(context).pop();
        widget.onOpenHistory?.call();
      case AppNotificationAction.openPrivacy:
        AppRoutes.push(context, const PrivacyScreen());
    }
  }

  Future<void> _openResult(String? stoneId) async {
    var history = await HistoryService.load(forceRefresh: false);
    if (!history.any((r) => r.stoneId == stoneId)) {
      history = await HistoryService.load();
    }
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
      ResultScreen(
          imagePath: result.capturedImagePath,
          gradeResult: result,
          fromHistory: true),
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
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textPrimary),
            color: AppColors.card,
            onSelected: (v) {
              if (v == 'clearAll') _clearAll();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'clearAll',
                enabled: _items.isNotEmpty,
                child: const Text('Clear all', style: AppText.body14),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_loaded) return const SizedBox.shrink();
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.notifications_off_rounded,
                      title: "You're all caught up",
                      message:
                          'Referrals, calibration reminders and report updates will appear here.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final today = _items.where((n) => isSameDay(n.createdAt, now)).toList();
    final earlier = _items.where((n) => !isSameDay(n.createdAt, now)).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (today.isNotEmpty) ..._section('Today', today),
          if (earlier.isNotEmpty) ..._section('Earlier', earlier),
        ],
      ),
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
          onClear: () => _clear(n),
        ),
    ];
  }
}
