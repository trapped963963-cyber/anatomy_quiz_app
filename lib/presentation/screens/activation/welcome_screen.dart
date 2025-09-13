import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

   // ## NEW: Helper method to launch URLs ##
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      // Handle error if the URL can't be launched
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          // ## THE FIX: Use a Stack to layer the logo and the content ##
          child: Stack(
            children: [
              // --- 1. The Background Watermark ---
              Center(
                child: Opacity(
                  opacity: 0.1, // Make it very subtle
                  child: Image.asset(
                    'assets/images/loading_logo.png', // The path to your logo
                    width: 500.r,
                    height: 500.r,
                  ),
                ),
              ),
              // --- 2. The Foreground Content ---
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أهلاً بك في علوم لايت',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'استعد لرحلة ممتعة لتعلم وحفظ جميع رسمات العلوم.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 60.h),
                    ElevatedButton(
                      onPressed: () => context.push('/name'),
                      child: const Text('ابدأ الآن'),
                    ),
                  ],
                ),
              ),
                            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.telegram, color: Colors.blue, size: 30.r),
                        onPressed: () {
                          // IMPORTANT: Replace with your actual Telegram channel link
                          _launchUrl('https://t.me/OlomLight');
                        },
                      ),
                      SizedBox(width: 20.w),
                      IconButton(
                        icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 30.r),
                        onPressed: () {
                          // IMPORTANT: Replace with your actual WhatsApp channel link
                          _launchUrl('https://whatsapp.com/channel/0029VbBRzaSKwqSYbvU3rc3V');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}