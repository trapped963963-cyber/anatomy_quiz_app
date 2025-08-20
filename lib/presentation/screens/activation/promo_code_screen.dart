import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/promo_code_input.dart';

class PromoCodeScreen extends ConsumerStatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  ConsumerState<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends ConsumerState<PromoCodeScreen> {
  String _promoCode = '';
  bool _isFilled = false;
  String? _errorText;

  Future<void> _validateAndProceed() async {
    if (_promoCode.isEmpty) {
      context.push('/contact');
      return;
    }

    final db = ref.read(databaseHelperProvider);
    final bytes = utf8.encode(_promoCode.toUpperCase());
    final hash = sha256.convert(bytes).toString();
    
    final isValid = await db.validatePromoCode(hash);
    if (isValid) {
      // In a real app, you might apply a discount or unlock a feature.
      // For now, we just proceed.
      context.go('/contact');
    } else {
      setState(() {
        _errorText = 'الرمز الترويجي غير صالح';
      });
    }
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
              onCompleted: (code) {
                setState(() {
                  _promoCode = code;
                  _isFilled = true;
                  _errorText = null;
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
            ElevatedButton(
              onPressed: _validateAndProceed,
              child: const Text('التالي'),
            ),
            TextButton(
              onPressed: () => context.go('/contact'),
              child: const Text('تخطي'),
            ),
            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}