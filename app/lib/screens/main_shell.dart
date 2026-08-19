import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/side_drawer.dart';
import 'home_screen.dart';
import 'capture_screen.dart';

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
    const _PlaceholderScreen(title: 'History', icon: Icons.history_rounded),
    const _PlaceholderScreen(title: 'Guide', icon: Icons.palette_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const GemEyeSideDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: GemEyeBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
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
