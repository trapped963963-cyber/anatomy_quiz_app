import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveSecretPepper(String pepper) async {
    await _storage.write(key: 'secret_pepper', value: pepper);
  }

  Future<String?> getSecretPepper() async {
    return await _storage.read(key: 'secret_pepper');
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}