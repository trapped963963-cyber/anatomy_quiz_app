import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';

class WordGameView extends ConsumerStatefulWidget {
  final Question question;
  final QuestionMode mode;
  final Function(bool isCorrect) onAnswered;
  final Future<bool?> Function(bool isCorrect) showFeedbackBottomSheet;
  final Widget Function(String text) buildQuestionContainer;

  const WordGameView({
    super.key,
    required this.question,
    required this.mode,
    required this.onAnswered,
    required this.showFeedbackBottomSheet,
    required this.buildQuestionContainer,
  });

  @override
  ConsumerState<WordGameView> createState() => _WordGameViewState();
}

class _WordGameViewState extends ConsumerState<WordGameView> {
  // State variables specific to the Word Game
  List<String> _answerSlots = [];
  List<String> _letterBank = [];
  String _wordToGuess = '';
  String _displayQuestionText = '';
  bool _isGameSetup = false;
  List<bool?> _letterFeedback = [];
  bool _isAnswered = false;
  bool? _isLastAnswerCorrect;


  @override
  void didUpdateWidget(covariant WordGameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      setState(() {
        _isGameSetup = false;
        _isAnswered = false;
        _letterFeedback = [];
        _isLastAnswerCorrect = null;  
      });
    }
  }

  bool _isArabic(String text) {
    if (text.isEmpty) return true; // Default to Arabic for empty strings

    // Loop through the string to find the first character that is a letter.
    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i);

      // Check if the character is an Arabic letter
      if (charCode >= 0x0600 && charCode <= 0x06FF) {
        return true;
      }

      // Check if the character is a standard English letter (a-z, A-Z)
      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        return false;
      }
    }

    // If no definitive letter is found (e.g., the string is just numbers),
    // default to LTR as numbers are typically read left-to-right.
    return false;
  }
  void _setupGame(BoxConstraints constraints) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The logic to choose a word based on screen width
      final double boxSize = 40.w;
      final double spacing = 4.w;
      final int maxLetters = ((constraints.maxWidth * 0.95) / (boxSize + spacing)).floor();
      final title = widget.question.correctLabel.title;
      // ## THE FIX: Create a centralized list of excluded words ##
      const List<String> excludedWords = ['أو', 'او', 'إلى' , 'الى' , 'من' , 'في', 'عن' , 'على','حول'];

      final words = title.split(RegExp(r'\s+'));

      List<int> fittableWordIndexes = [];
      for (int i = 0; i < words.length; i++) {
        final trimmedWord = words[i].trim();
        // A word is fittable if it's long enough, not excluded, AND fits the screen.
        if (trimmedWord.length > 1 &&
            !excludedWords.contains(trimmedWord) &&
            words[i].length <= maxLetters) {
          fittableWordIndexes.add(i);
        }
      }
      String wordToGuess;
      int chosenIndex;
      String toreplace;

      if (fittableWordIndexes.isNotEmpty) {
        final int deterministicIndex = widget.question.randomIndex! % fittableWordIndexes.length;
        chosenIndex = fittableWordIndexes[deterministicIndex];
        wordToGuess = words[chosenIndex];
        toreplace = '-' * wordToGuess.length;
      } else {
        final longestWord = words.reduce((a, b) => a.length > b.length ? a : b);
        chosenIndex = words.indexOf(longestWord);
        int Y = maxLetters;
        if(maxLetters == longestWord.length -1 && longestWord.length!=2)
        {
          Y=maxLetters-1;
        }
        if(longestWord.contains('Hz'))
        {Y = 2;}
        wordToGuess = longestWord.substring(longestWord.length - Y);
        final String wordStem = longestWord.substring(0, longestWord.length - Y);
        toreplace = '$wordStem${'-' * wordToGuess.length}';
      }
      

      

      List<String> displayWords = List.from(words);
      displayWords[chosenIndex] = toreplace;
      final String blankedTitle = displayWords.join(' ');
      final String displayQuestionText = AppStrings.askToWriteTitleWithContext(
        widget.question.correctLabel.labelNumber,
        blankedTitle,
      );
      final actualLetters = wordToGuess.split('');
      List<String> finalLetterBank = List.from(actualLetters);

      setState(() {
        _wordToGuess = wordToGuess;
        _displayQuestionText = displayQuestionText;
        _answerSlots = List.generate(wordToGuess.length, (index) => '');
        _letterBank = finalLetterBank..shuffle();
        _isGameSetup = true;
      });
    });
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
    if (!_isGameSetup) {
      // If the game isn't set up, run the setup logic
      return LayoutBuilder(builder: (context, constraints) {
        _setupGame(constraints);
        return const AppLoadingIndicator();
      });
    }

    // If the game IS set up, build the UI
    bool allSlotsFilled = !_answerSlots.contains('');
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.buildQuestionContainer(_displayQuestionText),
          SizedBox(height: 20.h),
          Directionality(
            textDirection: _isArabic(_wordToGuess) ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_answerSlots.length, (index) {
                  final String currentChar = _answerSlots[index];
                  Color boxColor;
                  if (_isAnswered && _letterFeedback.length == _answerSlots.length) {
                    boxColor = _letterFeedback[index]! ? AppColors.correct : AppColors.incorrect;
                  } else {
                    boxColor = currentChar.isNotEmpty ? Colors.blue.shade100 : Colors.grey.shade200;
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: GestureDetector(
                      onTap: () { if (currentChar.isNotEmpty) { setState(() { _letterBank.add(_answerSlots[index]); _answerSlots[index] = ''; }); } },
                      child: Container(
                        width: 40.r, height: 40.r,
                        decoration: BoxDecoration(
                          color: boxColor,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            currentChar, 
                            style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.bold,
                              color: _isAnswered ? Colors.white : AppColors.textPrimary,
                            ),
                          )
                        ),
                      ),
                    ),
                  );
              }),
            ),
          ),
          SizedBox(height: 24.h),
          if (!_isAnswered)
            Wrap(
              spacing: 8.w, runSpacing: 8.h, alignment: WrapAlignment.center,
              children: _letterBank.map((letter) {
              return Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  // We wrap with Material for the InkWell ripple effect.
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // This is your current logic, which we are preserving.
                        int emptyIndex = _answerSlots.indexOf('');
                        if (emptyIndex != -1) {
                          setState(() {
                            _answerSlots[emptyIndex] = letter;
                            _letterBank.remove(letter);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: AppColors.correct.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.correct.withOpacity(0.5)),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 18.sp, color: AppColors.textPrimary, fontFamily: GoogleFonts.cairo().fontFamily),
                  children: [
                    TextSpan(
                      text: _wordToGuess,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 24.h),
          // Check/Next Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              minimumSize: Size(double.infinity, 50.h),          
            ),
            onPressed: (_isAnswered || allSlotsFilled)
            ? () {
                // This button is enabled.
                if (_isAnswered) {
                  widget.onAnswered(_isLastAnswerCorrect ?? false);
                } else {
                  // If not yet checked, calculate the result and process it.
                  final userAnswer = _answerSlots.join('');
                  final isCorrect = userAnswer == _wordToGuess;
                  // Calculate feedback for each letter
                  List<bool> feedback = [];
                  for (int i = 0; i < _wordToGuess.length; i++) {
                    if (userAnswer[i] == _wordToGuess[i]) {
                      feedback.add(true); // Correct letter
                    } else {
                      feedback.add(false); // Incorrect letter
                    }
                  }
                  // Save the feedback to the state
                  setState(() {
                    _letterFeedback = feedback;
                  });

                  // Proceed with the normal answer process
                  _processAnswer(isCorrect);
                }
              }
            : null, // Otherwise, the button is disabled.
            child: Text(
              widget.mode == QuestionMode.test ? 'التالي' : (_isAnswered ? 'التالي' : 'تحقق'),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}