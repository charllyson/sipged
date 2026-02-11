import 'package:flutter/material.dart';
import 'package:siged/_utils/theme/sipged_theme.dart';

class SectionTitle extends StatelessWidget {
  final String? text;
  const SectionTitle({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12.0, bottom: 12.0),
      child: Text(
        text ?? '',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: SipGedTheme.primaryColor,
        ),
      ),
    );
  }
}