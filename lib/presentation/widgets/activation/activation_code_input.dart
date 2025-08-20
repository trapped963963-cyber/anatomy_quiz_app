import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class ActivationCodeInput extends StatefulWidget {
  final Function(String) onCompleted;
  
  const ActivationCodeInput({super.key, required this.onCompleted});

  @override
  State<ActivationCodeInput> createState() => _ActivationCodeInputState();
}

class _ActivationCodeInputState extends State<ActivationCodeInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  final int length = 12;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(length, (index) => FocusNode());
    _controllers = List.generate(length, (index) => TextEditingController());
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
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    final completeCode = _controllers.map((c) => c.text).join();
    if (completeCode.length == length) {
      widget.onCompleted(completeCode);
    }
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: 25.w,
      height: 40.h,
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
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          ),
        ),
        onChanged: (value) => _onTextChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Activation codes are typically LTR
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...List.generate(4, (index) => _buildBox(index)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: const Text('-', style: TextStyle(fontSize: 24)),
          ),
          ...List.generate(4, (index) => _buildBox(index + 4)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: const Text('-', style: TextStyle(fontSize: 24)),
          ),
          ...List.generate(4, (index) => _buildBox(index + 8)),
        ],
      ),
    );
  }
}