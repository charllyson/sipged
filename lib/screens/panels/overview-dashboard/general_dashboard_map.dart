// lib/screens/panels/overview-dashboard/general_dashboard_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';

class GeneralDashboardMap extends StatelessWidget {
  /// MUNICÍPIOS selecionados (para destaque mais forte)
  final List<String> selectedRegionNames;

  /// Todos os municípios que possuem contratos (para estilo "forte")
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
      create: (_) => IBGELocationCubit(repository: IBGELocationRepository())
        ..loadInitialAuto(
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
  State<_OverviewDashboardMapBody> createState() =>
      _OverviewDashboardMapBodyState();
}

class _OverviewDashboardMapBodyState extends State<_OverviewDashboardMapBody>
    with AutomaticKeepAliveClientMixin<_OverviewDashboardMapBody> {
  MapController? _mapController;

  /// Garante que o "fit bounds" seja aplicado apenas uma vez,
  /// para não brigar com o zoom/pan do usuário.
  bool _hasFitToPolygonsOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _OverviewDashboardMapBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Quando a lista de municípios com contratos muda de vazia -> preenchida,
    // chamamos novamente o loadInitialAuto para o Cubit inferir a UF certa.
    final oldEmpty = oldWidget.strongMunicipios.isEmpty;
    final newNotEmpty = widget.strongMunicipios.isNotEmpty;

    if (oldEmpty && newNotEmpty) {
      final cubit = context.read<IBGELocationCubit>();
      cubit.loadInitialAuto(
        municipioNames: widget.strongMunicipios,
      );
      _hasFitToPolygonsOnce = false;
    }
  }

  /// Junta todos os pontos dos polígonos para centralizar o mapa.
  List<LatLng> _geometryPointsFromPolygons(List<PolygonChangedData> polys) {
    if (polys.isEmpty) return const <LatLng>[];
    final pts = <LatLng>[];
    for (final p in polys) {
      pts.addAll(p.polygon.points);
    }
    return pts;
  }

  /// Aplica um fit-to-bounds suave, respeitando os limites do container.
  void _fitToPolygons(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(points);

      final cameraFit = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(16),
      );

      _mapController!.fitCamera(cameraFit);
      _hasFitToPolygonsOnce = true;
    } catch (_) {
      _hasFitToPolygonsOnce = true;
    }
  }

  /// ✅ Normaliza do mesmo jeito do MapInteractive (pra bater com strongMunicipios)
  String _norm(String s) =>
      s
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  Set<String> _normSet(List<String> xs) => xs.map(_norm).toSet();

  /// ✅ Aplica “forte/fraco” diretamente no PolygonChanged.
  /// Agora não existe mais strongPolygonNames no MapInteractive.
  List<PolygonChangedData> _applyStrengthStyle({
    required List<PolygonChangedData> polys,
    required List<String> strongNames,
  }) {
    if (polys.isEmpty) return polys;

    final strong = _normSet(strongNames);

    // 🎨 noData mais “clean”
    const noDataFill = Color(0xFF9CA3AF);      // cinza claro
    const noDataBorder = Color(0xFFB0B7C3);    // ✅ cinza ainda mais claro (linha)
    const noDataAlpha = 0.10;                 // bem transparente

// (data/selected mantém como está)
    const dataFill = Color(0xFF5AA7FF);
    const dataBorder = Color(0xFF2E78D6);

    const selectedFill = Color(0xFF1E6BFF);
    const selectedBorder = Color(0xFF0B2F7A);

    const dataAlpha = 0.42;
    const selectedAlpha = 0.62;

    return polys.map((p) {
      final isStrong = strong.contains(_norm(p.title));

      return p.copyWith(
        normalFillColor: (isStrong ? dataFill : noDataFill)
            .withValues(alpha: isStrong ? dataAlpha : noDataAlpha),

        // ✅ borda noData cinza clara e fina
        normalBorderColor: isStrong ? dataBorder : noDataBorder.withValues(alpha: 0.75),
        normalBorderWidth: isStrong ? 1.0 : 0.35,   // ✅ mais fina

        selectedFillColor: selectedFill.withValues(alpha: selectedAlpha),
        selectedBorderColor: selectedBorder,
        selectedBorderWidth: isStrong ? 2.2 : 2.0,
      );
    }).toList(growable: false);
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
            buildWhen: (prev, curr) =>
            prev.isLoading != curr.isLoading ||
                prev.errorMessage != curr.errorMessage ||
                prev.cityPolygons != curr.cityPolygons ||
                prev.states != curr.states,
            builder: (context, state) {
              if (state.errorMessage != null &&
                  state.cityPolygons.isEmpty &&
                  state.states.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Erro ao carregar dados do IBGE:\n${state.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // ✅ Polígonos com estilo forte/fraco aplicado no modelo
              final styledPolys = _applyStrengthStyle(
                polys: state.cityPolygons,
                strongNames: widget.strongMunicipios,
              );

              // pontos para o MapInteractive centralizar / encaixar
              final geomPoints = _geometryPointsFromPolygons(styledPolys);

              if (!_hasFitToPolygonsOnce &&
                  _mapController != null &&
                  geomPoints.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitToPolygons(geomPoints);
                });
              }

              return MapInteractivePage<void>(
                initialGeometryPoints: geomPoints,
                initialZoom: 7.8,
                minZoom: 4,
                maxZoom: 14,
                activeMap: true,
                showLegend: false,

                polygonsChanged: styledPolys,
                allowMultiSelect: false,
                showSearch: false,

                // MUNICÍPIOS selecionados
                selectedRegionNames: widget.selectedRegionNames,

                // Mantém cores (mesmo sem legenda, isso pinta o mapa no novo MapInteractive)
                polygonChangeColors: GeneralDashboardStyle.regionsColors,

                onControllerReady: (ctrl) {
                  _mapController = ctrl;

                  if (!_hasFitToPolygonsOnce && geomPoints.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitToPolygons(geomPoints);
                    });
                  }
                },
                onRegionTap: widget.onRegionTap,
              );
            },
          ),
        ),
      ),
    );
  }
}
