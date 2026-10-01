import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/side_drawer.dart';
import 'home_screen.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'guide_screen.dart';
import 'notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  void _onNavTap(int index) {
    if (index == 1) {
      AppRoutes.push(context, const CaptureScreen());
    } else {
      _switchTab(index);
    }
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) _homeKey.currentState?.refresh();
  }

  late final List<Widget> _screens = [
    HomeScreen(
      key: _homeKey,
      onOpenHistory: () => _switchTab(2),
      onOpenNotifications: () => AppRoutes.push(
        context,
        NotificationsScreen(onOpenHistory: () => _switchTab(2)),
      ),
    ),
    const _PlaceholderScreen(title: 'Grade', icon: Icons.camera_alt_rounded),
    const HistoryScreen(),
    const GuideScreen(),
  ];

  void _handleBackButton(bool didPop, dynamic result) {
    if (didPop) return;

    if (_currentIndex != 0) {
      _switchTab(0);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Exit GemEye?',
          style: TextStyle(
            fontFamily: GemEyeFonts.heading,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            fontFamily: GemEyeFonts.body,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: GemEyeColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBackButton,
      child: Scaffold(
        backgroundColor: Colors.white,
        endDrawer: GemEyeSideDrawer(
          currentIndex: _currentIndex,
          onTabSwitch: _switchTab,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: GemEyeBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: GemEyeColors.textMuted),
              const SizedBox(height: 12),
              Text(
                '$title Screen',
                style: const TextStyle(
                  fontFamily: GemEyeFonts.heading,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: GemEyeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Coming soon...',
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 13,
                  color: GemEyeColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
