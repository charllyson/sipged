// lib/screens/panels/overview-dashboard/general_dashboard_map.dart

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';

import 'package:sipged/_widgets/map/map/map_change.dart';

class GeneralDashboardMap extends StatelessWidget {
  final List<String> selectedRegionNames;
  final List<String> strongMunicipios;

  final void Function(String?) onRegionTap;
  final double? height;

  const GeneralDashboardMap({
    super.key,
    required this.selectedRegionNames,
    required this.strongMunicipios,
    required this.onRegionTap,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IBGELocationCubit>(
      create: (_) => IBGELocationCubit(
        repository: IBGELocationRepository(),
      )..loadInitialAuto(
        municipioNames: strongMunicipios,
        fallbackUfCode: 27,
      ),
      child: _OverviewDashboardMapBody(
        selectedRegionNames: selectedRegionNames,
        strongMunicipios: strongMunicipios,
        onRegionTap: onRegionTap,
        height: height,
      ),
    );
  }
}

class _OverviewDashboardMapBody extends StatefulWidget {
  final List<String> selectedRegionNames;
  final List<String> strongMunicipios;
  final void Function(String?) onRegionTap;
  final double? height;

  const _OverviewDashboardMapBody({
    required this.selectedRegionNames,
    required this.strongMunicipios,
    required this.onRegionTap,
    this.height,
  });

  @override
  State<_OverviewDashboardMapBody> createState() {
    return _OverviewDashboardMapBodyState();
  }
}

class _OverviewDashboardMapBodyState extends State<_OverviewDashboardMapBody>
    with AutomaticKeepAliveClientMixin<_OverviewDashboardMapBody> {
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _OverviewDashboardMapBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldStrong = _normSet(oldWidget.strongMunicipios);
    final newStrong = _normSet(widget.strongMunicipios);

    if (!setEquals(oldStrong, newStrong)) {
      context.read<IBGELocationCubit>().loadInitialAuto(
        municipioNames: widget.strongMunicipios,
        fallbackUfCode: 27,
      );
    }
  }

  String _norm(String s) {
    return removeDiacritics(s)
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _normSet(List<String> xs) {
    return xs.map(_norm).toSet();
  }

  String _polygonTitle(Polygon<Map<String, dynamic>> polygon) {
    final hit = polygon.hitValue;

    final value = hit?['title'] ??
        hit?['nome'] ??
        hit?['name'] ??
        hit?['NM_MUN'] ??
        hit?['processo'] ??
        polygon.label;

    return value?.toString().trim() ?? '';
  }

  List<LatLng> _geometryPointsFromPolygons(
      List<Polygon<Map<String, dynamic>>> polys,
      ) {
    if (polys.isEmpty) return const <LatLng>[];

    final pts = <LatLng>[];

    for (final polygon in polys) {
      pts.addAll(polygon.points);

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];

      for (final hole in holes) {
        pts.addAll(hole);
      }
    }

    return pts;
  }

  List<Polygon<Map<String, dynamic>>> _applyStrengthStyle({
    required List<Polygon<Map<String, dynamic>>> polys,
    required List<String> strongNames,
    required List<String> selectedNames,
  }) {
    if (polys.isEmpty) return polys;

    final strong = _normSet(strongNames);
    final selected = _normSet(selectedNames);

    const noDataFill = Color(0xFF9CA3AF);
    const noDataBorder = Color(0xFFB0B7C3);
    const noDataAlpha = 0.10;

    const dataFill = Color(0xFF9CA3AF);
    const dataBorder = Color(0xFFB0B7C3);
    const dataAlpha = 0.42;

    const filteredFill = Color(0xFF5AA7FF);
    const filteredBorder = Color(0xFF2E78D6);
    const filteredAlpha = 0.58;

    return polys.map((polygon) {
      final name = _polygonTitle(polygon);
      final nameNorm = _norm(name);

      final isSelected = selected.contains(nameNorm);
      final isStrong = strong.contains(nameNorm);

      final fill = isSelected
          ? filteredFill.withValues(alpha: filteredAlpha)
          : (isStrong ? dataFill : noDataFill).withValues(
        alpha: isStrong ? dataAlpha : noDataAlpha,
      );

      final border = isSelected
          ? filteredBorder
          : isStrong
          ? dataBorder
          : noDataBorder.withValues(alpha: 0.75);

      final stroke = isSelected
          ? 2.2
          : isStrong
          ? 1.0
          : 0.35;

      final hit = Map<String, dynamic>.from(polygon.hitValue ?? {});

      hit['title'] = hit['title'] ?? name;
      hit['nome'] = hit['nome'] ?? name;
      hit['processo'] = hit['processo'] ?? name;

      return Polygon<Map<String, dynamic>>(
        points: polygon.points,
        holePointsList: polygon.holePointsList ?? const <List<LatLng>>[],
        color: fill,
        borderColor: border,
        borderStrokeWidth: stroke,
        label: polygon.label,
        labelStyle: polygon.labelStyle,
        rotateLabel: polygon.rotateLabel,
        labelPlacementCalculator: polygon.labelPlacementCalculator,
        hitValue: hit,
      );
    }).toList(growable: false);
  }

  int _mapSignature({
    required IBGELocationState state,
    required List<Polygon<Map<String, dynamic>>> polygons,
  }) {
    return Object.hashAll([
      state.isLoading,
      state.errorMessage,
      polygons.length,
      Object.hashAll(widget.strongMunicipios.map(_norm)),
      Object.hashAll(widget.selectedRegionNames.map(_norm)),
      if (polygons.isNotEmpty) _polygonTitle(polygons.first),
      if (polygons.length > 1) _polygonTitle(polygons.last),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: widget.height ?? 320,
        width: double.infinity,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocBuilder<IBGELocationCubit, IBGELocationState>(
            buildWhen: (prev, curr) {
              return prev.isLoading != curr.isLoading ||
                  prev.errorMessage != curr.errorMessage ||
                  prev.cityPolygons != curr.cityPolygons ||
                  prev.states != curr.states;
            },
            builder: (context, state) {
              if (state.errorMessage != null &&
                  state.cityPolygons.isEmpty &&
                  state.states.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Erro ao carregar dados do IBGE:\n${state.errorMessage}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final styledPolys = _applyStrengthStyle(
                polys: state.cityPolygons,
                strongNames: widget.strongMunicipios,
                selectedNames: widget.selectedRegionNames,
              );

              final geomPoints = _geometryPointsFromPolygons(styledPolys);

              return MapChange(
                features: const <FeatureData>[],
                layersById: const <String, LayerData>{},
                orderedActiveLayerIds: const <String>[],

                selectedFeatureKey: null,
                loading: state.isLoading,

                visualDataSignature: _mapSignature(
                  state: state,
                  polygons: styledPolys,
                ),

                // Centro aproximado de Alagoas
                initialCenter: const LatLng(-9.5713, -36.7820),
                initialZoom: 7.8,

                // Zoom fixo para este painel
                minZoom: 7.8,
                maxZoom: 7.8,

                showSearch: false,
                showControls: true,

                // Oculta controles
                showZoomSlider: false,
                showMapTypeButton: false,
                showRotationButton: false,

                // Bloqueia interações de zoom e rotação
                enableZoom: false,
                enableRotation: false,

                // Mantém o arraste do mapa.
                // Se quiser travar totalmente, mude para false.
                enablePan: true,

                fitInitialGeometryOnce: true,
                initialGeometryPoints: geomPoints,

                externalPolygons: styledPolys,

                onControllerReady: (_) {},

                onFeatureTap: (_) {},

                onExternalPolygonTap: (polygon) {
                  if (polygon == null) {
                    widget.onRegionTap(null);
                    return;
                  }

                  final title = _polygonTitle(polygon);
                  widget.onRegionTap(title.isEmpty ? null : title);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}