import 'package:flutter/material.dart';

import '../theme/ubarber_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final TextAlign textAlign;

  const SectionTitle({
    super.key,
    required this.title,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      style: UBarberTextStyles.sectionTitle,
    );
  }
}