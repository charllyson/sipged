import 'package:flutter/material.dart';

class LayerRuleColumn<T> {
  final String title;
  final double width;
  final Widget Function(T item) cellBuilder;

  const LayerRuleColumn({
    required this.title,
    required this.width,
    required this.cellBuilder,
  });
}

class RuleTableColumn {
  final String title;
  final double width;

  const RuleTableColumn({
    required this.title,
    required this.width,
  });
}
