import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:anatomy_quiz_app/core/utils/secure_storage_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';

class ActivationService {
  
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  ActivationService(this._apiService, this._secureStorage);

  // This is the one-time online activation step.
  Future<void> fetchAndStorePepper({
    required String phoneNumber,
    required String fingerprint,
  }) async {

    // Call the API to get the user's unique pepper.
    final secrets = await _apiService.getSecrets(
      phoneNumber: phoneNumber,
      fingerprint: fingerprint,
    );
    // Save it to the device's secure "safe".
    await _secureStorage.saveSecretPepper(secrets['pepper']!);
    await _secureStorage.saveDbKey(secrets['db_key']!); 
  
  }

  Future<String> _getAppUUID() async {
    final prefs = await SharedPreferences.getInstance();
    String? appUUID = prefs.getString('appUUID');
    if (appUUID == null) {
      appUUID = const Uuid().v4();
      await prefs.setString('appUUID', appUUID);
    }
    return appUUID;
  }

  Future<String> _getDeviceID() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique per device
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_device'; // Unique per app install
    }
    return 'unknown_device';
  }

  Future<String> generateDeviceFingerprint(String phoneNumber) async {
    final appUUID = await _getAppUUID();
    final deviceID = await _getDeviceID();
    
    final combinedString = '$appUUID:$deviceID:$phoneNumber';
    final bytes = utf8.encode(combinedString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  Future<bool> verifyActivationCode({
    required String phoneNumber,
    required String activationCode,
  }) async {
    // 1. Fetch the user's unique secret pepper from the secure "safe".
    final secretPepper = await _secureStorage.getSecretPepper();
    if (secretPepper == null) {
      // If no pepper is stored, verification is impossible.
      return false;
    }

    // 2. Generate the expected code using the fetched pepper and a fresh fingerprint.
    final fingerprint = await generateDeviceFingerprint(phoneNumber);
    final combinedString = '$fingerprint$secretPepper';
    final bytes = utf8.encode(combinedString);
    final digest = sha256.convert(bytes);
    final expectedCode = digest.toString().substring(0, 12).toUpperCase();

    // 3. Compare with the code the user entered (which is saved in SharedPreferences).
    return expectedCode == activationCode.toUpperCase();
  }
}

