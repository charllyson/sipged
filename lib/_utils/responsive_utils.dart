import 'package:flutter/material.dart';

double responsiveInputWidth({
  required BuildContext context,
  required int itemsPerLine,
  double spacing = 12.0,           // Espaço entre campos
  double margin = 12.0,            // Margem lateral do container

  double extraPadding = 0.0,       // Padding adicional interno, se houver
  double reservedWidth = 0.0,      // Largura de elementos fixos (ex: botão de PDF)
  double spaceBetweenReserved = 0.0, // Espaço entre elementos fixos e inputs

  double? minWidthSmallScreen,     // Largura mínima para telas pequenas
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  if ( screenWidth < 600) {
    return screenWidth - margin - 32;
  }else{
    final totalSpacing = spacing * (itemsPerLine - 1);
    final totalMargins = margin * 2;
    final availableWidth = screenWidth - totalSpacing - totalMargins - extraPadding - reservedWidth - spaceBetweenReserved;

    return availableWidth / itemsPerLine;
  }
}

