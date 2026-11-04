import 'package:flutter/material.dart';

import '../theme/ubarber_colors.dart';
import '../theme/ubarber_constants.dart';
import '../theme/ubarber_text_styles.dart';

class AppMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isArabic;

  const AppMenuItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isArabic,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? UBarberColors.primaryBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          UBarberConstants.radiusLG,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(
              UBarberConstants.radiusLG,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(
                    UBarberConstants.radiusMD,
                  ),
                ),
                child: Icon(
                  icon,
                  color: itemColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                      style: UBarberTextStyles.sectionTitle,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                      style: UBarberTextStyles.body.copyWith(
                        color: UBarberColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                isArabic
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: UBarberColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}