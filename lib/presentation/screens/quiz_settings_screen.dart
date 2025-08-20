import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';

class QuizSettingsScreen extends StatefulWidget {
  const QuizSettingsScreen({super.key});

  @override
  State<QuizSettingsScreen> createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends State<QuizSettingsScreen> {
  double _questionCount = 10.0;
  QuestionScope _scope = QuestionScope.allLevels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الاختبار العام')),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question Count Slider
            Text('عدد الأسئلة: ${_questionCount.toInt()}', style: TextStyle(fontSize: 18.sp)),
            Slider(
              value: _questionCount,
              min: 5,
              max: 50,
              divisions: 9,
              label: _questionCount.round().toString(),
              onChanged: (double value) {
                setState(() => _questionCount = value);
              },
            ),
            SizedBox(height: 30.h),
            // Question Scope
            Text('نطاق الأسئلة', style: TextStyle(fontSize: 18.sp)),
            SegmentedButton<QuestionScope>(
              segments: const [
                ButtonSegment(value: QuestionScope.allLevels, label: Text('كل المستويات')),
                ButtonSegment(value: QuestionScope.completedLevels, label: Text('المكتملة فقط')),
              ],
              selected: {_scope},
              onSelectionChanged: (newSelection) {
                setState(() => _scope = newSelection.first);
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final config = QuizConfig(
                  quizType: QuizType.general,
                  difficulty: _questionCount.toInt(),
                  questionScope: _scope,
                );
                context.push('/custom-quiz', extra: config);
              },
              child: const Text('ابدأ الاختبار'),
            ),
          ],
        ),
      ),
    );
  }
}