// lib/screens/panels/overview-dashboard/general_dashboard_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_state.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_style.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';

class GeneralDashboardMap extends StatelessWidget {
  /// MUNICÍPIOS selecionados (para destaque mais forte)
  final List<String> selectedRegionNames;

  /// Todos os municípios que possuem contratos (para opacidade "forte")
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
      // ao mudar a base de municípios, permitimos novo fit-to-bounds
      _hasFitToPolygonsOnce = false;
    }
  }

  /// Junta todos os pontos dos polígonos para centralizar o mapa.
  List<LatLng> _geometryPointsFromPolygons(List<PolygonChanged> polys) {
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
        padding: const EdgeInsets.all(16), // margem interna no card
      );

      _mapController!.fitCamera(cameraFit);
      _hasFitToPolygonsOnce = true;
    } catch (_) {
      // se der algum erro estranho, só marca como feito para não ficar tentando
      _hasFitToPolygonsOnce = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // necessário por causa do AutomaticKeepAlive
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

              // pontos para o MapInteractive centralizar / encaixar
              final geomPoints =
              _geometryPointsFromPolygons(state.cityPolygons);

              // Assim que tivermos controller + polígonos, fazemos o fit.
              if (!_hasFitToPolygonsOnce &&
                  _mapController != null &&
                  geomPoints.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitToPolygons(geomPoints);
                });
              }

              return MapInteractivePage<void>(
                // Ainda passamos os pontos como hint de centralização inicial,
                // mas quem manda mesmo é o fitToPolygons acima.
                initialGeometryPoints: geomPoints,

                initialZoom: 7.8,
                minZoom: 4,
                maxZoom: 14,
                activeMap: true,
                showLegend: false,

                polygonsChanged: state.cityPolygons,
                allowMultiSelect: false,
                showSearch: false,

                // MUNICÍPIOS selecionados (mais forte)
                selectedRegionNames: widget.selectedRegionNames,

                // MUNICÍPIOS com contratos (opacidade 0.6)
                strongPolygonNames: widget.strongMunicipios,

                polygonChangeColors: GeneralDashboardStyle.regionsColors,

                onControllerReady: (ctrl) {
                  _mapController = ctrl;

                  // se os polígonos já estiverem carregados quando o controller
                  // ficar pronto, encaixamos imediatamente.
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
