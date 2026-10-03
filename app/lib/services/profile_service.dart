import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccountType { individual, company }

/// Profile details kept on this device. Name and email live in Firebase
/// Auth; everything else is stored here until the backend exists.
// TODO(F2): sync the profile (and company details) with the backend.
class LocalProfile {
  final AccountType accountType;
  final String phone;
  final String? role;
  final String? country;
  final String companyName;
  final String contactPerson;
  final String? industry;
  final String? photoPath;
  final String? logoPath;

  const LocalProfile({
    this.accountType = AccountType.individual,
    this.phone = '',
    this.role,
    this.country,
    this.companyName = '',
    this.contactPerson = '',
    this.industry,
    this.photoPath,
    this.logoPath,
  });

  bool get isCompany => accountType == AccountType.company;

  LocalProfile copyWith({
    AccountType? accountType,
    String? phone,
    String? role,
    String? country,
    String? companyName,
    String? contactPerson,
    String? industry,
    String? photoPath,
    String? logoPath,
    bool clearPhoto = false,
    bool clearLogo = false,
  }) =>
      LocalProfile(
        accountType: accountType ?? this.accountType,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        country: country ?? this.country,
        companyName: companyName ?? this.companyName,
        contactPerson: contactPerson ?? this.contactPerson,
        industry: industry ?? this.industry,
        photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
        logoPath: clearLogo ? null : logoPath ?? this.logoPath,
      );

  Map<String, dynamic> toJson() => {
        'accountType': accountType.name,
        'phone': phone,
        'role': role,
        'country': country,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'industry': industry,
        'photoPath': photoPath,
        'logoPath': logoPath,
      };

  factory LocalProfile.fromJson(Map<String, dynamic> j) => LocalProfile(
        accountType: j['accountType'] == AccountType.company.name
            ? AccountType.company
            : AccountType.individual,
        phone: j['phone'] as String? ?? '',
        role: j['role'] as String?,
        country: j['country'] as String?,
        companyName: j['companyName'] as String? ?? '',
        contactPerson: j['contactPerson'] as String? ?? '',
        industry: j['industry'] as String?,
        photoPath: j['photoPath'] as String?,
        logoPath: j['logoPath'] as String?,
      );
}

/// Local profile store (flutter_secure_storage: phone and company details
/// are personal data).
class ProfileService {
  ProfileService._();

  static const String _key = 'profile_v1';

  static const List<String> countries = [
    'Sri Lanka',
    'India',
    'Thailand',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Other',
  ];
  static const List<String> roles = [
    'Gemologist',
    'Trader',
    'Exporter',
    'Student',
    'Other',
  ];
  static const List<String> industries = [
    'Gem Trading',
    'Gem Export',
    'Jewellery',
    'Laboratory',
    'Other',
  ];

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<LocalProfile> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null) {
        return LocalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      // Migrate values the old Profile screen kept in SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final legacy = LocalProfile(
        phone: prefs.getString('profile_phone') ?? '',
        companyName: prefs.getString('company_name') ?? '',
        role: prefs.getString('profile_designation'),
      );
      await save(legacy);
      for (final k in ['profile_phone', 'company_name', 'profile_designation']) {
        await prefs.remove(k);
      }
      return legacy;
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService.load failed: $e');
      return const LocalProfile();
    }
  }

  static Future<void> save(LocalProfile p) async {
    await _storage.write(key: _key, value: jsonEncode(p.toJson()));
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService.clear failed: $e');
    }
  }

  /// Copies a picked image into app storage so it survives cache clears.
  /// Returns the stored path.
  static Future<String> storeImage(File file, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = file.path.split('.').last.toLowerCase();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final target = File('${dir.path}/profile_${name}_$stamp.$ext');
    await file.copy(target.path);
    return target.path;
  }
}
