import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveSecretPepper(String pepper) async {
    await _storage.write(key: 'secret_pepper', value: pepper);
  }

  Future<String?> getSecretPepper() async {
    return await _storage.read(key: 'secret_pepper');
  }

  // --- ## NEW: Database Key Methods ## ---
  Future<void> saveDbKey(String dbKey) async {
    await _storage.write(key: 'db_key', value: dbKey);
  }

  Future<String?> getDbKey() async {
    return await _storage.read(key: 'db_key');
  }
  
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}