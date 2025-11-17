import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }
}
