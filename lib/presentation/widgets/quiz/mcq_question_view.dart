import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class McqQuestionView extends ConsumerStatefulWidget {
  final Question question;
  final QuestionMode mode;
  final Function(bool isCorrect) onAnswered;
  final Future<bool?> Function(bool isCorrect) showFeedbackBottomSheet;
  final Widget Function(String text) buildQuestionContainer;

  const McqQuestionView({
    super.key,
    required this.question,
    required this.mode,
    required this.onAnswered,
    required this.showFeedbackBottomSheet,
    required this.buildQuestionContainer,
  });

  @override
  ConsumerState<McqQuestionView> createState() => _McqQuestionViewState();
}

class _McqQuestionViewState extends ConsumerState<McqQuestionView> {
  int? _selectedAnswerId;
  bool _isAnswered = false;
  bool? _isLastAnswerCorrect;

  @override
  void didUpdateWidget(covariant McqQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      setState(() {
        _selectedAnswerId = null;
        _isAnswered = false;
        _isLastAnswerCorrect = null;
      });
    }
  }

  void _handleSelection(Label selectedChoice) {
    if (_isAnswered) return;
    setState(() {
      _selectedAnswerId = selectedChoice.id;
    });
  }

  void _handleCheck() {
    if (_selectedAnswerId == null || _isAnswered) return;
    final selectedChoice = widget.question.choices.firstWhere((c) => c.id == _selectedAnswerId);
    final isCorrect = selectedChoice.id == widget.question.correctLabel.id;
    _processAnswer(isCorrect);
  }

  void _processAnswer(bool isCorrect) async {
    switch (widget.mode) {
      case QuestionMode.learn:
        await _runLearnModeFeedback(isCorrect);
        break;
      case QuestionMode.test:
        widget.onAnswered(isCorrect);
        break;
    }
  }

  Future<void> _runLearnModeFeedback(bool isCorrect) async {
    final settings = ref.read(settingsProvider);
    setState(() {
      _isAnswered = true;
      _isLastAnswerCorrect = isCorrect;
    });

    if (isCorrect) {
      ref.read(soundServiceProvider).playCorrectSound();
    } else {
      ref.read(soundServiceProvider).playIncorrectSound();
      if (settings['haptics']!) {
        HapticFeedback.heavyImpact();
      }
    }

    final bool? userClickedNext = await widget.showFeedbackBottomSheet(isCorrect);

    if (mounted && userClickedNext == true) {
      widget.onAnswered(isCorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle baseStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );

    final ButtonStyle normalStyle = baseStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(AppColors.primary),
      foregroundColor: MaterialStateProperty.all(Colors.white),
    );

    final ButtonStyle selectedStyle = baseStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(AppColors.primaryDark),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(6),
      side: MaterialStateProperty.all(BorderSide(color: AppColors.accent, width: 3.w)),
    );

    final ButtonStyle correctStyle = baseStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(AppColors.correct),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(6),
    );

    final ButtonStyle incorrectStyle = baseStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(AppColors.incorrect),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(6),
    );

    final ButtonStyle disabledStyle = baseStyle.copyWith(
      backgroundColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.5)),
      foregroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.7)),
      elevation: MaterialStateProperty.all(0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       widget.buildQuestionContainer(widget.question.questionText),
        SizedBox(height: 16.h),
        Expanded(
          child: ListView.separated(
            itemCount: widget.question.choices.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final choice = widget.question.choices[index];
              final isSelected = choice.id == _selectedAnswerId;
              final isCorrect = choice.id == widget.question.correctLabel.id;

              ButtonStyle currentStyle = normalStyle;
              if (_isAnswered) {
                if (isCorrect) currentStyle = correctStyle;
                else if (isSelected) currentStyle = incorrectStyle;
                else currentStyle = disabledStyle;
              } else if (isSelected) {
                currentStyle = selectedStyle;
              }

              Widget button = ElevatedButton(
                style: currentStyle,
                onPressed: () => _handleSelection(choice),
                child: Text(
                  widget.question.questionType == QuestionType.askForTitle
                      ? choice.title
                      : choice.labelNumber.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
              );

              if (_isAnswered && isSelected) {
                if (isCorrect) return button.animate().shimmer(duration: 700.ms, delay: 200.ms);
                else return button.animate().shake(hz: 5, duration: 500.ms);
              }

              return button;
            },
          ),
        ),
        SizedBox(height: 16.h),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            minimumSize: Size(double.infinity, 50.h),
          ),
        onPressed: (_isAnswered || _selectedAnswerId != null)
        ? () {
          if (_isAnswered) {
            widget.onAnswered(_isLastAnswerCorrect ?? false);
          } else {
            _handleCheck();
          }
        }
        : null, 
          child: Text(
            widget.mode == QuestionMode.test ? 'التالي' : (_isAnswered ? 'التالي' : 'تحقق'),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}