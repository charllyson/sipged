import 'package:flutter/material.dart';

class TextChangeData {
  final String title;
  final String text;
  final bool enabled;
  final double fontSize;
  final int colorValue;
  final FontWeight fontWeight;
  final double offsetX;
  final double offsetY;

  const TextChangeData({
    required this.title,
    required this.text,
    required this.enabled,
    required this.fontSize,
    required this.colorValue,
    required this.fontWeight,
    required this.offsetX,
    required this.offsetY,
  });

  TextChangeData copyWith({
    String? title,
    String? text,
    bool? enabled,
    double? fontSize,
    int? colorValue,
    FontWeight? fontWeight,
    double? offsetX,
    double? offsetY,
  }) {
    return TextChangeData(
      title: title ?? this.title,
      text: text ?? this.text,
      enabled: enabled ?? this.enabled,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      fontWeight: fontWeight ?? this.fontWeight,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}