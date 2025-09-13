import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/promo_code_input.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromoCodeScreen extends ConsumerStatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  ConsumerState<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends ConsumerState<PromoCodeScreen> {
  final _promoCodeInputKey = GlobalKey<PromoCodeInputState>();

  String _promoCode = '';
  String? _errorText;
  bool _isConfirmed = false;
  bool _isCompleted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPromoCode();
  }

  Future<void> _loadPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('onboarding_promo_code');
    if (code != null) {
      setState(() {
        _promoCode = code;
        _isConfirmed = true;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _validateCode() async {
    final code = _promoCode.toUpperCase();
    final db = ref.read(databaseHelperProvider);
    final bytes = utf8.encode(code);
    final hash = sha256.convert(bytes).toString();
    final isValid = await db.validatePromoCode(hash);

    final prefs = await SharedPreferences.getInstance();
    if (isValid) await prefs.setString('onboarding_promo_code', code);

    setState(() {
      if (isValid) {
        _isConfirmed = true;
        _errorText = null;
      } else {
        _isConfirmed = false;
        _errorText = 'الرمز الترويجي غير صالح';
      }
    });
  }

  void _unConfirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_promo_code');
    setState(() {
      _isConfirmed = false;
      _promoCode = '';
      _isCompleted = false;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 3 من 5 (اختياري)')),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isConfirmed) ...[
                        const Text(
                          'لقد اخترت الرمز الترويجي:',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _promoCode,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
        
                      if (!_isConfirmed) ...[
                        Text(
                          'هل لديك رمز ترويجي؟',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30.h),
                        PromoCodeInput(
                          key: _promoCodeInputKey,
                          onValueChanged: (code) {
                            setState(() {
                              _promoCode = code.toUpperCase();
                              _isCompleted = false;
                            });
                          },
                          onCompleted: (code) {
                            setState(() {
                              _promoCode = code.toUpperCase();
                              _isCompleted = true;
                            });
                          },
                        ),
                        if (_errorText != null) ...[
                          SizedBox(height: 10.h),
                          Text(
                            _errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 30.h),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 2,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: () async {
                            final clipboardData =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (clipboardData?.text != null) {
                              _promoCodeInputKey.currentState
                                  ?.paste(clipboardData!.text!);
                            }
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
                      ],
        
                      SizedBox(height: 10.h),
        
                      ElevatedButton(
                        onPressed: _isConfirmed
                            ? () => context.push('/contact')
                            : _isCompleted
                                ? _validateCode
                                : null,
                        child: Text(_isConfirmed ? 'التالي' : 'تحقق'),
                      ),
        
                      TextButton(
                        onPressed:
                            _isConfirmed ? _unConfirm : () => context.push('/contact'),
                        child: Text(_isConfirmed ? 'تغيير الرمز' : 'تخطي'),
                      ),
        
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('رجوع'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),]
      ),
    );
  }
}
