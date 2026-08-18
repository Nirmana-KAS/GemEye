import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firstName = authService.getFirstName();
    final capitalizedName =
        firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: const TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: GemEyeColors.textSecondary,
                          ),
                        ),
                        Text(
                          capitalizedName,
                          style: const TextStyle(
                            fontFamily: GemEyeFonts.heading,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: GemEyeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: GemEyeColors.primarySurface,
                        backgroundImage:
                            authService.currentUser?.photoURL != null
                                ? NetworkImage(
                                    authService.currentUser!.photoURL!)
                                : null,
                        child: authService.currentUser?.photoURL == null
                            ? Text(
                                capitalizedName[0],
                                style: const TextStyle(
                                  fontFamily: GemEyeFonts.heading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: GemEyeColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: GemEyeColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: GemEyeColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Not calibrated yet. Calibrate before grading.',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF92400E)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to capture screen
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          GemEyeColors.primary,
                          GemEyeColors.primaryLight
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              GemEyeColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.diamond_rounded,
                            size: 36, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Grade a Stone',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.heading,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to capture and classify',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.body,
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard('0', 'Today'),
                    const SizedBox(width: 10),
                    _buildStatCard('--', 'Avg Conf'),
                    const SizedBox(width: 10),
                    _buildStatCard('--', 'Avg ΔE₀₀'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Grades',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.heading,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: GemEyeColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GemEyeColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.diamond_outlined,
                          size: 40, color: GemEyeColors.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No stones graded yet',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GemEyeColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap "Grade a Stone" to get started',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 12,
                          color: GemEyeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GemEyeColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 11,
                color: GemEyeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
