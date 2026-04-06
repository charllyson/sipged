import 'package:flutter/material.dart';

class PushPanelData {
  final String id;
  final String title;
  final IconData icon;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Widget child;

  const PushPanelData({
    required this.id,
    required this.title,
    required this.icon,
    this.initialWidth = 250,
    this.minWidth = 150,
    this.maxWidth = 500,
    this.child = const SizedBox.shrink(),
  });

  PushPanelData copyWith({
    String? id,
    String? title,
    IconData? icon,
    double? initialWidth,
    double? minWidth,
    double? maxWidth,
    Widget? child,
  }) {
    return PushPanelData(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      initialWidth: initialWidth ?? this.initialWidth,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      child: child ?? this.child,
    );
  }
}