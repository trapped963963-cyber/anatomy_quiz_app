import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/service_providers.dart';

import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/settings_icon_button.dart';
import 'package:flutter/services.dart';
import 'package:anatomy_quiz_app/presentation/providers/search_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة التطبيق'),
        content: const Text('هل أنت متأكد؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User chooses to stay
            child: const Text('البقاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // User chooses to exit
            child: const Text('الخروج'),
          ),
        ],
      ),
    ) ?? false; // Return false if the dialog is dismissed
  }
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
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final bool shouldExit = await _showExitConfirmationDialog();
          if (shouldExit) {
            SystemNavigator.pop();
          }
        }
      },

      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // In the main Row
                      Expanded( // Wrap in Expanded to give it a defined space
                        child: AutoSizeText(
                          'مرحباً، ${userProgress.userName ?? ''}!',
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                          maxLines: 1, // Ensure it stays on one line
                          minFontSize: 15, // Set a minimum readable size
                        ),
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
                  _buildMainButton(context,ref),
                  SizedBox(height: 20.h),
                  _buildSecondaryButton(
                    context,
                    title: 'يلا ندرس!',
                    icon: Icons.map,
                    onTap: () => context.push('/units'),
                  ),
                  SizedBox(height: 10.h),
                  _buildSecondaryButton(
                    context,
                    title: 'جاهز للاختبار؟!',
                    icon: Icons.quiz,
                    onTap: () => context.push('/quiz/select-content'),
                  ),
                   SizedBox(height: 10.h),
                  _buildSecondaryButton(
                    context,
                    title: 'ابحث عن رسم', // Search for a diagram
                    icon: Icons.search,
                    onTap: () {
                      // ## THE FIX: Reset the search state before navigating ##
                      ref.read(searchQueryProvider.notifier).state = '';
                      context.push('/search');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, WidgetRef ref) {
    final userProgress = ref.watch(userProgressProvider);
    final lastActiveLevelId = userProgress.lastActiveLevelId;
    final lastActiveLevelTitle = userProgress.lastActiveLevelTitle ?? 'ابدأ رحلتك';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: () {
          context.push('/level/$lastActiveLevelId');
        },
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes items to opposite ends
            crossAxisAlignment: CrossAxisAlignment.center, // Vertically aligns items in the middle
            children: [
              // This Column holds the two text widgets
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('متابعة التعلم', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  AutoSizeText(
                    lastActiveLevelTitle,
                    style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                    maxLines: 2,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis, // Add '...' if it's still too long
                  ),                ],
              ),
              // The icon is now a direct child of the Row
              Icon(Icons.send, color: Colors.white, size: 40.sp),
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