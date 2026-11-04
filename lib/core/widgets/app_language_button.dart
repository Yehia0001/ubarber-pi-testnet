import 'package:flutter/material.dart';

class AppLanguageButton extends StatelessWidget {
  final String currentLang;
  final VoidCallback onPressed;

  const AppLanguageButton({
    super.key,
    required this.currentLang,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.translate_rounded,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        currentLang == 'ar' ? 'EN' : 'AR',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
      ),
    );
  }
}