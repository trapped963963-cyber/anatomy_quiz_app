import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class ActivationCodeInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String) onValueChanged;

  const ActivationCodeInput({
    super.key,
    required this.onCompleted,
    required this.onValueChanged,
  });

  @override
  State<ActivationCodeInput> createState() => ActivationCodeInputState();
}

// Made the state public to be accessible by the parent screen's GlobalKey
class ActivationCodeInputState extends State<ActivationCodeInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  final int length = 12;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(length, (index) => FocusNode());
    _controllers = List.generate(length, (index) => TextEditingController());

    // "Jump to next empty" focus logic
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          int firstEmptyIndex =
              _controllers.indexWhere((c) => c.text.isEmpty);
          if (firstEmptyIndex != -1) {
            if (!_focusNodes[firstEmptyIndex].hasFocus) {
              _focusNodes[firstEmptyIndex].requestFocus();
            }
          } else {
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

  void _onTextChanged(String value, int index) {
    if (value.isNotEmpty && index < length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final completeCode = _controllers.map((c) => c.text).join();
    widget.onValueChanged(completeCode);
    if (completeCode.length == length) {
      widget.onCompleted(completeCode);
    }
  }

  // Public method to allow pasting from the parent screen
  void paste(String code) {
    final sanitizedCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final lengthToPaste = sanitizedCode.length > length ? length : sanitizedCode.length;

    for (int i = 0; i < lengthToPaste; i++) {
      _controllers[i].text = sanitizedCode[i];
    }

    if (lengthToPaste > 0) {
      _onTextChanged(_controllers[lengthToPaste - 1].text, lengthToPaste - 1);
      if (lengthToPaste < length) {
        _focusNodes[lengthToPaste].requestFocus();
      }
    }
  }

  Widget _buildBox(int index) {
    return Focus(
      // Smart backspace logic
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.backspace && event is KeyDownEvent) {
          if (_controllers[index].text.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
child: SizedBox(
        width: 40.r, // Adjusted size
        height: 48.r,
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
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
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
      )
    );
  }

  // Helper to build a row of 4 boxes
  Widget _buildRow(int startIndex) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) => _buildBox(startIndex + i)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // New multi-line layout
    return Column(
      children: [
        _buildRow(0),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: SizedBox(width: 100.w, child: const Divider()),
        ),
        _buildRow(4),
         Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: SizedBox(width: 100.w, child: const Divider()),
        ),
        _buildRow(8),
      ],
    );
  }
}