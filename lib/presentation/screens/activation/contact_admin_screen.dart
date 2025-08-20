import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ContactAdminScreen extends ConsumerWidget {
  const ContactAdminScreen({super.key});

  Future<void> _launchUrl(Uri url, BuildContext context) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح هذا التطبيق')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final activationService = ref.watch(activationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 4 من 5')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: FutureBuilder<String>(
          future: activationService.generateDeviceFingerprint(onboardingState.phoneNumber),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final fingerprint = snapshot.data!;
            final message = 'أرغب في تفعيل التطبيق.\nالاسم: ${onboardingState.name}\nرقم الهاتف: ${onboardingState.phoneNumber}\nرمز الجهاز: $fingerprint';
            
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تواصل مع المسؤول للحصول على كود التفعيل',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(fontSize: 16.sp, height: 1.5),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ الرسالة'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الرسالة بنجاح')),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => _launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}'), context),
                    child: const Text('إرسال عبر واتساب'),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton(
                    onPressed: () => _launchUrl(Uri.parse('sms:?body=${Uri.encodeComponent(message)}'), context),
                    child: const Text('إرسال عبر رسالة نصية'),
                  ),
                  SizedBox(height: 30.h),
                  OutlinedButton(
                    onPressed: () => context.push('/activate'),
                    child: const Text('لقد أرسلت الرسالة، أدخل الكود الآن'),
                  ),
                  TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}