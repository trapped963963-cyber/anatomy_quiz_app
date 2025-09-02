import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

// A custom exception for when the user has no internet connection.
class NoInternetException implements Exception {
  final String message = 'لا يوجد اتصال بالإنترنت. الرجاء التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  String toString() => message;
}

// A custom exception for when our API server has a problem.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}


class ApiService {

  final String _baseUrl = 'https://anatomy-api-v2.vercel.app/api';
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
      return response;
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException();
    } catch (e) {
      throw ApiException('An unexpected error occurred.');
    }
  }

  /// 2. Fetches the unique secret pepper for a user during activation.
  Future<Map<String, String>> getSecrets({
    required String phoneNumber,
    required String fingerprint,
  }) async {
    final response = await _post('activations/get-pepper', {
      'phone_number': phoneNumber,
      'device_fingerprint': fingerprint,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
        return {
          'pepper': data['secret_pepper'],
          'db_key': data['db_key'],
        };
    } else {
      // Create a more specific error message if the server provides one
      final errorDetail = json.decode(response.body)['detail'] ?? 'Failed to get activation secret.';
      throw ApiException(errorDetail);
    }
  }


  // The method now only needs the phone number
  Future<void> pingActivity({required String phoneNumber}) async {
    try {
      await _post('users/ping', {'phone_number': phoneNumber});
    } catch (e) {
      print('Activity ping failed: $e');
    }
  }
  Future<String> getContactNumber() async {
    try {
      // Construct the full URL by combining the base URL and the endpoint
      final response = await http.get(Uri.parse('$_baseUrl/get-contact-info'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['contact_number'];
      } else {
        // ## FIX 2: Add a specific error message ##
        throw ApiException('Failed to load contact number. Status code: ${response.statusCode}');
      }
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException();
    } catch (e) {
      // If it's not one of our custom exceptions, re-throw it as a generic API exception
      if (e is ApiException || e is NoInternetException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }
}
