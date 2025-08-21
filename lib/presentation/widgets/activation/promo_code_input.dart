import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class PromoCodeInput extends StatefulWidget {
  final Function(String) onCompleted;
  // Added for consistency and better state management in the parent.
  final Function(String) onValueChanged;

  const PromoCodeInput({
    super.key,
    required this.onCompleted,
    required this.onValueChanged,
  });

  @override
  State<PromoCodeInput> createState() => PromoCodeInputState();
}

class PromoCodeInputState extends State<PromoCodeInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  final int length = 5;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(length, (index) => FocusNode());
    _controllers = List.generate(length, (index) => TextEditingController());

    // ## NEW: "JUMP TO NEXT EMPTY" LOGIC ##
    // Add a listener to each focus node.
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        // If any box gains focus...
        if (_focusNodes[i].hasFocus) {
          // ...immediately find the first empty controller.
          int firstEmptyIndex = _controllers.indexWhere(
            (controller) => controller.text.isEmpty,
          );

          // If an empty box is found...
          if (firstEmptyIndex != -1) {
            // ...and it's not the one that's already focused, move the focus there.
            if (!_focusNodes[firstEmptyIndex].hasFocus) {
              _focusNodes[firstEmptyIndex].requestFocus();
            }
          } else {
            // If all boxes are full, move focus to the very last box.
            if (!_focusNodes[length - 1].hasFocus) {
              _focusNodes[length - 1].requestFocus();
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

  void paste(String code) {
    // Sanitize the input to only include alphanumeric characters
    final sanitizedCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Determine how many characters to paste (max is 5)
    final lengthToPaste = sanitizedCode.length > length ? length : sanitizedCode.length;

    // Fill the controllers with the pasted characters
    for (int i = 0; i < lengthToPaste; i++) {
      _controllers[i].text = sanitizedCode[i];
    }

    // After pasting, trigger the change handler to update the parent widget
    // and move the focus to the correct position.
    if (lengthToPaste > 0) {
      _onTextChanged(_controllers[lengthToPaste - 1].text, lengthToPaste - 1);
      if (lengthToPaste < length) {
        _focusNodes[lengthToPaste].requestFocus();
      }
    }
  }
  
  void _onTextChanged(String value, int index) {
    // This method now only needs to handle moving the focus FORWARD.
    if (value.isNotEmpty && index < length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final completeCode = _controllers.map((c) => c.text).join();
    widget.onValueChanged(completeCode); // Notify parent on every change.
    if (completeCode.length == length) {
      widget.onCompleted(completeCode);
    }
  }

  Widget _buildBox(int index) {
    return Focus(
      // ## NEW: SMART BACKSPACE LOGIC ##
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.backspace &&
            event is KeyDownEvent) {
          // If the field is ALREADY empty when backspace is pressed,
          // then we handle the event ourselves.
          if (_controllers[index].text.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            return KeyEventResult.handled; // We took control of the event.
          }
        }
        return KeyEventResult.ignored; // Let the TextFormField handle it normally.
      },
      child: SizedBox(
        width: 50.w,
        height: 60.h,
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
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
      textDirection: TextDirection.ltr, // Codes are usually LTR
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(length, (index) => _buildBox(index)),
      ),
    );
  }
}