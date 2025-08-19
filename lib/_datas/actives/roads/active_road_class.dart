import 'package:flutter/material.dart';

/// Define um estilo visual aplicado a uma camada de linha (Polyline),
/// podendo incluir cor, espessura e deslocamento.
class ActiveRoadClass {
  /// Cor da linha.
  final Color cor;

  /// Espessura da linha (stroke width).
  final double width;

  /// Deslocamento ortogonal aplicado à linha (em unidades geográficas).
  final double dx;

  /// Cria uma nova camada de estilo com cor, largura e deslocamento opcional.
  const ActiveRoadClass({
    required this.cor,
    required this.width,
    this.dx = 0,
  });
}

