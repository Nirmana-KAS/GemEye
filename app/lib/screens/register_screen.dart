import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _businessRegController = TextEditingController();
  final _addressController = TextEditingController();
  final _authService = AuthService();

  String _accountType = 'individual';
  String _selectedCountry = 'Sri Lanka';
  String _selectedRole = 'Gemologist';
  String _selectedIndustry = 'Gem Trading';
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const List<String> _countries = [
    'Sri Lanka',
    'India',
    'Thailand',
    'Myanmar',
    'Australia',
    'United Kingdom',
    'United States',
    'Other',
  ];

  static const List<String> _roles = [
    'Gemologist',
    'Trader',
    'Exporter',
    'Student',
    'Other',
  ];

  static const List<String> _industries = [
    'Gem Trading',
    'Gem Export',
    'Jewellery',
    'Laboratory',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _businessRegController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final companyName = _companyNameController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter a password');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (_accountType == 'company' && companyName.isEmpty) {
      _showError('Please enter your company name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(email, password);
      await _authService.updateDisplayName(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: GemEyeColors.success,
          ),
        );
        AppRoutes.pushReplacement(context, const MainShell());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(e.message ?? 'Registration failed');
      }
    } catch (e) {
      if (mounted) {
        _showError('Registration failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildAccountTypeCard(String type, String label, IconData icon) {
    final isSelected = _accountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _accountType = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? GemEyeColors.primarySurface
                : GemEyeColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? GemEyeColors.primary : GemEyeColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color:
                    isSelected ? GemEyeColors.primary : GemEyeColors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GemEyeFonts.body,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? GemEyeColors.primary
                      : GemEyeColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: GemEyeFonts.body,
        fontSize: 14,
        color: GemEyeColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: GemEyeColors.textMuted),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: GemEyeFonts.body,
        fontSize: 14,
        color: GemEyeColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: GemEyeColors.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GemEyeColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Type',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.heading,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GemEyeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAccountTypeCard(
                          'individual', 'Individual', Icons.person_rounded),
                      const SizedBox(width: 12),
                      _buildAccountTypeCard(
                          'company', 'Company', Icons.business_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Min 8 characters',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: GemEyeColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _buildDropdown(
                    value: _selectedCountry,
                    items: _countries,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCountry = value);
                      }
                    },
                    icon: Icons.public_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (_accountType == 'individual')
                    _buildDropdown(
                      value: _selectedRole,
                      items: _roles,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                      icon: Icons.work_outline_rounded,
                    ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _accountType == 'company'
                        ? Column(
                            children: [
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _companyNameController,
                                hintText: 'Company name',
                                icon: Icons.business_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _businessRegController,
                                hintText: 'Business registration no. (optional)',
                                icon: Icons.numbers_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildDropdown(
                                value: _selectedIndustry,
                                items: _industries,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                        () => _selectedIndustry = value);
                                  }
                                },
                                icon: Icons.category_rounded,
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _addressController,
                                hintText: 'Company address (optional)',
                                icon: Icons.location_on_outlined,
                                maxLines: 2,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAccount,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.heading,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontFamily: GemEyeFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: GemEyeColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => AppRoutes.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: GemEyeFonts.heading,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GemEyeColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: GemEyeColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
