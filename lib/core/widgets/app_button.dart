import 'package:flutter/material.dart';

import '../theme/ubarber_colors.dart';
import '../theme/ubarber_constants.dart';
import '../theme/ubarber_text_styles.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool expanded;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.color,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(
            title,
            style: UBarberTextStyles.button,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: UBarberTextStyles.button,
              ),
            ],
          );

    final button = SizedBox(
      height: UBarberConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? UBarberColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              (color ?? UBarberColors.primaryGreen).withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UBarberConstants.radiusLG,
            ),
          ),
        ),
        child: child,
      ),
    );

    if (!expanded) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}