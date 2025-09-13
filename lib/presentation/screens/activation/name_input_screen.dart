import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ## ADD THIS IMPORT ##
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({super.key});

  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Gender? _selectedGender;
  bool _isLoading = true;

 
  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Load data when the screen starts
    _nameController.addListener(_onNameChanged);
  }
 
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('onboarding_name');
    final savedGenderString = prefs.getString('onboarding_gender');

    if (savedName != null) {
      _nameController.text = savedName;
    }
    if (savedGenderString != null) {
      _selectedGender = savedGenderString == 'male' ? Gender.male : Gender.female;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onNameChanged() async {
    setState(() {}); 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_name', _nameController.text);
  }

  Future<void> _onGenderChanged(Gender? gender) async {
    setState(() {
      _selectedGender = gender;
    });
    final prefs = await SharedPreferences.getInstance();
    if (gender != null) {
      await prefs.setString('onboarding_gender', gender == Gender.male ? 'male' : 'female');
    } else {
      await prefs.remove('onboarding_gender');
    }
  }

  void _onNext() {
    if (_formKey.currentState!.validate() && _selectedGender != null) {
      context.push('/phone');
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطوة 1 من 5')),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : Stack(
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
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(builder: (context, constraints){
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('ما هو اسمك؟', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            SizedBox(height: 30.h),
                            TextFormField(
                              controller: _nameController,
                              maxLength: 15,
                              decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(),counterText: "", ),
                              validator: (value) {
                                if (value == null || value.trim().length < 2) return 'الرجاء إدخال اسم لا يقل عن حرفين';
                                if (value.contains(RegExp(r'[0-9]'))) return 'لا يمكن أن يحتوي الاسم على أرقام';
                                return null;
                              },
                            ),
                            SizedBox(height: 30.h),
                            Text('أنا:', style: TextStyle(fontSize: 18.sp), textAlign: TextAlign.center),
                            SizedBox(height: 10.h),
                            SegmentedButton<Gender>(
                              segments: <ButtonSegment<Gender>>[
                                ButtonSegment<Gender>(
                                  value: Gender.male,
                                  label: const Text('ذكر'),
                                  icon: Icon(Icons.man_sharp,),
                                ),
                                ButtonSegment<Gender>(
                                  value: Gender.female,
                                  label: const Text('أنثى'),
                                  icon: Icon(Icons.woman_sharp,),
                                ),
                              ],
                              selected: _selectedGender != null ? {_selectedGender!} : {},
                              onSelectionChanged: (Set<Gender> newSelection) {
                                _onGenderChanged(newSelection.isNotEmpty ? newSelection.first : null);
                              },
                              emptySelectionAllowed: true,
                              showSelectedIcon: false,
                            ),
                            SizedBox(height: 30.h),
                            ElevatedButton(
                              onPressed: (_nameController.text.trim().length >= 2 && _selectedGender != null) ? _onNext : null,
                              child: const Text('التالي'),
                            ),
                            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
                          ],
                        ),
                      ),
                    );}
                  ),
                ),
              ),]
          ),
    );
  }
}