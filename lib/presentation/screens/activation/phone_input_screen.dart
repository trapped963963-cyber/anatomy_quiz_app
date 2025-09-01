import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/phone_number_input.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  String _phoneNumber = '';
  bool _isComplete = false;

  void _onNext() {
    if (_isComplete) {
      ref.read(onboardingProvider.notifier).setPhoneNumber(_phoneNumber);
      context.push('/promo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 2 من 5')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: LayoutBuilder(  
          builder: (context, constraints) {
            return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight,),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'أدخل رقم هاتفك',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),
                  PhoneNumberInput(
                    onValueChanged: (value) {
                      // This runs on every key press.
                      setState(() {
                        _phoneNumber = value;
                        // The button is only enabled if the length is exactly 10.
                        _isComplete = value.length == 10;
                      });
                    },
                    onCompleted: (number) {
                      // This now runs only once at the end. We can use it for
                      // specific actions like hiding the keyboard, but the main
                      // logic is now in onValueChanged. For now, we can leave it empty.
                    },
                  ),
                  SizedBox(height: 30.h),
                  ElevatedButton(
                    onPressed: _isComplete ? _onNext : null,
                    child: const Text('التالي'),
                  ),
                  TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}