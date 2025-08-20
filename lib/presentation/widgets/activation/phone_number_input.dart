import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class PhoneNumberInput extends StatefulWidget {
  final Function(String) onCompleted;

  const PhoneNumberInput({super.key, required this.onCompleted});

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

    // Pre-fill the first two boxes
    _controllers[0].text = '0';
    _controllers[1].text = '9';
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
    if (value.isNotEmpty && index < 9) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 1) { // Can't delete the pre-filled numbers
      _focusNodes[index - 1].requestFocus();
    }
    
    // Check if all fields are filled to call the onCompleted callback
    final completeNumber = _controllers.map((c) => c.text).join();
    if (completeNumber.length == 10) {
      widget.onCompleted(completeNumber);
    }
  }

  Widget _buildBox(int index) {
    bool isEnabled = index > 1; // Disable the first two boxes

    return SizedBox(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Force LTR for the phone number input
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (index) => _buildBox(index)),
      ),
    );
  }
}