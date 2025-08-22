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
  final String message = 'حدث خطأ أثناء الاتصال بالخادم. الرجاء المحاولة مرة أخرى.';

  @override
  String toString() => message;
}

class ApiService {
  // Replace this with your actual Vercel deployment URL
  final String _apiUrl =
      'https://anatomy-api.vercel.app/api/get-contact-info';
  Future<String> getContactNumber() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10)); // Add a timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['contact_number'];
      } else {
        // This is a server-side API problem (e.g., 404, 500).
        throw ApiException();
      }
    } on SocketException {
      // This happens when there's no internet.
      throw NoInternetException();
    } on TimeoutException {
      // This also indicates a network problem.
      throw NoInternetException();
    } catch (e) {
      // For any other unexpected error, we'll treat it as an API problem.
      throw ApiException();
    }
  }
}
