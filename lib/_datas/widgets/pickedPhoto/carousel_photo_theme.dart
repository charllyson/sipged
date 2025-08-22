// lib/_widgets/carousel/styles/carousel_photo_theme.dart
import 'package:flutter/material.dart';

class CarouselPhotoTheme {
  final double itemSize;
  final double spacing;
  final BorderRadius borderRadius;
  final Color removerBg;
  final Color removerIconColor;
  final EdgeInsetsGeometry listPadding;

  const CarouselPhotoTheme({
    this.itemSize = 96,
    this.spacing = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.removerBg = const Color(0x73000000),
    this.removerIconColor = const Color(0xFFFFFFFF),
    this.listPadding = const EdgeInsets.only(left: 8),
  });
}
