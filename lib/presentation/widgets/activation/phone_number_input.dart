import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';


class PhoneNumberInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String) onValueChanged;
  final String? initialValue;

  const PhoneNumberInput({
    super.key,
    required this.onCompleted,
    required this.onValueChanged,
    this.initialValue,
  });

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  @override
void initState() {
  super.initState();
  _focusNodes = List.generate(10, (index) => FocusNode());
  _controllers = List.generate(10, (index) => TextEditingController());

  _controllers[0].text = '0';
  _controllers[1].text = '9';

  if (widget.initialValue != null && widget.initialValue!.length == 10) {
    for (int i = 2; i < 10; i++) {
      _controllers[i].text = widget.initialValue![i];
    }
  }
  // ## THIS IS THE NEW LOGIC ##
  // Add a listener to each focus node.
  for (int i = 0; i < _focusNodes.length; i++) {
    _focusNodes[i].addListener(() {
      // If any box gains focus...
      if (_focusNodes[i].hasFocus) {
        // ...immediately find the first empty controller after the '09' prefix.
        int firstEmptyIndex = _controllers.indexWhere(
          (controller) => controller.text.isEmpty,
          2, // Start searching from index 2
        );

        // If an empty box is found...
        if (firstEmptyIndex != -1) {
          // ...and it's not the one that's already focused, move the focus there.
          if (!_focusNodes[firstEmptyIndex].hasFocus) {
            _focusNodes[firstEmptyIndex].requestFocus();
          }
        } else {
          // If all boxes are full, move focus to the very last box.
          if (!_focusNodes[9].hasFocus) {
            _focusNodes[9].requestFocus();
          }
        }
      }
    });
  }
}
  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // This method now only handles moving the focus FORWARD.
  void _onTextChanged(String value, int index) {
    if (value.isNotEmpty && index < 9) {
      _focusNodes[index + 1].requestFocus();
    }

    final completeNumber = _controllers.map((c) => c.text).join();

    widget.onValueChanged(completeNumber);
    if (completeNumber.length == 10) {
      widget.onCompleted(completeNumber);
    }
  }
  
  Widget _buildBox(int index) {
    bool isEnabled = index > 1;

    return Focus(
        onKeyEvent: (node, event) { // <-- 1. Renamed to onKeyEvent
        // We listen on KeyDownEvent to check the state of the field
        // BEFORE the TextFormField processes the key press.
        if (event.logicalKey == LogicalKeyboardKey.backspace && event is KeyDownEvent) {

          // If the field is ALREADY empty when backspace is pressed,
          // then we handle the event ourselves.
          if (_controllers[index].text.isEmpty && index > 2) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            return KeyEventResult.handled; // We took control of the event.
          }
        }
          return KeyEventResult.ignored;
        },
      child: SizedBox(
        width: 32.w,
        height: 48.h,
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: isEnabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          onChanged: (value) => _onTextChanged(value, index),
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (index) => _buildBox(index)),
      ),
    );
  }
}