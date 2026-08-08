// lib/_widgets/map/search/search_map_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/map/my_location/nominatim_cubit.dart';
import 'package:sipged/_widgets/map/search/search_overlay.dart';
import 'package:sipged/_widgets/map/search/search_suggestion.dart';
import 'package:sipged/_widgets/map/search/search_widget.dart';

class SearchMapButton extends StatefulWidget {
  const SearchMapButton({
    super.key,
    required this.mapController,
    required this.searchHitVN,
    this.searchActionBuilder,
    this.searchTargetZoom = 16,
    this.onMapTap,
    this.onMoved,
  });

  final MapController mapController;
  final ValueNotifier<LatLng?> searchHitVN;

  final Widget Function(void Function(String) onSearch)? searchActionBuilder;

  final double searchTargetZoom;

  final void Function(double lat, double lon)? onMapTap;
  final void Function(LatLng center, double zoom)? onMoved;

  @override
  State<SearchMapButton> createState() => _SearchMapButtonState();
}

class _SearchMapButtonState extends State<SearchMapButton> {
  LatLng? _parseLatLng(String raw) {
    final String q = raw.trim();

    if (q.isEmpty) return null;

    final String normalized = q
        .replaceAll(';', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final List<String> parts = normalized.contains(',')
        ? normalized.split(',')
        : normalized.split(' ');

    if (parts.length < 2) return null;

    final String latText = parts[0].trim().replaceAll(',', '.');
    final String lonText = parts[1].trim().replaceAll(',', '.');

    final double? lat = double.tryParse(latText);
    final double? lon = double.tryParse(lonText);

    if (lat == null || lon == null) return null;

    if (lat < -90 || lat > 90) return null;
    if (lon < -180 || lon > 180) return null;

    return LatLng(lat, lon);
  }

  Future<List<SearchSuggestion<dynamic>>> _fetchAddressSuggestions(
      String query,
      ) async {
    final String q = query.trim();

    if (q.length < 3) return const <SearchSuggestion<dynamic>>[];

    try {
      final cubit = context.read<NominatimCubit>();

      final results = await cubit.search(
        q,
        limit: 8,
      );

      return results
          .map(
            (result) => SearchSuggestion.address(
          id: result.id,
          title: result.title,
          subtitle: result.city ?? result.state ?? result.country,
          point: result.point,
        ),
      )
          .toList(growable: false);
    } catch (_) {
      return const <SearchSuggestion<dynamic>>[];
    }
  }

  void _onSuggestionTap(
      SearchSuggestion<dynamic> suggestion,
      void Function(String) onSearch,
      ) {
    final data = suggestion.data;

    if (data is LatLng) {
      onSearch('${data.latitude},${data.longitude}');
      return;
    }

    onSearch(suggestion.title);
  }

  Future<void> _onSearch(String text) async {
    final String q = text.trim();

    if (q.isEmpty) return;

    final LatLng? parsed = _parseLatLng(q);

    if (parsed != null) {
      _goTo(parsed);

      widget.onMapTap?.call(
        parsed.latitude,
        parsed.longitude,
      );

      return;
    }

    try {
      final cubit = context.read<NominatimCubit>();

      final LatLng? hit = await cubit.getCoordinates(q);

      if (!mounted) return;

      if (hit != null) {
        _goTo(hit);

        widget.onMapTap?.call(
          hit.latitude,
          hit.longitude,
        );

        return;
      }
    } catch (_) {}
  }

  void _goTo(LatLng point) {
    widget.searchHitVN.value = point;

    widget.mapController.move(
      point,
      widget.searchTargetZoom,
    );

    widget.onMoved?.call(
      point,
      widget.searchTargetZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.searchActionBuilder;

    if (builder != null) {
      return builder(_onSearch);
    }

    return SearchWidget(
      onSearch: _onSearch,
      fetchSuggestions: _fetchAddressSuggestions,
      onSuggestionTap: (suggestion) {
        _onSuggestionTap(
          suggestion,
          _onSearch,
        );
      },
      tooltip: 'Buscar endereço',
      backgroundColor: Colors.black38,
      iconColor: Colors.white,
      hintText: 'Buscar endereço ou "lat, lng"...',
      expandSide: SearchExpandSide.right,
      maxWidth: 320,
      height: 42,
    );
  }
}