import 'package:flutter/material.dart';

import '../theme/ubarber_colors.dart';
import '../theme/ubarber_constants.dart';
import '../theme/ubarber_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
final VoidCallback? onSuffixPressed;

  const AppTextField({
    super.key,
    required this.controller,
    this.suffixIcon,
    this.onSuffixPressed,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: UBarberConstants.inputHeight,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: UBarberTextStyles.input,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: UBarberTextStyles.hint,
         filled: false,

         prefixIcon: prefixIcon != null
    ? Icon(
        prefixIcon,
        color: UBarberColors.primaryBlue,
      )
    : null,

enabledBorder: const UnderlineInputBorder(
  borderSide: BorderSide(
    color: UBarberColors.primaryBlue,
    width: 1.5,
  ),
),

suffixIcon: suffixIcon != null
    ? IconButton(
        icon: suffixIcon!,
        onPressed: onSuffixPressed,
      )
    : null,
focusedBorder: const UnderlineInputBorder(
  borderSide: BorderSide(
    color: UBarberColors.primaryBlue,
    width: 2,
  ),
),
        ),
      ),
    );
  }
}