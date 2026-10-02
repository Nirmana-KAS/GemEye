import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/card_container.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/input_field.dart';
import '../widgets/or_divider.dart';
import '../widgets/password_field.dart';
import '../widgets/segmented_toggle.dart';
import 'onboarding_screen.dart';

enum _AccountType { individual, company }

class RegisterScreen extends StatefulWidget {
  /// Opens in "Complete your profile" mode for a user who has just signed
  /// in with Google: name and email come from Google and are locked.
  final bool completeGoogleProfile;

  const RegisterScreen({super.key, this.completeGoogleProfile = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const String _requiredSuffix = ' *';
  static const String _optionalSuffix = ' · Optional';

  static const List<String> _countries = [
    'Sri Lanka',
    'India',
    'Thailand',
    'United Arab Emirates',
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

  static final RegExp _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _businessRegController = TextEditingController();
  final _addressController = TextEditingController();
  final _authService = AuthService();

  _AccountType _accountType = _AccountType.individual;
  String? _selectedCountry = 'Sri Lanka';
  String? _selectedRole;
  String? _selectedIndustry;
  File? _profilePhoto;
  File? _companyLogo;
  bool _googleMode = false;
  bool _submitted = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _serverEmailError;

  bool get _isCompany => _accountType == _AccountType.company;

  /// Fields whose errors (and the profile initial) update as the user types.
  List<TextEditingController> get _validatedControllers => [
        _nameController,
        _emailController,
        _passwordController,
        _companyNameController,
      ];

  @override
  void initState() {
    super.initState();
    for (final c in _validatedControllers) {
      c.addListener(_refresh);
    }
    if (widget.completeGoogleProfile) {
      _enterGoogleMode(_authService.currentUser);
    }
  }

  @override
  void dispose() {
    for (final c in _validatedControllers) {
      c.removeListener(_refresh);
    }
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _businessRegController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _enterGoogleMode(User? user) {
    _googleMode = true;
    _submitted = false;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _requiredText(TextEditingController controller) {
    if (!_submitted) return null;
    return controller.text.trim().isEmpty ? 'Required' : null;
  }

  String? _requiredChoice(String? value) {
    if (!_submitted) return null;
    return value == null ? 'Required' : null;
  }

  String? get _nameError => _googleMode ? null : _requiredText(_nameController);

  String? get _emailError {
    if (_googleMode) return null;
    if (_serverEmailError != null) return _serverEmailError;
    if (!_submitted) return null;
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? get _passwordError {
    if (_googleMode || !_submitted) return null;
    final password = _passwordController.text.trim();
    if (password.isEmpty) return 'Required';
    if (!PasswordRule.allPass(PasswordRule.registration, password)) {
      return 'Password does not meet the requirements';
    }
    return null;
  }

  String? get _companyNameError =>
      _isCompany ? _requiredText(_companyNameController) : null;

  int _countErrors() {
    final errors = <String?>[
      _nameError,
      _emailError,
      _passwordError,
      _requiredChoice(_selectedCountry),
      if (_isCompany) ...[
        _companyNameError,
        _requiredChoice(_selectedIndustry),
      ] else
        _requiredChoice(_selectedRole),
    ];
    return errors.whereType<String>().length;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null || !mounted) return;
      if (result.additionalUserInfo?.isNewUser ?? false) {
        setState(() => _enterGoogleMode(result.user));
      } else {
        AppRoutes.pushReplacement(context, const OnboardingScreen());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Google sign-in failed. Please try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _serverEmailError = null;
    });

    final errorCount = _countErrors();
    if (errorCount > 0) {
      AppSnackBar.show(context,
          message: errorCount == 1
              ? '1 field needs attention'
              : '$errorCount fields need attention',
          type: AppSnackBarType.error);
      return;
    }

    if (_googleMode) {
      // TODO(F2): persist profile (phone, country, role, photo) for Google users.
      _persistCompanyProfile();
      _finishRegistration();
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(email, password);
      await _authService.updateDisplayName(name);
      // TODO(F2): persist profile (phone, country, role, photo).
      _persistCompanyProfile();
      if (mounted) _finishRegistration();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('Registration failed: ${e.code}');
      if (!mounted) return;
      switch (e.code) {
        case 'email-already-in-use':
          setState(() =>
              _serverEmailError = 'An account already exists for this email');
        case 'invalid-email':
          setState(() => _serverEmailError = 'Enter a valid email address');
        case 'network-request-failed':
          AppSnackBar.show(context,
              message: 'No connection. Check your internet and try again.',
              type: AppSnackBarType.error);
        default:
          AppSnackBar.show(context,
              message: 'Registration failed. Please try again.',
              type: AppSnackBarType.error);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Registration failed: $e');
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Registration failed. Please try again.',
            type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _persistCompanyProfile() {
    if (!_isCompany) return;
    // TODO(F2): persist company profile (company name, logo, business reg.
    // no, industry, address). Not stored anywhere yet.
  }

  void _finishRegistration() {
    AppSnackBar.show(context,
        message: 'Account created', type: AppSnackBarType.success);
    AppRoutes.pushReplacement(context, const OnboardingScreen());
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GemAppBar(
        title: _googleMode ? 'Complete your profile' : 'Register',
        leading: GemAppBarLeading.back,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.screen,
            AppSpacing.screen, AppSpacing.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withGaps([
            if (_googleMode) _buildGoogleBanner() else _buildGoogleEntry(),
            _buildAccountType(),
            ...(_isCompany ? _companyFields() : _individualFields()),
            if (!_googleMode) _buildLoginLink(),
          ]),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<Widget> _withGaps(List<Widget> children) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xxl),
        children[i],
      ],
    ];
  }

  Widget _buildGoogleBanner() {
    return CardContainer(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Image.asset('assets/images/google_logo.png',
                width: 20, height: 20),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signed in with Google', style: AppText.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text('Add a few details to finish setting up GemEye.',
                    style: AppText.secondary.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleSignInButton(
          isLoading: _isGoogleLoading,
          onPressed: _isLoading ? null : _signInWithGoogle,
        ),
        const OrDivider(
          label: 'or register with email',
          padding: EdgeInsets.only(top: AppSpacing.xl),
        ),
      ],
    );
  }

  Widget _buildAccountType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel(text: 'Account type'),
        const SizedBox(height: AppSpacing.md),
        SegmentedToggle<_AccountType>(
          selected: _accountType,
          onChanged: (type) => setState(() {
            _accountType = type;
            _submitted = false;
          }),
          options: const [
            SegmentOption(
                value: _AccountType.individual,
                label: 'Individual',
                icon: Icons.person_rounded),
            SegmentOption(
                value: _AccountType.company,
                label: 'Company',
                icon: Icons.business_rounded),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeading(String text, {bool divider = true}) {
    return Container(
      padding: EdgeInsets.only(top: divider ? AppSpacing.xxl : AppSpacing.xs),
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)))
          : null,
      child: Text(text, style: AppText.sectionHeader),
    );
  }

  Widget _nameField(String label) => InputField(
        label: label,
        labelSuffix: _requiredSuffix,
        controller: _nameController,
        hintText: 'e.g. Nimal Perera',
        locked: _googleMode,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        errorText: _nameError,
      );

  Widget _emailField(String label) => InputField(
        label: label,
        labelSuffix: _requiredSuffix,
        controller: _emailController,
        hintText: 'name@company.com',
        locked: _googleMode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        errorText: _emailError,
        onChanged: (_) => _serverEmailError = null,
      );

  Widget _passwordField() => PasswordField(
        labelSuffix: _requiredSuffix,
        controller: _passwordController,
        hintText: 'Create a password',
        rules: PasswordRule.registration,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        errorText: _passwordError,
      );

  Widget _phoneField(String label) => InputField(
        label: label,
        labelSuffix: _optionalSuffix,
        controller: _phoneController,
        hintText: '+94 77 123 4567',
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
      );

  Widget _countryField() => DropdownField<String>(
        label: 'Country',
        labelSuffix: _requiredSuffix,
        hintText: 'Select country',
        value: _selectedCountry,
        items: _countries,
        errorText: _requiredChoice(_selectedCountry),
        onChanged: (value) => setState(() => _selectedCountry = value),
      );

  List<Widget> _individualFields() {
    return [
      ImagePickerField(
        label: 'Profile photo',
        image: _profilePhoto,
        initialLetter: _nameController.text,
        onChanged: (file) => setState(() => _profilePhoto = file),
      ),
      _nameField('Full Name'),
      _emailField('Email'),
      if (!_googleMode) _passwordField(),
      _phoneField('Phone'),
      _countryField(),
      DropdownField<String>(
        label: 'Role',
        labelSuffix: _requiredSuffix,
        hintText: 'Select role',
        value: _selectedRole,
        items: _roles,
        errorText: _requiredChoice(_selectedRole),
        onChanged: (value) => setState(() => _selectedRole = value),
      ),
    ];
  }

  List<Widget> _companyFields() {
    return [
      _sectionHeading('Company details', divider: false),
      InputField(
        label: 'Company Name',
        labelSuffix: _requiredSuffix,
        controller: _companyNameController,
        hintText: 'e.g. Ceylon Gem Exports',
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        errorText: _companyNameError,
      ),
      ImagePickerField(
        label: 'Company Logo',
        shape: ImagePickerShape.roundedSquare,
        image: _companyLogo,
        pickLabel: 'Upload logo',
        pickIcon: Icons.upload_rounded,
        onChanged: (file) => setState(() => _companyLogo = file),
      ),
      InputField(
        label: 'Business Reg. No',
        labelSuffix: _optionalSuffix,
        controller: _businessRegController,
        hintText: 'e.g. PV 00123456',
        textInputAction: TextInputAction.next,
      ),
      _countryField(),
      DropdownField<String>(
        label: 'Industry',
        labelSuffix: _requiredSuffix,
        hintText: 'Select industry',
        value: _selectedIndustry,
        items: _industries,
        errorText: _requiredChoice(_selectedIndustry),
        onChanged: (value) => setState(() => _selectedIndustry = value),
      ),
      _sectionHeading('Contact person'),
      _nameField('Contact Name'),
      _emailField('Contact Email'),
      if (!_googleMode) _passwordField(),
      _phoneField('Contact Phone'),
      InputField(
        label: 'Address',
        labelSuffix: _optionalSuffix,
        controller: _addressController,
        hintText: 'Street, city, postcode',
        maxLines: 3,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.words,
      ),
    ];
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?',
            style: AppText.body14.copyWith(color: AppColors.textSecondary)),
        TextLinkButton(
          label: 'Log In',
          onPressed: () => AppRoutes.pop(context),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
              AppSpacing.screen, AppSpacing.xxxl),
          child: PrimaryButton(
            label: 'Create Account',
            loadingLabel: 'Creating account…',
            isLoading: _isLoading,
            onPressed: _isGoogleLoading ? null : _submit,
          ),
        ),
      ),
    );
  }
}
