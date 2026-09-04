import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/side_drawer.dart';
import 'home_screen.dart';
import 'capture_screen.dart';
import 'history_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 1) {
      AppRoutes.push(context, const CaptureScreen());
    } else {
      setState(() => _currentIndex = index);
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const _PlaceholderScreen(title: 'Grade', icon: Icons.camera_alt_rounded),
    const HistoryScreen(),
    const _PlaceholderScreen(title: 'Guide', icon: Icons.palette_rounded),
  ];

  void _handleBackButton(bool didPop, dynamic result) {
    if (didPop) return;

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
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
          onTabSwitch: (index) => setState(() => _currentIndex = index),
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
