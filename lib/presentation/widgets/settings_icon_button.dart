import 'package:flutter/material.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class SettingsIconButton extends StatelessWidget {
  final IconData onIcon;
  final IconData offIcon;
  final bool isOn;
  final VoidCallback onPressed;

  const SettingsIconButton({
    super.key,
    required this.onIcon,
    required this.offIcon,
    required this.isOn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(isOn ? onIcon : offIcon),
      color: isOn ? AppColors.primary : AppColors.textSecondary,
      iconSize: 32,
    );
  }
}