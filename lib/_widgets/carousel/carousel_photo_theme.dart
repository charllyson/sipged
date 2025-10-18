// lib/_blocs/widgets/carousel/carousel_photo_theme.dart
import 'package:flutter/material.dart';

class CarouselPhotoTheme {
  /// Tamanho (largura/altura) de cada miniatura
  final double itemSize;

  /// Espaçamento horizontal entre itens
  final double spacing;

  /// Padding da ListView horizontal
  final EdgeInsets listPadding;

  /// Raio de borda das miniaturas
  final BorderRadius borderRadius;

  /// Fundo do “X” de remover (o erro estava aqui)
  final Color removerBg;

  /// Cor do ícone “X” (o erro estava aqui)
  final Color removerIconColor;


  const CarouselPhotoTheme({
    this.itemSize = 96.0,
    this.spacing = 10.0,
    this.listPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.removerBg = const Color(0xB3000000),   // preto com ~70% opacidade
    this.removerIconColor = Colors.white,       // ícone branco
  });


}
