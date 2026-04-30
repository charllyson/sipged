import 'package:flutter/material.dart';

class MapData {
  final String nome;
  final String url;

  /// URL usada apenas como miniatura visual.
  ///
  /// Pode ser:
  /// - um tile real;
  /// - uma imagem fixa;
  /// - vazio, usando fallback desenhado.
  final String previewUrl;

  /// Descrição curta para painel expandido.
  final String description;

  /// Ícone de fallback.
  final IconData icon;

  /// Categoria visual.
  final String category;

  /// Cor de destaque do mapa na UI.
  final Color accentColor;

  /// Se false, aparece desabilitado.
  final bool enabled;

  const MapData({
    required this.nome,
    required this.url,
    this.previewUrl = '',
    this.description = '',
    this.icon = Icons.layers_rounded,
    this.category = 'base',
    this.accentColor = const Color(0xFF00838F),
    this.enabled = true,
  });

  String get urlTemplate => url;

  bool get hasMap => url.trim().isNotEmpty;

  bool get hasPreview => previewUrl.trim().isNotEmpty;

  String get shortName {
    final clean = nome.trim();
    if (clean.isEmpty) return 'Mapa';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first;

    return parts.take(2).join(' ');
  }
}