import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum SuggestionKind {
  address,
  coordinate,
  contract,
  user,
  roadSegment,
  custom,
}

class SearchSuggestion<T> {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T? data;
  final SuggestionKind kind;

  const SearchSuggestion({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.data,
    this.kind = SuggestionKind.custom,
  });

  /// ✅ Método estático (não-factory) para criar sugestão de endereço (LatLng)
  static SearchSuggestion<LatLng> address({
    required String id,
    required String title,
    String? subtitle,
    IconData? icon,
    LatLng? point,
  }) {
    return SearchSuggestion<LatLng>(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon ?? Icons.place_outlined,
      data: point,
      kind: SuggestionKind.address,
    );
  }
}

/// (Opcional) Alias para reaproveitar em telas onde você só trabalha com endereços
typedef AddressSuggestion = SearchSuggestion<LatLng>;
