import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/activation_code_input.dart';


class ActivationCodeScreen extends ConsumerStatefulWidget {
  const ActivationCodeScreen({super.key});

  @override
  ConsumerState<ActivationCodeScreen> createState() => _ActivationCodeScreenState();
}

class _ActivationCodeScreenState extends ConsumerState<ActivationCodeScreen> {
  String _activationCode = '';
  bool _isFilled = false;
  bool _isLoading = false;
  String? _errorText;

  Future<void> _activateApp() async {
    if (!_isFilled) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final activationService = ref.read(activationServiceProvider);
    final onboardingState = ref.read(onboardingProvider);
    final userNotifier = ref.read(userProgressProvider.notifier);

    final isValid = await activationService.verifyActivationCode(
      phoneNumber: onboardingState.phoneNumber,
      activationCode: _activationCode,
    );

    if (isValid) {
      // Save activation code
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activationCode', _activationCode);
      
      // Save user name
      await userNotifier.setUserName(onboardingState.name);
      
      // Save user phone      
      await prefs.setString('phoneNumberForValidation', onboardingState.phoneNumber);
      // Navigate to home, replacing the entire activation stack
      context.go('/home');

    } else {
      setState(() {
        _errorText = 'كود التفعيل غير صحيح. الرجاء المحاولة مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 5 من 5')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أدخل كود التفعيل',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            ActivationCodeInput(
              onCompleted: (code) {
                setState(() {
                  _activationCode = code;
                  _isFilled = true;
                });
              },
            ),
             if (_errorText != null) ...[
              SizedBox(height: 10.h),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              )
            ],
            SizedBox(height: 30.h),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _isFilled ? _activateApp : null,
                    child: const Text('تفعيل التطبيق'),
                  ),
            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}