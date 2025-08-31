import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/service_providers.dart';

import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/settings_icon_button.dart';
import 'package:flutter/services.dart';




class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  
  @override
  void initState() {
    super.initState();
    ref.read(userActivityServiceProvider).triggerActivityPing();
  }
  @override
  Widget build(BuildContext context) {
    final userProgress = ref.watch(userProgressProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop ,dynamic result) {
        if (!didPop) {
          SystemNavigator.pop();
       }
      },

      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مرحباً، ${userProgress.userName ?? ''}!',
                      style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        SettingsIconButton(
                          onIcon: Icons.volume_up,
                          offIcon: Icons.volume_off,
                          isOn: settings['sound']!,
                          onPressed: () => settingsNotifier.toggleSound(),
                        ),
                        SettingsIconButton(
                          onIcon: Icons.vibration,
                          offIcon: Icons.smartphone,
                          isOn: settings['haptics']!,
                          onPressed: () => settingsNotifier.toggleHaptics(),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 60.h),
                _buildMainButton(
                  context,
                  title: 'متابعة التعلم',
                  subtitle: 'المستوى',
                  icon: Icons.play_arrow,
                  onTap: () {
                    // We will build this screen next
                    // context.go('/step/${userProgress.currentLevelId}/${userProgress.currentStepInLevel}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('شاشة الاختبار قيد الإنشاء!'))
                    );
                  },
                ),
                SizedBox(height: 20.h),
                _buildSecondaryButton(
                  context,
                  title: 'مسار التعلم',
                  icon: Icons.map,
                  onTap: () => context.push('/units'),
                ),
                SizedBox(height: 10.h),
                _buildSecondaryButton(
                  context,
                  title: 'اختبار عام',
                  icon: Icons.quiz,
                  onTap: () => context.push('/quiz/select-content'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.teal.shade300],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 40.sp),
              SizedBox(height: 10.h),
              Text(title, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 16.sp, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}