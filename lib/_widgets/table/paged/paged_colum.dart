import 'package:flutter/material.dart';

class PagedColum<T> {
  final String title;
  final String Function(T item)? getter;
  final Widget Function(T item)? cellBuilder;
  final Widget Function(BuildContext context)? headerBuilder;
  final TextAlign textAlign;

  /// largura real da coluna
  final double? width;

  /// limite opcional do conteúdo interno
  final double? maxWidth;

  const PagedColum({
    required this.title,
    this.getter,
    this.cellBuilder,
    this.headerBuilder,
    this.textAlign = TextAlign.left,
    this.width,
    this.maxWidth,
  });
}