import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;

class ActivationService {
  static const String _pepper = "YOUR_SUPER_SECRET_PEPPER_HERE_12345";

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
    final fingerprint = await generateDeviceFingerprint(phoneNumber);
    final combinedString = '$fingerprint$_pepper';

    final bytes = utf8.encode(combinedString);
    final digest = sha256.convert(bytes);
    final finalHash = digest.toString();
    print(finalHash.substring(0, 12).toUpperCase());
    return finalHash.substring(0, 12).toUpperCase() == activationCode.toUpperCase();
  }
}