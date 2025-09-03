import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';

class ContactAdminScreen extends ConsumerStatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  ConsumerState<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends ConsumerState<ContactAdminScreen> {
  bool _isLoading = true;
  String? _contactNumber;
  String? _fingerprint;
  String? _lastError;
  int _apiFailedAttempts = 0;
  final String _backupContactNumber = "+963997564200";

  // ## NEW: State variables to hold the user's data from SharedPreferences ##
  String _userName = '';
  String _gender = '';
  String _phoneNumber = '';
  String _promoCode = '';

  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchContactDetails();
    });
  }

  Future<void> _fetchContactDetails() async {

  if (!_isLoading) {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });
  }

  try {

    final prefs = await SharedPreferences.getInstance();
    final apiService = ref.read(apiServiceProvider);
    final activationService = ref.read(activationServiceProvider);

    // Load user data from SharedPreferences
    final phone = prefs.getString('onboarding_phone') ?? '';
    final name = prefs.getString('onboarding_name') ?? '';
    final gender = prefs.getString('onboarding_gender') == 'male' ? 'ذكر' : 'أنثى';
    final promo = prefs.getString('onboarding_promo_code') ?? '';
      

    final results = await Future.wait([
      apiService.getContactNumber(),
      activationService.generateDeviceFingerprint(phone),
    ]);

    if (mounted) {
      setState(() {
        _userName = name;
        _gender = gender;
        _phoneNumber = phone;
        _promoCode = promo;
        _contactNumber = results[0];
        _fingerprint = results[1];
        _isLoading = false;
        _apiFailedAttempts = 0;
      });
    }
  } catch (e) {
    if (!mounted) return;

    int currentFailCount = _apiFailedAttempts;
    String errorMessage;

    if (e is NoInternetException) {
      errorMessage = e.toString();
    } 
    // ## NEW: Catching the specific Device ID error ##
    else if (e is PlatformException) {
      currentFailCount++;
      errorMessage = 'حدث خطأ في قراءة بيانات الجهاز. الرجاء المحاولة مرة أخرى.';
      // For your report, you might want the technical detail.
      // You could also store e.toString() in another variable for the report.
    }
    else { // Handles ApiException and any other generic error
      currentFailCount++;
      errorMessage = e is ApiException ? e.toString() : 'An unexpected error occurred.';
    }

    setState(() {
      _apiFailedAttempts = currentFailCount;
      _lastError = errorMessage;
      _isLoading = false;
    });

    if (_apiFailedAttempts >= 10) {
      _reportProblemToAdmin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال تقرير بالمشكلة لفريق الدعم.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}


  // ## NEW: A dedicated method for the "Try Again" button ##
  void _retryFetch() {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });
    // Call the original fetch method to re-run the API call
    _fetchContactDetails();
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح هذا التطبيق')),
        );
      }
    }
  }
  
  void _reportProblemToAdmin() async {
    
    String activationMessage = 'أرغب في تفعيل التطبيق.\n'
        'الاسم: $_userName\n'
        'الجنس: $_gender\n'
        'رقم الهاتف: $_phoneNumber';
    
    if (_promoCode.isNotEmpty) {
      activationMessage += '\nالرمز الترويجي: $_promoCode';
    }
    
    activationMessage += '\nرمز الجهاز: $_fingerprint';


    final reportMessage = "--- User Report ---\nError: $_lastError\n\n--- Original Request ---\n$activationMessage";
    final reportUrl = 'https://wa.me/$_backupContactNumber?text=${Uri.encodeComponent(reportMessage)}';
    _launchUrl(Uri.parse(reportUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 4 من 5')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Center(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingIndicator();
    }
    if (_lastError != null) {
      return _buildErrorState();
    }
    if (_contactNumber != null && _fingerprint != null) {
      return _buildSuccessState();
    }
    // Fallback in case of an unexpected state
    return _buildErrorState();
  }

  Widget _buildSuccessState() {
    
    String message = 'أرغب في تفعيل التطبيق.\n'
        'الاسم: $_userName\n'
        'الجنس: $_gender\n'
        'رقم الهاتف: $_phoneNumber';

    if (_promoCode.isNotEmpty) {
      message += '\nالرمز الترويجي: $_promoCode';
    }
    message += '\nرمز الجهاز: $_fingerprint';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('للحصول على كود التفعيل، أرسل الرسالة التالية:', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8.r)),
            child: Text(message, style: TextStyle(fontSize: 16.sp, height: 1.5), textAlign: TextAlign.right),
          ),
          SizedBox(height: 10.h),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ الرسالة'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرسالة بنجاح')));
            },
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => _launchUrl(Uri.parse('https://wa.me/$_contactNumber?text=${Uri.encodeComponent(message)}')),
            child: const Text('إرسال عبر واتساب'),
          ),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: () async { // Make the function async
            // 1. Copy the message to the clipboard.
            await Clipboard.setData(ClipboardData(text: message));

            // 2. Show the confirmation message FIRST.
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 2), // Make sure it's visible
                  content: Text('تم نسخ الرسالة! الرجاء لصقها في محادثة تيليجرام.'),
                ),
              );
            }

            // 3. Wait for a moment so the user can read the message.
            await Future.delayed(const Duration(seconds: 2));

            // 4. Launch the Telegram app.
            // !!! IMPORTANT: Remember to replace 'YourAdminUsername'
            _launchUrl(Uri.parse('https://t.me/YourAdminUsername'));
          },
            child: const Text('إرسال عبر تيليجرام'),
          ),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: () => _launchUrl(Uri.parse('sms:$_contactNumber?body=${Uri.encodeComponent(message)}')),
            child: const Text('إرسال عبر رسالة نصية'),
          ),
          SizedBox(height: 20.h),
          OutlinedButton(
            onPressed: () => context.push('/activate'),
            child: const Text('لدي كود بالفعل'),
          ),
          TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_lastError ?? 'An unknown error occurred.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16.sp)),
        SizedBox(height: 20.h),
        ElevatedButton(onPressed: _retryFetch, child: const Text('حاول مرة أخرى')),
        if (_apiFailedAttempts >= 2)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: TextButton(
              child: const Text('إبلاغ المسؤول بالمشكلة'),
              onPressed: _reportProblemToAdmin,
            ),
          ),
        TextButton(
          child: const Text('لدي كود بالفعل'),
          onPressed: () {
            context.push('/activate');
          },
        ),
      ],
    );
  }
}