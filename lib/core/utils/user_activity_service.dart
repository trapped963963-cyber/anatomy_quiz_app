import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserActivityService {
  final ApiService _apiService;
  final ActivationService _activationService;

  UserActivityService(this._apiService, this._activationService);

  Future<void> triggerActivityPing() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPingString = prefs.getString('last_activity_ping');

    if (lastPingString == null) {
      await _sendPing(prefs);
      return;
    }

    final lastPingDate = DateTime.parse(lastPingString);
    if (DateTime.now().difference(lastPingDate).inDays >= 30) {
      await _sendPing(prefs);
    }
  }

  Future<void> _sendPing(SharedPreferences prefs) async {
    final phoneNumber = prefs.getString('phoneNumberForValidation');
    if (phoneNumber == null) return;


    try {
      await _apiService.pingActivity(phoneNumber: phoneNumber);
      await prefs.setString('last_activity_ping', DateTime.now().toIso8601String());
    } catch (e) {
      ;
    }
  }
}