import 'package:flutter/material.dart';

class CarouselPhotoTheme {
  final double itemSize;
  final double spacing;
  final EdgeInsets listPadding;
  final BorderRadius borderRadius;
  final Color removerBg;
  final Color removerIconColor;

  const CarouselPhotoTheme({
    this.itemSize = 96.0,
    this.spacing = 10.0,
    this.listPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.removerBg = const Color(0xB3000000),
    this.removerIconColor = Colors.white,
  });
}