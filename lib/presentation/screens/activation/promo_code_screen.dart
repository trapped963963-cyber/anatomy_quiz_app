import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/promo_code_input.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart'; // <-- RE-ADDED for Clipboard

class PromoCodeScreen extends ConsumerStatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  ConsumerState<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends ConsumerState<PromoCodeScreen> {
  final _promoCodeInputKey = GlobalKey<PromoCodeInputState>(); // <-- RE-ADDED for Paste
  String _promoCode = '';
  String? _errorText;
  String? _successText;
  bool _isCodeValid = false;

  Future<void> _validateCode(String code) async {
    final db = ref.read(databaseHelperProvider);
    final bytes = utf8.encode(code.toUpperCase());
    final hash = sha256.convert(bytes).toString();
    final isValid = await db.validatePromoCode(hash);

    setState(() {
      _isCodeValid = isValid;
      if (isValid) {
        _successText = 'رمز ترويجي صالح!';
        _errorText = null;
      } else {
        _errorText = 'الرمز الترويجي غير صالح';
        _successText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 3 من 5 (اختياري)')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هل لديك رمز ترويجي؟',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            PromoCodeInput(
              key: _promoCodeInputKey, // <-- RE-ADDED for Paste
              onValueChanged: (value) {
                setState(() {
                  _promoCode = value;
                  _isCodeValid = false;
                  _errorText = null;
                  _successText = null;
                });
              },
              onCompleted: (code) {
                _validateCode(code);
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
            if (_successText != null) ...[
              SizedBox(height: 10.h),
              Text(
                _successText!,
                style: const TextStyle(color: AppColors.correct),
                textAlign: TextAlign.center,
              )
            ],

            SizedBox(height: 30.h),
            
            ElevatedButton(
              // A secondary style to distinguish it from the primary "Next" button.
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 2,
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onPressed: () async {
                final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                if (clipboardData == null || clipboardData.text == null) return;

                _promoCodeInputKey.currentState?.paste(clipboardData.text!);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لصق من الحافظة'),
                  SizedBox(width: 8.w),
                  const Icon(Icons.content_paste, size: 20),
                ],
              ),
            ),


            SizedBox(height: 10.h),

            
            ElevatedButton(
              onPressed: _isCodeValid
                  ? () {
                      context.push('/contact');
                    }
                  : null,
              child: const Text('التالي'),
            ),
            
            
            
            TextButton(
              onPressed: () => context.push('/contact'),
              child: const Text('تخطي'),
            ),
            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}