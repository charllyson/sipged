import 'package:flutter/material.dart';

class ScheduleLaneRowData {
  ScheduleLaneRowData({
    required this.id,
    required this.posCtrl,
    required this.nameCtrl,
    required this.altura,
    required this.color,
  });

  final String id; // ID estável para travas
  final TextEditingController posCtrl;
  final TextEditingController nameCtrl;
  double altura;
  Color color;
}