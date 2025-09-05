import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/activation_code_input.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';

class ActivationCodeScreen extends ConsumerStatefulWidget {
  const ActivationCodeScreen({super.key});

  @override
  ConsumerState<ActivationCodeScreen> createState() => _ActivationCodeScreenState();
}

class _ActivationCodeScreenState extends ConsumerState<ActivationCodeScreen> {
  final _activationInputKey = GlobalKey<ActivationCodeInputState>();
  String _activationCode = '';
  bool _isLoading = false;
  String? _errorText;

  Future<void> _activateApp() async {
    if (_activationCode.length < 12) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    

    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('onboarding_phone');
      final userName = prefs.getString('onboarding_name');
      final genderString = prefs.getString('onboarding_gender');

      if (phoneNumber == null || userName == null || genderString == null) {
        throw Exception("Missing user data from previous steps.");
      }

      final gender = genderString == 'male' ? Gender.male : Gender.female;
      final activationService = ref.read(activationServiceProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final userNotifier = ref.read(userProgressProvider.notifier);

      final fingerprint = await activationService.generateDeviceFingerprint(phoneNumber);
      
      await activationService.fetchAndStorePepper(
        phoneNumber: phoneNumber,
        fingerprint: fingerprint,
      );
      final dbKey = await secureStorage.getDbKey();
      if (dbKey != null) {
        ref.read(encryptionServiceProvider).initialize(dbKey);
      } else {
        throw Exception("Failed to retrieve DB key after storing it.");
      }

      final isValid = await activationService.verifyActivationCode(
        phoneNumber: phoneNumber,
        activationCode: _activationCode,
      );


      if (isValid) {
        await prefs.setString('activationCode', _activationCode);
        await prefs.setString('phoneNumberForValidation', phoneNumber);
        
        await userNotifier.setUserName(userName);
        await userNotifier.setGender(gender);
        
        if (mounted) context.go('/home');
      } else {
        setState(() {
          _errorText = 'كود التفعيل غير صحيح. الرجاء المحاولة مرة أخرى.';
          _isLoading = false;
        });
      }
    }  
    on ApiException catch (e) {
      setState(() {
        // Show a more specific message for API errors.
        _errorText = 'لم يتم العثور على تفعيل لهذا الرقم. الرجاء التواصل مع قسم الدعم.';
        _isLoading = false;
      });
    } 
    catch(e) {
        setState(() {
        _errorText = 'فشل استرداد بيانات التفعيل. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('أدخل كود التفعيل', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 30.h),
              ActivationCodeInput(
                key: _activationInputKey,
                onValueChanged: (value) {
                  setState(() {
                    _activationCode = value;
                  });
                },
                onCompleted: (code) {
                  _activateApp();
                },
              ),
               if (_errorText != null) ...[
                SizedBox(height: 10.h),
                Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center)
              ],
              SizedBox(height: 20.h),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.content_paste),
                label: const Text('لصق من الحافظة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: () async {
                  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                  if (clipboardData == null || clipboardData.text == null) return;
                  _activationInputKey.currentState?.paste(clipboardData.text!);
                },
              ),
              SizedBox(height: 10.h),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _activationCode.length == 12 ? _activateApp : null,
                      child: const Text('تفعيل التطبيق'),
                    ),
              TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
            ],
          ),
        ),
      ),
    );
  }
}