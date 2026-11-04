import 'package:flutter/material.dart';

import '../theme/ubarber_colors.dart';
import '../theme/ubarber_constants.dart';

class AppTopBar extends StatelessWidget {
  final String currentLang;
  final VoidCallback onLanguageChanged;

  const AppTopBar({
    super.key,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLang == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (isArabic) const Spacer(),

          TextButton.icon(
            onPressed: onLanguageChanged,
            icon: const Icon(
              Icons.translate_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              isArabic ? 'EN' : 'AR',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor:
                  Colors.white.withOpacity(0.10),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  UBarberConstants.radiusMD,
                ),
              ),
            ),
          ),

          if (!isArabic) const Spacer(),
        ],
      ),
    );
  }
}