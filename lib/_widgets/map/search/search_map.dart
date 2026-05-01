import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';
import 'package:sipged/_services/map/map_box/service/nominatim_service.dart';
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
  late final NominatimService _geocoder = NominatimService.nominatim(
    userAgent: 'siged-app/1.0 (org.gov.br)',
    acceptLanguage: 'pt-BR',
    countryCodes: 'br',
    limit: 1,
  );

  void _notify(
      String title, {
        NotificationType type = NotificationType.info,
        String? subtitle,
        Duration duration = const Duration(seconds: 4),
      }) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Mapa',
        type: type,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'map_interactive',
        },
      ),
      saveInFirebase: false,
    );
  }

  LatLng? _parseLatLng(String raw) {
    final q = raw.trim();

    if (q.isEmpty) return null;

    final normalized = q
        .replaceAll(';', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = normalized.contains(',')
        ? normalized.split(',')
        : normalized.split(' ');

    if (parts.length < 2) return null;

    final latText = parts[0].trim().replaceAll(',', '.');
    final lonText = parts[1].trim().replaceAll(',', '.');

    final lat = double.tryParse(latText);
    final lon = double.tryParse(lonText);

    if (lat == null || lon == null) return null;

    if (lat < -90 || lat > 90) return null;
    if (lon < -180 || lon > 180) return null;

    return LatLng(lat, lon);
  }

  Future<List<SearchSuggestion<dynamic>>> _fetchAddressSuggestions(
      String q,
      ) async {
    if (q.trim().length < 3) return const [];

    final results = await _geocoder.search(q, limit: 8);

    return results
        .map(
          (r) => SearchSuggestion.address(
        id: r.id,
        title: r.title,
        subtitle: r.city ?? r.state ?? r.country,
        point: r.point,
      ),
    )
        .toList(growable: false);
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
    final q = text.trim();

    if (q.isEmpty) return;

    final parsed = _parseLatLng(q);

    if (parsed != null) {
      _goTo(parsed);
      widget.onMapTap?.call(parsed.latitude, parsed.longitude);
      return;
    }

    try {
      final hit = await _geocoder.geocode(q);

      if (hit != null) {
        _goTo(hit);
        widget.onMapTap?.call(hit.latitude, hit.longitude);
        return;
      }
    } catch (_) {}

    _notify(
      'Não encontrado',
      subtitle: 'Tente “lat, lng” ou refine a busca.',
      type: NotificationType.warning,
    );
  }

  void _goTo(LatLng point) {
    widget.searchHitVN.value = point;

    widget.mapController.move(
      point,
      widget.searchTargetZoom,
    );

    widget.onMoved?.call(point, widget.searchTargetZoom);
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
      onSuggestionTap: (s) => _onSuggestionTap(s, _onSearch),
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