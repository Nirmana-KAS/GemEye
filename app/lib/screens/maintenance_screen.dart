import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/remote_config_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/full_screen_message.dart';

/// Covers the whole app while remote config `maintenance.enabled` is on
/// (MaintenanceGate). Shows the admin's message; Retry reads /config again.
class MaintenanceScreen extends StatefulWidget {
  /// Reads /config again (RemoteConfigService.refresh); replaced in tests.
  final Future<void> Function() onRetry;

  const MaintenanceScreen({super.key, required this.onRetry});

  static const String defaultMessage =
      'GemEye is under maintenance. Please try again later.';

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = RemoteConfigService.maintenanceMessage.trim();
    return FullScreenMessage(
      icon: Icons.build_rounded,
      iconColor: AppColors.warningText,
      iconTint: AppColors.warningTint,
      title: 'Under maintenance',
      message: message.isEmpty ? MaintenanceScreen.defaultMessage : message,
      actions: [
        PrimaryButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          isLoading: _checking,
          loadingLabel: 'Checking...',
          onPressed: _retry,
        ),
      ],
    );
  }
}

/// Wraps the app (MaterialApp.builder): while maintenance is on, the
/// MaintenanceScreen covers everything. The app below stays mounted
/// (Offstage), so its navigation state is kept for when maintenance ends.
class MaintenanceGate extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRetry;

  const MaintenanceGate({super.key, required this.child, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RemoteConfigService.changes,
      builder: (context, _, __) {
        final on = RemoteConfigService.maintenance;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(offstage: on, child: TickerMode(enabled: !on, child: child)),
            if (on)
              MaintenanceScreen(
                  onRetry: onRetry ?? () => RemoteConfigService.refresh()),
          ],
        );
      },
    );
  }
}
