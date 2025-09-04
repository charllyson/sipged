import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/format_field.dart';

class BuildValueChip extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  const BuildValueChip(
      this.title,
      this.value,
      this.icon, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$title: ${priceToString(value)}'),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
