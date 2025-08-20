import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop,dynamic result) {
      if (!didPop) {
        SystemNavigator.pop();
      }
    },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'أهلاً بك في تحدي التشريح!',
                  style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Text(
                  'استعد لرحلة ممتعة لتعلم وحفظ أدق تفاصيل علم التشريح.',
                  style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50.h),
                ElevatedButton(
                  onPressed: () => context.push('/name'),
                  child: const Text('لنبدأ!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}