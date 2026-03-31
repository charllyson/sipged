import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

class ChipCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  const ChipCard(
      this.title,
      this.value,
      this.icon, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$title: ${SipGedFormatMoney.doubleToText(value)}'),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
