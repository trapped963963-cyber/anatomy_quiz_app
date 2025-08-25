import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/core/utils/feedback_messages.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionWidget extends ConsumerStatefulWidget {
  final Question question;
  final Function(bool isCorrect) onAnswered;
  final QuestionMode mode;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.mode = QuestionMode.learn,
  });

  @override
  ConsumerState<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends ConsumerState<QuestionWidget> {
  int? _selectedAnswerId;
  bool _isAnswered = false;
  bool? _isLastAnswerCorrect;


  // State for the Word Game
  List<String> _answerSlots = [];
  List<String> _letterBank = [];
  String _wordToGuess = '';
  String _displayQuestionText = '';
  bool _isGameSetup = false;
  List<bool?> _letterFeedback = [];
  
  // State for the Matching Game
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
    if (widget.question.questionType == QuestionType.matching) {
      _setupMatchingGame();
    }
  }

  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      setState(() {
        _selectedAnswerId = null;
        _isAnswered = false;
        _isLastAnswerCorrect = null;
        _isGameSetup = false;
        _letterFeedback = []; 
        if (widget.question.questionType == QuestionType.matching) {
          _setupMatchingGame();
        }
      });
    }
  }
  void _processAnswer(bool isCorrect) {
    // This switch statement is the new "brain" of the widget.
    switch (widget.mode) {
      case QuestionMode.learn:
        _runLearnModeFeedback(isCorrect);
        break;
      case QuestionMode.test:
        // In test mode, we just record the answer and move on.
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
    // Capture the value returned when the sheet is closed.
    final bool? userClickedNext = await _showFeedbackBottomSheet(isCorrect);

    // Only move to the next question if the user explicitly clicked the "Next" button.
    if (mounted && userClickedNext == true) {
      widget.onAnswered(isCorrect);
    }
  }

  Future<bool?> _showFeedbackBottomSheet(bool isCorrect) async {
    // Get screen height to make the sheet responsive.
    final screenHeight = MediaQuery.of(context).size.height;

    final userProgress = ref.read(userProgressProvider);
    final gender = userProgress.gender == 'female' ? Gender.female : Gender.male;
    final message = FeedbackMessages.getRandomMessage(isCorrect: isCorrect, gender: gender);

    final bool shouldShowTitle = 
        widget.question.questionType == QuestionType.askForTitle || 
        widget.question.questionType == QuestionType.askToWriteTitle;

    final String correctAnswerText = shouldShowTitle
        ? widget.question.correctLabel.title
        : widget.question.correctLabel.labelNumber.toString();

    return await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      backgroundColor: isCorrect ? AppColors.correct : AppColors.incorrect,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          // ## TWEAK 1: Height is now 30% of the screen height ##
          height: screenHeight * 0.33,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 32.sp, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12.h),
                if (!isCorrect)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: AutoSizeText(
                      'الإجابة الصحيحة: $correctAnswerText',
                      style: TextStyle(fontSize: 25.sp, color: Colors.white70),
                      textAlign: TextAlign.center,
                      maxLines: 3, // It can wrap to a second line if needed
                      minFontSize: 14, // It will shrink down to this size before truncating
                    ),
                  ),

                // Use a Spacer to push the button to the bottom, creating a flexible layout
                const Spacer(), 

                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isCorrect ? AppColors.correct : AppColors.incorrect,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSelection(Label selectedChoice) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerId = selectedChoice.id;
    });
  }
  void _handleSelectionMatching(Label label, bool isNumber) {
  if (_isCheckingMatch) return;

  setState(() {
    if (isNumber) {
      _selectedNumber = label;
    } else {
      _selectedTitle = label;
    }
  });

  // If both a number and a title have been selected, check for a match.
  if (_selectedNumber != null && _selectedTitle != null) {
    setState(() => _isCheckingMatch = true);
    final bool isCorrect = _selectedNumber!.id == _selectedTitle!.id;
    final settings = ref.read(settingsProvider);

    if (isCorrect) {
      ref.read(soundServiceProvider).playCorrectSound();
      // Correct Match: Trigger fade-out animation
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          _disappearingIds.add(_selectedNumber!.id);
        });

        // After the animation, permanently remove the items.
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
      // Incorrect Match: Trigger shake animation
      ref.read(soundServiceProvider).playIncorrectSound();
      if (settings['haptics']!) {
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _shakingNumberId = _selectedNumber!.id;
        _shakingTitleId = _selectedTitle!.id;
      });

      // After the animation, reset the selections.
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

  void _handleCheck() {
    if (_selectedAnswerId == null || _isAnswered) return;

    final selectedChoice = widget.question.choices.firstWhere((c) => c.id == _selectedAnswerId);
    final isCorrect = selectedChoice.id == widget.question.correctLabel.id;
    _processAnswer(isCorrect);
  }

  void _setupMatchingGame() {
    // Create shuffled lists of the choices to populate the pools.
    final numbers = List<Label>.from(widget.question.choices)..sort((a, b) => a.labelNumber.compareTo(b.labelNumber));
    final titles = List<Label>.from(widget.question.choices)..shuffle();

    setState(() {
      _remainingNumbers = numbers;
      _remainingTitles = titles;
      _selectedNumber = null;
      _selectedTitle = null;
      _isCheckingMatch = false;
    });
  }


  void _showFullQuestionText(BuildContext context, String fullText) {
    // Get the screen height to make our bottom sheet responsive
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.5), // 50% of screen height
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w,vertical: 16.h),
            child: Stack( // Use a Stack to overlay the close button
              children: [
                // Main content
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            fullText,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20.sp, height: 2.0,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ## FIX: Add the 'X' close button ##
                Positioned(
                  top: -4.h, // Adjust position to look nice
                  right: -12.w,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionContainer(String passedText) {

    return Stack( // We use Stack to overlay the button on the container
      children: [
        // The main text container
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 60.h, maxHeight: 80.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w , vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: AutoSizeText(
              passedText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
              minFontSize: 14,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // ## FIX: Use Positioned for the icon ##
        // This "floats" the button in the corner without taking up layout space.
        Positioned(
          top: 0,
          left: -1.w,
          child: IconButton(
            // ## FIX: Changed icon to zoom_out_map ##
            icon: const Icon(Icons.zoom_out_map, color: AppColors.textSecondary),
            onPressed: () => _showFullQuestionText(context, passedText),
            tooltip: 'عرض النص الكامل',
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        // Use a switch to build the UI based on the question type
        child: _buildQuestionBody(),
      ),
    );
  }

  Widget _buildQuestionBody() {
    switch (widget.question.questionType) {
      case QuestionType.askForTitle:
      case QuestionType.askForNumber:
      case QuestionType.askFromDef:
        return _buildMcqUi();
      case QuestionType.askToWriteTitle:
        return _buildWordGameUi();
      case QuestionType.matching:
        return _buildMatchingUi();
      default:
        return const Text('Unsupported Question Type');
    }
  }

  Widget _buildMcqUi() {
    // 1. Define button styles with explicit padding to make them more compact.
    final ButtonStyle baseStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w), // Control padding here
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce extra tap space
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
       _buildQuestionContainer(widget.question.questionText),
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

              // 2. Create the button widget WITHOUT the extra Padding widget.
              Widget button = ElevatedButton(
                style: currentStyle,
                onPressed: () => _handleSelection(choice),
                child: Text( // The child is now just the Text widget.
                  widget.question.questionType == QuestionType.askForTitle
                      ? choice.title
                      : choice.labelNumber.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
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
        // 1. The style is defined once and includes the disabled appearance.
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          minimumSize: Size(double.infinity, 50.h),
        ),

        // 2. This logic determines if the button is enabled (a function) or disabled (null).
        onPressed: (_isAnswered || _selectedAnswerId != null)
            ? () {
                // Action to perform when the button is tapped.
                if (_isAnswered) {
                  widget.onAnswered(_isLastAnswerCorrect ?? false);
                } else {
                  _handleCheck();
                }
              }
            : null, // Button is disabled if no answer is selected yet.

        // 3. The button's text changes based on the state.
        child: Text(
          widget.mode == QuestionMode.test ? 'التالي' : (_isAnswered ? 'التالي' : 'تحقق'),
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
      ],
    );
  }
 Widget _buildWordGameUi() {
  if (_isGameSetup) {
    bool allSlotsFilled = !_answerSlots.contains('');
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuestionContainer(_displayQuestionText),
          SizedBox(height: 20.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_answerSlots.length, (index) {
                final String currentChar = _answerSlots[index];
                Color boxColor;
                if (_isAnswered && _letterFeedback.length == _answerSlots.length) {
                  // After "Check" is pressed, use feedback colors
                  boxColor = _letterFeedback[index]! ? AppColors.correct : AppColors.incorrect;
                } else {
                  // Before "Check" is pressed, use the default colors
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
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold,
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
              // Replace the children of the letter bank Wrap with this:
              children: _letterBank.map((letter) {
                // letter is a simple String here, as per your current code.
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
                            fontSize: 20.sp,
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
          ElevatedButton(
            // 1. Define the style just ONCE.
            // This style includes the appearance for both enabled and disabled states.
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              minimumSize: Size(double.infinity, 50.h),
            ),

            onPressed: (_isAnswered || allSlotsFilled)
            ? () {
                if (_isAnswered) {
                  widget.onAnswered(_isLastAnswerCorrect ?? false);
                } else {
                  // --- START: NEW FEEDBACK LOGIC ---
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
                  // --- END: NEW FEEDBACK LOGIC ---
                }
              }
            : null,
            // 3. The child's text changes based on the state.
            child: Text(
              widget.mode == QuestionMode.test ? 'التالي' : (_isAnswered ? 'التالي' : 'تحقق'),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // If the game is NOT set up yet, run the setup logic.
  return LayoutBuilder(builder: (context, constraints) {
    // Use a post-frame callback to safely call setState after the build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Calculate max fittable letters based on width.
      final double boxSize = 40.w;
      final double spacing = 4.w; // 2w padding on each side
      final int maxLetters = ((constraints.maxWidth*0.95) / (boxSize + spacing)).floor();

      final title = widget.question.correctLabel.title;
      final words = title.split(' ');

      // 2. Find the INDEXES of all words that can fit on the screen.
      List<int> fittableWordIndexes = [];
      for (int i = 0; i < words.length; i++) {
        if (words[i].length <= maxLetters) {
          fittableWordIndexes.add(i);
        }
      }

      String wordToGuess;
      int chosenIndex;
      String toreplace = "------";

      // 3. Choose a word INDEX. Prioritize fittable words.
      if (fittableWordIndexes.isNotEmpty) {
        chosenIndex = (fittableWordIndexes..shuffle()).first;
        wordToGuess = words[chosenIndex];
        toreplace = '-' * wordToGuess.length;

      } else {
        
        // 1. Find the longest word.
        final longestWord = words.reduce((a, b) => a.length > b.length ? a : b);
        final longestWordIndex = words.indexOf(longestWord);

        // 2. The part to guess is the end of the word, sized to fit the screen.
        wordToGuess = longestWord.substring(longestWord.length - maxLetters);
        // The part to show is the beginning of the word.
        final String wordStem = longestWord.substring(0, longestWord.length - maxLetters);

        toreplace = '$wordStem${'_' * wordToGuess.length}';
        chosenIndex = longestWordIndex;
      }

      // 4. Construct the question text using the chosen INDEX.
      List<String> displayWords = List.from(words);
      displayWords[chosenIndex] = toreplace; // Replace only at the specific index
      final String blankedTitle = displayWords.join(' ');

      // The new question format that is always clear.
      final String displayQuestionText = 'أكمل اسم الجزء رقم ${widget.question.correctLabel.labelNumber}:\n"$blankedTitle"';

      // 5. Generate letter bank (logic is the same).
      final actualLetters = wordToGuess.split('');
      List<String> finalLetterBank = List.from(actualLetters);

      // 6. Set the state with all our prepared data.
      // We check if the widget is still in the tree to prevent errors.
      if (mounted) {
        setState(() {
          _wordToGuess = wordToGuess;
          _displayQuestionText = displayQuestionText;
          _answerSlots = List.generate(wordToGuess.length, (index) => '');
          _letterBank = finalLetterBank..shuffle();
          _isGameSetup = true; // CRUCIAL: Mark setup as complete.
        });
      }
    });

    // Show a loading indicator while the setup runs.
    return const Center(child: CircularProgressIndicator());
  });
}

// In your _QuestionWidgetState class

Widget _buildMatchingUi() {
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
      onPressed: () => _handleSelectionMatching(item, isNumber),
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
