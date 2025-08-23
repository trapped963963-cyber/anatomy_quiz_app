import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';
class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({super.key});

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Gender? _selectedGender; // State for the selected gender

  void _onNext() {
    // Validate both name and gender before proceeding
    if (_formKey.currentState!.validate() && _selectedGender != null) {
      ref.read(onboardingProvider.notifier).setName(_nameController.text.trim());
      ref.read(onboardingProvider.notifier).setGender(_selectedGender!);
      context.push('/phone');
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
              Text('ما هو اسمك؟', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              SizedBox(height: 30.h),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().length < 2) return 'الرجاء إدخال اسم لا يقل عن حرفين';
                  if (value.contains(RegExp(r'[0-9]'))) return 'لا يمكن أن يحتوي الاسم على أرقام';
                  return null;
                },
              ),
              SizedBox(height: 30.h),
              Text('أنا:', style: TextStyle(fontSize: 18.sp), textAlign: TextAlign.center),
              SizedBox(height: 10.h),

              // ## NEW: Gender Selection UI ##
              SegmentedButton<Gender>(
                // We are moving the segments definition inside the build method
                // so it can react to state changes.
                segments: <ButtonSegment<Gender>>[
                  ButtonSegment<Gender>(
                    value: Gender.male,
                    label: const Text('ذكر'),
                    // ## NEW: Add an icon that changes based on selection ##
                    icon: Icon(
                          Icons.man_sharp,       // The default icon
                    ),
                  ),
                  ButtonSegment<Gender>(
                    value: Gender.female,
                    label: const Text('أنثى'),
                    // ## NEW: Add an icon that changes based on selection ##
                    icon: Icon(
                           Icons.woman_sharp,     // The default icon
                    ),
                  ),
                ],
                selected: _selectedGender != null ? {_selectedGender!} : {},
                onSelectionChanged: (Set<Gender> newSelection) {
                  setState(() {
                    if (newSelection.isNotEmpty) {
                      _selectedGender = newSelection.first;
                    } else {
                      _selectedGender = null;
                    }
                  });
                },
                emptySelectionAllowed: true,
                showSelectedIcon: false,

              ),

              SizedBox(height: 30.h),
              ElevatedButton(
                // Button is disabled until both fields are valid
                onPressed: (_nameController.text.isNotEmpty && _selectedGender != null) ? _onNext : null,
                child: const Text('التالي'),
              ),
              TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
            ],
          ),
        ),
      ),
    );
  }
}