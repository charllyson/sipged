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
  /// MUNICÍPIOS selecionados (para destaque mais forte / filtro ativo)
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

  /// Normaliza nomes para comparação consistente
  String _norm(String s) => s.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  Set<String> _normSet(List<String> xs) => xs.map(_norm).toSet();

  /// Aplica estilos:
  /// - selecionado/filtro ativo => vermelho
  /// - com contrato => azul
  /// - sem contrato => cinza claro
  List<PolygonChangedData> _applyStrengthStyle({
    required List<PolygonChangedData> polys,
    required List<String> strongNames,
    required List<String> selectedNames,
  }) {
    if (polys.isEmpty) return polys;

    final strong = _normSet(strongNames);
    final selected = _normSet(selectedNames);

    // Sem dados
    const noDataFill = Color(0xFF9CA3AF);
    const noDataBorder = Color(0xFFB0B7C3);
    const noDataAlpha = 0.10;

    // Com dados
    const dataFill = Color(0xFF9CA3AF);
    const dataBorder = Color(0xFFB0B7C3);
    const dataAlpha = 0.42;

    // Filtro ativo / selecionado => vermelho
    const filteredFill = Color(0xFF5AA7FF);
    const filteredBorder = Color(0xFF2E78D6);
    const filteredAlpha = 0.58;

    return polys.map((p) {
      final name = _norm(p.title);
      final isSelected = selected.contains(name);
      final isStrong = strong.contains(name);

      if (isSelected) {
        return p.copyWith(
          normalFillColor: filteredFill.withValues(alpha: filteredAlpha),
          normalBorderColor: filteredBorder,
          normalBorderWidth: 2.2,
          selectedFillColor: filteredFill.withValues(alpha: 0.72),
          selectedBorderColor: filteredBorder,
          selectedBorderWidth: 2.6,
        );
      }

      return p.copyWith(
        normalFillColor: (isStrong ? dataFill : noDataFill)
            .withValues(alpha: isStrong ? dataAlpha : noDataAlpha),
        normalBorderColor:
        isStrong ? dataBorder : noDataBorder.withValues(alpha: 0.75),
        normalBorderWidth: isStrong ? 1.0 : 0.35,
        selectedFillColor: filteredFill.withValues(alpha: 0.72),
        selectedBorderColor: filteredBorder,
        selectedBorderWidth: isStrong ? 2.4 : 2.2,
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

              final styledPolys = _applyStrengthStyle(
                polys: state.cityPolygons,
                strongNames: widget.strongMunicipios,
                selectedNames: widget.selectedRegionNames,
              );

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

                // mantém a seleção lógica
                selectedRegionNames: widget.selectedRegionNames,

                // pode manter, mas agora a cor principal vem do PolygonChangedData
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