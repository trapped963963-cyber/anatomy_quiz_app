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

  void _handleAnswer(Label selectedAnswer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswerId = selectedAnswer.id;
    });

    final isCorrect = selectedAnswer.id == widget.question.correctLabel.id;
    final settings = ref.read(settingsProvider);

    // Play sound and haptics
    if (isCorrect) {
      ref.read(soundServiceProvider).playCorrectSound();
    } else {
      ref.read(soundServiceProvider).playIncorrectSound();
      if (settings['haptics']!) {
        HapticFeedback.heavyImpact();
      }
    }

    Timer(const Duration(milliseconds: 1200), () {
      widget.onAnswered(isCorrect);
    });
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

  // --- UI Builder for Multiple Choice Questions ---
Widget _buildMcqUi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The question text remains fixed at the top
        Container(
          constraints: BoxConstraints(
            maxHeight: 120.h, // Set a max height for the text area
          ),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          // This makes the text itself scrollable if it overflows the container
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Text(
                widget.question.questionText,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h), // Reduced spacing slightly

        // This Expanded section will take all remaining space and make its child scrollable
        Expanded(
          child: ListView.builder(
            itemCount: widget.question.choices.length,
            itemBuilder: (context, index) {
              final choice = widget.question.choices[index];
              Color tileColor = Colors.transparent;
              if (_isAnswered) {
                if (choice.id == widget.question.correctLabel.id) {
                  tileColor = AppColors.correct.withOpacity(0.3);
                } else if (choice.id == _selectedAnswerId) {
                  tileColor = AppColors.incorrect.withOpacity(0.3);
                }
              }

              return Card(
                color: tileColor,
                elevation: 2,
                child: ListTile(
                  title: Text(
                    widget.question.questionType == QuestionType.askForTitle
                        ? choice.title
                        : choice.labelNumber.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => _handleAnswer(choice),
                ),
              );
            },
          ),
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
          Text(_displayQuestionText, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
            children: _letterBank.map((letter) {
              return ElevatedButton(
                onPressed: () {
                  int emptyIndex = _answerSlots.indexOf('');
                  if (emptyIndex != -1) { setState(() { _answerSlots[emptyIndex] = letter; _letterBank.remove(letter); }); }
                },
                child: Text(letter, style: TextStyle(fontSize: 18.sp)),
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
