import 'package:flutter/material.dart';
import 'ubarber_colors.dart';

class UBarberTextStyles {
  UBarberTextStyles._();

  static const TextStyle appTitle = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: UBarberColors.white,
    letterSpacing: -1,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: UBarberColors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: UBarberColors.white,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    color: UBarberColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: UBarberColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: UBarberColors.white,
  );

  static const TextStyle input = TextStyle(
    fontSize: 17,
    color: UBarberColors.white,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 16,
    color: UBarberColors.textHint,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: UBarberColors.textHint,
  );
}