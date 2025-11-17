import 'package:flutter/material.dart';

class HubCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}