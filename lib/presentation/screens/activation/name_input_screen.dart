import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({super.key});

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      ref.read(onboardingProvider.notifier).setName(_nameController.text.trim());
      context.go('/phone');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 1 من 5')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ما هو اسمك؟',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'الرجاء إدخال اسم لا يقل عن 3 أحرف';
                  }
                  if (value.contains(RegExp(r'[0-9]'))) {
                    return 'لا يمكن أن يحتوي الاسم على أرقام';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30.h),
              ElevatedButton(onPressed: _onNext, child: const Text('التالي')),
              TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
            ],
          ),
        ),
      ),
    );
  }
}