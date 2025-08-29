import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';
import 'package:flutter/services.dart';

class MatchingQuestionView extends ConsumerStatefulWidget {
  final Question question;
  final Function(bool isCorrect) onAnswered;

  const MatchingQuestionView({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  ConsumerState<MatchingQuestionView> createState() => _MatchingQuestionViewState();
}

class _MatchingQuestionViewState extends ConsumerState<MatchingQuestionView> {
  // State variables specific to the Matching Game
  List<Label> _remainingNumbers = [];
  List<Label> _remainingTitles = [];
  Label? _selectedNumber;
  Label? _selectedTitle;
  bool _isCheckingMatch = false;
  Set<int> _disappearingIds = {};
  int? _shakingNumberId;
  int? _shakingTitleId;

  @override
  void initState() {
    super.initState();
    _setupMatchingGame();
  }

  @override
  void didUpdateWidget(covariant MatchingQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      _setupMatchingGame();
    }
  }

  void _setupMatchingGame() {
    final numbers = List<Label>.from(widget.question.choices)..sort((a, b) => a.labelNumber.compareTo(b.labelNumber));
    final titles = List<Label>.from(widget.question.choices)..shuffle();
    setState(() {
      _remainingNumbers = numbers;
      _remainingTitles = titles;
      _selectedNumber = null;
      _selectedTitle = null;
      _isCheckingMatch = false;
      _disappearingIds = {};
      _shakingNumberId = null;
      _shakingTitleId = null;
    });
  }

  void _handleSelection(Label label, bool isNumber) {
    if (_isCheckingMatch) return;

    setState(() {
      if (isNumber) {
        _selectedNumber = label;
      } else {
        _selectedTitle = label;
      }
    });

    if (_selectedNumber != null && _selectedTitle != null) {
      setState(() => _isCheckingMatch = true);
      final bool isCorrect = _selectedNumber!.id == _selectedTitle!.id;
      final settings = ref.read(settingsProvider);

      if (isCorrect) {
        ref.read(soundServiceProvider).playCorrectSound();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return; 
          setState(() => _disappearingIds.add(_selectedNumber!.id));
          
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return; 
            setState(() {
              _remainingNumbers.removeWhere((item) => item.id == _selectedNumber!.id);
              _remainingTitles.removeWhere((item) => item.id == _selectedTitle!.id);
              _selectedNumber = null;
              _selectedTitle = null;
              _isCheckingMatch = false;
              if (_remainingNumbers.isEmpty) {
                widget.onAnswered(true);
              }
            });
          });
        });
      } else {
        ref.read(soundServiceProvider).playIncorrectSound();
        if (settings['haptics']!) HapticFeedback.heavyImpact();
        setState(() {
          _shakingNumberId = _selectedNumber!.id;
          _shakingTitleId = _selectedTitle!.id;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _selectedNumber = null;
            _selectedTitle = null;
            _shakingNumberId = null;
            _shakingTitleId = null;
            _isCheckingMatch = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // ## STEP 1: Define all the necessary styles ##
    final ButtonStyle normalStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    );
    final ButtonStyle selectedStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      side: BorderSide(color: AppColors.accent, width: 3.w),
    );
    final ButtonStyle correctStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppColors.correct,
      foregroundColor: Colors.white,
    );
    final ButtonStyle incorrectStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: AppColors.incorrect,
      foregroundColor: Colors.white,
    );

    // Helper function to build a single button
    Widget buildMatchButton(Label item, bool isNumber) {
      final bool isSelected = (isNumber ? _selectedNumber?.id : _selectedTitle?.id) == item.id;
      final bool isShaking = (isNumber ? _shakingNumberId : _shakingTitleId) == item.id;
      
      // ## STEP 2: Add the new styling logic ##
      ButtonStyle currentStyle;
      if (_isCheckingMatch && isSelected) {
        // If we are currently checking a match, color the selected buttons red or green.
        final bool isMatchCorrect = _selectedNumber!.id == _selectedTitle!.id;
        currentStyle = isMatchCorrect ? correctStyle : incorrectStyle;
      } else if (isSelected) {
        // If an item is just selected, use the selected style.
        currentStyle = selectedStyle;
      } else {
        // Otherwise, use the normal style.
        currentStyle = normalStyle;
      }
      
      Widget button = ElevatedButton(
        style: currentStyle,
        onPressed: () => _handleSelection(item, isNumber),
        child: isNumber
            ? Text(item.labelNumber.toString(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold))
            : AutoSizeText(
                item.title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                maxLines: 2,
                minFontSize: 12,
                textAlign: TextAlign.center,
              ),
      );

      if (isShaking) {
        return button.animate().shake(hz: 5, duration: 500.ms);
      }
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _disappearingIds.contains(item.id) ? 0.0 : 1.0,
        child: button,
      );
    }
    
    return Column(
      children: [
        Text(
          widget.question.questionText,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.w),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: _remainingNumbers.map((item) => buildMatchButton(item, true)).toList(),
              ),
            ),
          ),
        ),
        const Divider(thickness: 1, indent: 20, endIndent: 20),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.w),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                alignment: WrapAlignment.center,
                children: _remainingTitles.map((item) => buildMatchButton(item, false)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
    
  }
}