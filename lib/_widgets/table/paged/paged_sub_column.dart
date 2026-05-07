import 'package:flutter/material.dart';

class PagedSubColumn<T> {
  const PagedSubColumn({
    required this.title,
    required this.valueBuilder,
    this.width = 160,
    this.maxWidth,
    this.textAlign = TextAlign.left,
    this.fontWeight,
    this.maxLines = 1,
  });

  final String title;
  final String Function(T item) valueBuilder;

  /// Largura real da coluna da subtabela.
  final double width;

  /// Limite opcional do conteúdo interno.
  final double? maxWidth;

  final TextAlign textAlign;
  final FontWeight? fontWeight;
  final int maxLines;
}
