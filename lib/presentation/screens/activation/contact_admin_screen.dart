import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

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
  final String _backupContactNumber = "+963959267289";

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
    else if (e is ApiTimeoutException) {
    errorMessage = e.toString();
    } 
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
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.05, // Make it very subtle
              child: Image.asset(
                'assets/images/loading_logo.png', // The path to your logo
                width: 500.r,
                height: 500.r,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Center(
              child: _buildBody(),
            ),
          ),
        ]
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
    
    String message =
        'الاسم: $_userName\n'
        'الجنس: $_gender\n'
        'رقم الهاتف: $_phoneNumber\n\n\n';

    if (_promoCode.isNotEmpty) {
      message += '\nالرمز الترويجي: $_promoCode';
    }
    message += '\nرمز الجهاز: $_fingerprint';
    message += '\n\n\n\n\n اضغط زر الإرسال لإتمام عملية الدفع والحصول على رمز التفعيل\n\n';

  return Column(
    children: [
      // --- Top Section: Fixed Header ---
      Text(
        'للحصول على كود التفعيل، أرسل الرسالة التالية:',
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 20.h),
      
      // --- Middle Section: Scrollable Message ---
      Expanded(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.r)
            ),
            child: Text(
              message,
              style: TextStyle(fontSize: 16.sp, height: 1.5),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
      // --- Bottom Section: Fixed Buttons ---
      const Divider(thickness: 1, height: 20),
      // Use a SingleChildScrollView here in case the buttons overflow on very small screens
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('نسخ الرسالة'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرسالة بنجاح')));
              },
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () => _launchUrl(Uri.parse('https://wa.me/$_contactNumber?text=${Uri.encodeComponent(message)}')),
              child: const Text('إرسال عبر واتساب'),
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
  onPressed: () async {
    // 1. Copy the message to the clipboard.
    await Clipboard.setData(ClipboardData(text: message));

    // 2. Show the custom, stylish SnackBar FIRST.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3), // Slightly longer duration
          backgroundColor: AppColors.primary, // Use your app's primary color
          behavior: SnackBarBehavior.floating, // Make it a floating rectangle
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)), // Rounded corners
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w), // More padding
          content: Row(
            children: [
              Icon(Icons.copy, color: AppColors.primary, size: 24.sp), // Icon for attention
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'تم نسخ الرسالة! الرجاء لصقها في محادثة تيليجرام. .. انتظر قليلا',
                  style: TextStyle(
                    color: AppColors.surface, // Text color that contrasts with background
                    fontSize: 16.sp, // Slightly larger font size
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Wait for 2 seconds (or 3, matching snackbar duration) so the user can read the message.
    await Future.delayed(const Duration(seconds: 3)); // Match the SnackBar duration

    // 4. Launch the Telegram app.
    _launchUrl(Uri.parse('https://t.me/$_contactNumber'));
  },
  child: const Text('إرسال عبر تيليجرام'),
),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: () => _launchUrl(Uri.parse('sms:$_contactNumber?body=${Uri.encodeComponent(message)}')),
              // ## THE FIX: The child is now a Column ##
              child: Column(
                children: [
                  // Main button text
                  const Text('إرسال عبر رسالة نصية'),
                  // Smaller disclaimer text
                  Text(
                    '(قد يتم تطبيق رسوم الرسائل النصية القياسية)',
                    style: TextStyle(
                      fontSize: 10.sp, // Make it smaller
                      fontWeight: FontWeight.normal, // Make it less bold
                      color: Colors.white70, // Make it slightly transparent
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                shape: const StadiumBorder(), // Pill shape
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              onPressed: () => context.push('/activate'),
              icon: const Icon(Icons.key_rounded, size: 20), // Your key icon
              label: Text(
                'لدي كود بالفعل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
          ],
        ),
      ),
    ],
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