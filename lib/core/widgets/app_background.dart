import 'package:flutter/material.dart';
import '../theme/ubarber_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
  decoration: const BoxDecoration(
  color: UBarberColors.background,
  image: DecorationImage(
    image: AssetImage('assets/images/register_bg.jpg'),
    fit: BoxFit.cover,
  ),
),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
        color: Colors.black.withOpacity(0.25),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    UBarberColors.primaryBlue,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}