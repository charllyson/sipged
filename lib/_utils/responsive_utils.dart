import 'package:flutter/material.dart';

double responsiveInputsOnePerLine(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  const margin = 16.0; // Ex: padding lateral de 16 em cada lado = 32
  return screenWidth - margin * 2;
}

double responsiveInputsTwoPerLine(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  const spacing = 12.0;
  const margin = 16.0;

  final totalSpacing = spacing;
  final availableWidth = screenWidth - margin * 2 - totalSpacing;
  return availableWidth / 2;
}


double responsiveInputsThreePerLine(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  const spacing = 12;
  const margin = 12;

  if (screenWidth < 600) {
    return screenWidth - margin - 32;
  } else if (screenWidth < 1000) {
    return (screenWidth - spacing - margin * 1 - 32) / 2;
  } else {
    return (screenWidth - spacing - margin * 2 - 32) / 3;
  }
}

double responsiveInputsFourPerLine(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  const spacing = 12.0; // espaçamento entre inputs
  const margin = 16.0;  // padding lateral (por exemplo, 16px em cada lado = 32 total)

  if (screenWidth < 600) {
    // Em telas pequenas, ocupa a largura total (menos margens)
    return screenWidth - margin * 2;
  } else {
    // Espaço total menos margens e espaçamentos entre 4 inputs
    final totalSpacing = spacing * 3; // 3 espaçamentos entre 4 campos
    final availableWidth = screenWidth - margin * 2 - totalSpacing;
    return availableWidth / 4;
  }
}