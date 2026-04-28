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
  const SearchSuggestion({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.data,
    this.kind = SuggestionKind.custom,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T? data;
  final SuggestionKind kind;

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

  static SearchSuggestion<LatLng> coordinate({
    required String id,
    required String title,
    String? subtitle,
    LatLng? point,
  }) {
    return SearchSuggestion<LatLng>(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: Icons.my_location_outlined,
      data: point,
      kind: SuggestionKind.coordinate,
    );
  }
}

typedef AddressSuggestion = SearchSuggestion<LatLng>;