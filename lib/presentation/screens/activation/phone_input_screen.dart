import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/widgets/activation/phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ## ADD THIS IMPORT ##


class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  late Future<String?> _initialPhoneFuture;
  String _phoneNumber = '';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // We assign the Future in initState
    _initialPhoneFuture = _loadInitialData();
  }

  Future<String?> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('onboarding_phone');

    if (savedPhone != null) {
      setState(() {
        _phoneNumber = savedPhone;
        _isComplete = savedPhone.length == 10;
      });
    }
    return savedPhone;
  }

  // ## NEW: Save data immediately on change ##
  Future<void> _onPhoneChanged(String value) async {
    setState(() {
      _phoneNumber = value;
      _isComplete = value.length == 10;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_phone', value);

  }

  void _onNext() {
    if (_isComplete) {
      context.push('/promo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 2 من 5')),
      body: FutureBuilder<String?>(
        future: _initialPhoneFuture,
        builder: (context, snapshot) {
          // While waiting for the data from SharedPreferences, show a loader
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once the data is loaded, build the main UI
          final initialPhone = snapshot.data ?? '';

      
      
      
        return Stack(
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
                        initialValue: _phoneNumber,
                        onValueChanged: _onPhoneChanged ,
                        onCompleted: (number) {
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
          ),]
        );
      }
    ) 
    );
  }
}