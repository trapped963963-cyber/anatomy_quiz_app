import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class QuestionWidget extends ConsumerStatefulWidget {
  final Question question;
  final Function(bool isCorrect) onAnswered;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  ConsumerState<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends ConsumerState<QuestionWidget> {
  int? _selectedAnswerId;
  bool _isAnswered = false;

  // State for the Word Game
  List<String> _answerSlots = [];
  List<String> _letterBank = [];
  String _wordToGuess = '';
  String _displayQuestionText = '';
  bool _wordGameCompleted = false;
  bool _isGameSetup = false;
  
  
  // State for the Matching Game
  List<Label> _remainingNumbers = [];
  List<Label> _remainingTitles = [];
  Label? _selectedNumber;
  Label? _selectedTitle;
  bool _isCheckingMatch = false;
  Set<int> _disappearingIds = {}; 
  
  @override
  void initState() {
    super.initState();
    if (widget.question.questionType == QuestionType.askToWriteTitle) {
      //_setupWordGame();
    } else if (widget.question.questionType == QuestionType.matching) {
      _setupMatchingGame();
    }
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
  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when the question changes
    if (widget.question != oldWidget.question) {
      setState(() {
        _selectedAnswerId = null;
        _isAnswered = false;
        _isGameSetup = false;

        if (widget.question.questionType == QuestionType.matching) {
          _setupMatchingGame();
        }
      });
    }
  }

  // This new method is called when the user taps an option.
  void _handleSelection(Label selectedChoice) {
    // Do nothing if the answer has already been checked and locked in.
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerId = selectedChoice.id;
    });
  }

  // This new method is called when the user presses the "Check" button.
  void _handleCheck() {
    // Do nothing if no answer is selected or if it's already been checked.
    if (_selectedAnswerId == null || _isAnswered) return;

    final selectedChoice = widget.question.choices.firstWhere((c) => c.id == _selectedAnswerId);
    final isCorrect = selectedChoice.id == widget.question.correctLabel.id;
    final settings = ref.read(settingsProvider);

    // Lock the question and show the red/green feedback colors.
    setState(() {
      _isAnswered = true;
    });

    // Play sound and haptics.
    if (isCorrect) {
      ref.read(soundServiceProvider).playCorrectSound();
    } else {
      ref.read(soundServiceProvider).playIncorrectSound();
      if (settings['haptics']!) {
        HapticFeedback.heavyImpact();
      }
    }

    // Wait a moment before telling the parent screen to move to the next question.
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onAnswered(isCorrect);
      }
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
          // ## FIX: Height is now relative to the screen ##
          constraints: BoxConstraints(maxHeight: screenHeight * 0.5), // 50% of screen height
          child: Padding(
            // ## FIX: Horizontal padding makes it not touch the edges ##
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
          padding: EdgeInsets.all(7.w),
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
          left: 0,
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
          onPressed: (_selectedAnswerId != null && !_isAnswered) ? _handleCheck : null,
          child: const Text('تحقق'),
        ),
      ],
    );
  }
 Widget _buildWordGameUi() {
  // If the game has already been set up for this question, build the UI.
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
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: GestureDetector(
                    onTap: () { if (currentChar.isNotEmpty) { setState(() { _letterBank.add(_answerSlots[index]); _answerSlots[index] = ''; }); } },
                    child: Container(
                      width: 40.w, height: 40.h,
                      decoration: BoxDecoration(
                        color: currentChar.isNotEmpty ? Colors.blue.shade100 : Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(child: Text(currentChar, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold))),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 24.h),
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
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: allSlotsFilled ? () { final userAnswer = _answerSlots.join(''); final isCorrect = userAnswer == _wordToGuess; widget.onAnswered(isCorrect); } : null,
            child: const Text('تحقق'),
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
      final int maxLetters = (constraints.maxWidth / (boxSize + spacing)).floor();

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

      // 3. Choose a word INDEX. Prioritize fittable words.
      if (fittableWordIndexes.isNotEmpty) {
        chosenIndex = (fittableWordIndexes..shuffle()).first;
        wordToGuess = words[chosenIndex];
      } else {
        // Fallback: As you noted, we could skip the question here.
        // For now, we'll find the index of the shortest word as a fallback.
        String shortestWord = words.reduce((a, b) => a.length < b.length ? a : b);
        chosenIndex = words.indexOf(shortestWord);
        wordToGuess = shortestWord;
      }

      // 4. Construct the question text using the chosen INDEX.
      List<String> displayWords = List.from(words);
      displayWords[chosenIndex] = '______'; // Replace only at the specific index
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

  Widget _buildMatchingUi() {
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

        // This delay is now just for showing the red/green feedback.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;

          if (isCorrect) {
            // 1. Trigger the fade-out animation.
            setState(() {
              _disappearingIds.add(_selectedNumber!.id);
            });

            // 2. After the animation, permanently remove the items.
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
          } else {
            // If incorrect, just reset the selections.
            setState(() {
              _selectedNumber = null;
              _selectedTitle = null;
              _isCheckingMatch = false;
            });
          }
        });
      }
    }

    return Column(
      children: [
        Text(
          widget.question.questionText,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        // Titles Pool
        _buildChoicePool(_remainingTitles, false, _selectedTitle, _handleSelection),
        SizedBox(height: 16.h),
        // Numbers Pool
        _buildChoicePool(_remainingNumbers, true, _selectedNumber, _handleSelection),
      ],
    );
  }

  // Helper widget to build a single scrollable pool.
  Widget _buildChoicePool(List<Label> items, bool isNumberPool, Label? selectedItem, Function(Label, bool) onSelect) {
    return SizedBox(
      height: 60.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: items.map((item) {
            final bool isSelected = selectedItem?.id == item.id;
            final bool isCorrectMatch = _selectedNumber?.id == _selectedTitle?.id;

            Color chipColor = Theme.of(context).chipTheme.backgroundColor ?? Colors.grey.shade200;
            Widget? avatar;

            if (_isCheckingMatch && isSelected) {
              chipColor = isCorrectMatch ? AppColors.correct : AppColors.incorrect;
              // ## 'X' ICON FIX ##
              // If the match is incorrect, show an 'X' icon.
              if (!isCorrectMatch) {
                avatar = const Icon(Icons.close, color: Colors.white, size: 18);
              }
            } else if (isSelected) {
              chipColor = AppColors.accent;
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              // ## ANIMATION FIX ##
              // This widget will animate the opacity change when an item is disappearing.
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _disappearingIds.contains(item.id) ? 0.0 : 1.0,
                child: ChoiceChip(
                  avatar: avatar,
                  label: Text(isNumberPool ? item.labelNumber.toString() : item.title),
                  selected: isSelected,
                  onSelected: (val) {
                    // Prevent tapping an already disappearing item.
                    if (_disappearingIds.contains(item.id)) return;
                    onSelect(item, isNumberPool);
                  },
                  selectedColor: chipColor,
                  backgroundColor: chipColor,
                  labelStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  // Make the checkmark invisible, since we use color instead.
                  showCheckmark: false, 
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

 
}
