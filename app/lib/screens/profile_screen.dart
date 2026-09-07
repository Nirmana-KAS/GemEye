import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _designationController = TextEditingController();

  int _totalCount = 0;
  int _certCount = 0;
  int _monthCount = 0;
  String _originalName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    _originalName = user?.displayName ?? '';
    _nameController.text = _originalName;
    _phoneController.text = prefs.getString('profile_phone') ?? '';
    _companyController.text = prefs.getString('company_name') ?? '';
    _designationController.text = prefs.getString('profile_designation') ?? '';
  }

  Future<void> _loadStats() async {
    final history = await StorageService.getGradeHistory();
    final now = DateTime.now();
    setState(() {
      _totalCount = history.length;
      _certCount = history.where((r) => r.certificateNumber != null).length;
      _monthCount = history
          .where((r) =>
              r.capturedAt.year == now.year && r.capturedAt.month == now.month)
          .length;
    });
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = _nameController.text.trim();
      if (name.isNotEmpty && name != _originalName) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      }
      await prefs.setString('profile_phone', _phoneController.text.trim());
      await prefs.setString('company_name', _companyController.text.trim());
      await prefs.setString(
          'profile_designation', _designationController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: GemEyeColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFF5F7FA),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person,
                                size: 50, color: Color(0xFF6B7280))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: GemEyeColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Individual Account',
                      style: TextStyle(
                        fontFamily: GemEyeFonts.body,
                        fontSize: 11,
                        color: GemEyeColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Personal Information',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    const Icon(Icons.person_outline, color: GemEyeColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style:
                  const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: GemEyeColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style:
                  const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                labelText: 'Company (Optional)',
                prefixIcon: const Icon(Icons.business_outlined,
                    color: GemEyeColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style:
                  const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _designationController,
              decoration: InputDecoration(
                labelText: 'Designation (Optional)',
                prefixIcon:
                    const Icon(Icons.work_outline, color: GemEyeColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style:
                  const TextStyle(fontFamily: GemEyeFonts.body, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Grading Statistics',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Total Graded', _totalCount.toString(),
                    Icons.diamond_outlined),
                const SizedBox(width: 8),
                _statCard('Certificates', _certCount.toString(),
                    Icons.description_outlined),
                const SizedBox(width: 8),
                _statCard('This Month', _monthCount.toString(),
                    Icons.calendar_today_outlined),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Account Information',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Email', user?.email ?? ''),
            _infoRow(
                'Account Created', _formatDate(user?.metadata.creationTime)),
            _infoRow(
                'Last Sign In', _formatDate(user?.metadata.lastSignInTime)),
            _infoRow(
              'Auth Provider',
              user?.providerData.isNotEmpty == true
                  ? user!.providerData.first.providerId
                  : 'email',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: GemEyeColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 10,
                color: GemEyeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: GemEyeFonts.body,
              fontSize: 13,
              color: GemEyeColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
