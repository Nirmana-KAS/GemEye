import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/history_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/gem_app_bar.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/input_field.dart';
import 'change_email_screen.dart';

/// Profile (20a individual / 20b company). Name lives in Firebase Auth;
/// the rest is kept on this device by [ProfileService].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();

  LocalProfile _saved = const LocalProfile();
  String _savedName = '';
  String? _role;
  String? _country;
  String? _industry;
  File? _newPhoto;
  File? _logo;
  bool _logoChanged = false;
  bool _loaded = false;
  bool _saving = false;

  int _total = 0;
  int _referred = 0;
  int _certificates = 0;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameController, _companyController, _phoneController]) {
      c.addListener(_refresh);
    }
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    try {
      final profile = await ProfileService.load();
      final history = await HistoryService.load();
      if (!mounted) return;
      setState(() {
        _saved = profile;
        _savedName = _auth.currentUser?.displayName ?? '';
        _nameController.text = _savedName;
        _companyController.text = profile.companyName;
        _phoneController.text = profile.phone;
        _role = profile.role;
        _country = profile.country;
        _industry = profile.industry;
        _logo = profile.logoPath == null ? null : File(profile.logoPath!);
        _total = history.length;
        _referred =
            history.where((r) => r.isReferred).length;
        _certificates =
            history.where((r) => r.certificateNumber != null).length;
        _loaded = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Profile load failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  bool get _isCompany => _saved.isCompany;

  bool get _dirty =>
      _nameController.text.trim() != _savedName ||
      _companyController.text.trim() != _saved.companyName ||
      _phoneController.text.trim() != _saved.phone ||
      _role != _saved.role ||
      _country != _saved.country ||
      _industry != _saved.industry ||
      _newPhoto != null ||
      _logoChanged;

  Future<void> _pickPhoto() async {
    final file = await ImagePickerField.pickImage(context);
    if (file != null && mounted) setState(() => _newPhoto = file);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      if (name.isNotEmpty && name != _savedName) {
        await _auth.updateDisplayName(name);
      }
      var profile = _saved.copyWith(
        companyName: _companyController.text.trim(),
        contactPerson: _isCompany ? name : _saved.contactPerson,
        phone: _phoneController.text.trim(),
        role: _role,
        country: _country,
        industry: _industry,
      );
      if (_newPhoto != null) {
        profile = profile.copyWith(
            photoPath: await ProfileService.storeImage(_newPhoto!, 'photo'));
      }
      if (_logoChanged) {
        profile = _logo == null
            ? profile.copyWith(clearLogo: true)
            : profile.copyWith(
                logoPath: await ProfileService.storeImage(_logo!, 'logo'));
      }
      // TODO(F2): sync the profile and company details with the backend.
      await ProfileService.save(profile);
      if (!mounted) return;
      setState(() {
        _saved = profile;
        _savedName = name.isNotEmpty ? name : _savedName;
        _newPhoto = null;
        _logoChanged = false;
      });
      AppSnackBar.show(context,
          message: 'Profile saved',
          type: AppSnackBarType.success,
          actionLabel: 'OK',
          onAction: () {});
    } catch (e) {
      if (kDebugMode) debugPrint('Profile save failed: $e');
      if (AuthService.handleSessionError(e) || !mounted) return;
      AppSnackBar.show(context,
          message: 'Could not save your profile. Try again.',
          type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _displayName {
    if (_isCompany && _companyController.text.trim().isNotEmpty) {
      return _companyController.text.trim();
    }
    final n = _nameController.text.trim();
    return n.isEmpty ? (_auth.currentUser?.email ?? 'User') : n;
  }

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(w[0]))
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GemAppBar(title: 'Profile', leading: GemAppBarLeading.back),
      body: SafeArea(
        top: false,
        child: !_loaded
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                          AppSpacing.xxxl, AppSpacing.xl, AppSpacing.xl),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildStats(),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isCompany) ...[
                          ImagePickerField(
                            label: 'Company Logo',
                            shape: ImagePickerShape.roundedSquare,
                            image: _logo,
                            pickLabel: 'Replace',
                            pickIcon: Icons.upload_rounded,
                            onChanged: (f) => setState(() {
                              _logo = f;
                              _logoChanged = true;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        ..._buildFields(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: PrimaryButton(
                      label: 'Save changes',
                      isLoading: _saving,
                      onPressed: _dirty ? _save : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final radius = _isCompany ? 24.0 : 48.0;
    final photoUrl = _auth.currentUser?.photoURL;
    final localPath = _saved.photoPath;
    ImageProvider? image;
    if (_newPhoto != null) {
      image = FileImage(_newPhoto!);
    } else if (localPath != null && File(localPath).existsSync()) {
      image = FileImage(File(localPath));
    } else if (photoUrl != null) {
      image = NetworkImage(photoUrl);
    }

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change photo',
          child: GestureDetector(
            onTap: _pickPhoto,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(radius),
                      image: image == null
                          ? null
                          : DecorationImage(image: image, fit: BoxFit.cover),
                    ),
                    child: image == null
                        ? Text(_initials,
                            style: AppText.screenTitle.copyWith(
                                fontSize: 32, color: AppColors.onPrimary))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.background, width: 3),
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          size: 16, color: AppColors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(_displayName,
            textAlign: TextAlign.center, style: AppText.screenTitle),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isCompany ? Icons.business_rounded : Icons.person_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(_isCompany ? 'Company' : 'Individual',
                  style: AppText.titleSmall
                      .copyWith(fontSize: 11, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    Widget stat(String value, String label, Color colour) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: colour)),
                const SizedBox(height: AppSpacing.xs),
                Text(label,
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat('$_total', 'Total graded', AppColors.textPrimary),
        const SizedBox(width: AppSpacing.md),
        stat('$_referred', 'Referred', AppColors.warningText),
        const SizedBox(width: AppSpacing.md),
        stat('$_certificates', 'Certificates', AppColors.textPrimary),
      ],
    );
  }

  List<Widget> _buildFields() {
    const gap = SizedBox(height: AppSpacing.xl);
    final email = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: FieldLabel(text: 'Email')),
            TextLinkButton(
              label: 'Change',
              onPressed: () => ChangeEmailScreen.open(context),
            ),
          ],
        ),
        LockedValue(value: _auth.currentUser?.email ?? '-'),
      ],
    );
    final phone = InputField(
      label: 'Phone',
      controller: _phoneController,
      hintText: '+94 77 123 4567',
      keyboardType: TextInputType.phone,
    );
    final country = DropdownField<String>(
      label: 'Country',
      items: ProfileService.countries,
      value: _country,
      onChanged: (v) => setState(() => _country = v),
    );

    if (_isCompany) {
      return [
        InputField(label: 'Company name', controller: _companyController),
        gap,
        InputField(label: 'Contact person', controller: _nameController),
        gap,
        email,
        gap,
        phone,
        gap,
        DropdownField<String>(
          label: 'Industry',
          items: ProfileService.industries,
          value: _industry,
          onChanged: (v) => setState(() => _industry = v),
        ),
        gap,
        country,
      ];
    }
    return [
      InputField(label: 'Full name', controller: _nameController),
      gap,
      email,
      gap,
      phone,
      gap,
      DropdownField<String>(
        label: 'Role',
        items: ProfileService.roles,
        value: _role,
        onChanged: (v) => setState(() => _role = v),
      ),
      gap,
      country,
    ];
  }
}
