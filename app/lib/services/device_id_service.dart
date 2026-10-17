import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Random per-install device id (UUID v4), created on first launch and kept in
/// secure storage. Sent as the X-Device-Id header on every API call so the
/// server can block one phone without blocking every phone of the same model.
class DeviceIdService {
  DeviceIdService._();

  static const String _key = 'device_install_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final RegExp _uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  static String? _id;

  /// The loaded id, or null before [init] finished.
  static String? get current => _id;

  /// Loads the stored id, or creates and stores a new one (main.dart, once).
  static Future<String> init() async {
    final cached = _id;
    if (cached != null) return cached;
    String? id;
    try {
      id = await _storage.read(key: _key);
    } catch (e) {
      if (kDebugMode) debugPrint('Device id not read: $e');
    }
    if (id == null || !_uuidV4.hasMatch(id)) {
      id = const Uuid().v4();
      try {
        await _storage.write(key: _key, value: id);
      } catch (e) {
        if (kDebugMode) debugPrint('Device id not saved: $e');
      }
    }
    return _id = id;
  }

  /// Forgets the in-memory id (tests).
  @visibleForTesting
  static void resetForTest() => _id = null;
}
