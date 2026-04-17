import 'package:flutter/material.dart';

class ResumeData {
  final String label;
  final double? value;
  final Color backgroundColor;
  final FontWeight? fontWeight;

  ResumeData({
    required this.label,
    required this.value,
    required this.backgroundColor,
    this.fontWeight
  });

  factory ResumeData.empty() {
    return ResumeData(
      label: '',
      value: null,
      backgroundColor: Colors.transparent,
    );
  }
}