import 'package:flutter/material.dart';
import 'package:siged/_utils/colors/colors_system_change.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: ColorsSystemChange.primaryColor,
        ),
      ),
    );
  }
}