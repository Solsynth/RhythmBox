import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/services/kv_store/kv_store.dart';
import 'package:uuid/uuid.dart';

abstract class EncryptedKvStoreService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static FlutterSecureStorage get storage => _storage;

  static String? _encryptionKeySync;

  static Future<void> initialize() async {
    _encryptionKeySync = await encryptionKey;
  }

  static String get encryptionKeySync => _encryptionKeySync!;

  static bool get isUnsupportedPlatform =>
      PlatformInfo.isMacOS ||
      PlatformInfo.isIOS ||
      (PlatformInfo.isLinux && !PlatformInfo.isInFlatpak);

  static Future<String> get encryptionKey async {
    if (isUnsupportedPlatform) {
      return KVStoreService.encryptionKey;
    }
    try {
      final value = await _storage.read(key: 'encryption');
      final key = const Uuid().v4();

      if (value == null) {
        await setEncryptionKey(key);
        return key;
      }

      return value;
    } catch (e) {
      return KVStoreService.encryptionKey;
    }
  }

  static Future<void> setEncryptionKey(String key) async {
    if (isUnsupportedPlatform) {
      await KVStoreService.setEncryptionKey(key);
      return;
    }

    try {
      await _storage.write(key: 'encryption', value: key);
    } catch (e) {
      await KVStoreService.setEncryptionKey(key);
    } finally {
      _encryptionKeySync = key;
    }
  }
}
