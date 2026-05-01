// lib/screens/map/setup_region_map.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_data.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';

import 'package:sipged/_utils/geometry/sipged_geo_math.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

Future<List<String>?> setupRegionMap(
    BuildContext context, {
      String title = 'Selecionar municípios da região',
      List<String> initialSelected = const [],
      List<String> lockedMunicipios = const [],
      int initialUfCode = 27,
    }) async {
  return showWindowDialog<List<String>>(
    context: context,
    title: title,
    width: 960,
    barrierDismissible: true,
    contentPadding: EdgeInsets.zero,
    child: SizedBox(
      width: double.infinity,
      height: 620,
      child: BlocProvider(
        create: (_) => IBGELocationCubit(
          repository: IBGELocationRepository(),
        )..loadInitial(initialUfCode: initialUfCode),
        child: _RegionMunicipiosSelectorBody(
          title: title,
          initialSelected: initialSelected,
          lockedMunicipios: lockedMunicipios,
        ),
      ),
    ),
  );
}

class _RegionMunicipiosSelectorBody extends StatefulWidget {
  const _RegionMunicipiosSelectorBody({
    required this.title,
    required this.initialSelected,
    required this.lockedMunicipios,
  });

  final String title;
  final List<String> initialSelected;
  final List<String> lockedMunicipios;

  @override
  State<_RegionMunicipiosSelectorBody> createState() {
    return _RegionMunicipiosSelectorBodyState();
  }
}

class _RegionMunicipiosSelectorBodyState
    extends State<_RegionMunicipiosSelectorBody> {
  MapController? _mapController;

  OverlayEntry? _lockedBalloonEntry;

  late Set<String> _selectedCities;
  late Set<String> _lockedCities;

  late final TextEditingController _ufCtrl;

  @override
  void initState() {
    super.initState();

    _selectedCities = widget.initialSelected
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    _lockedCities = widget.lockedMunicipios
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    _ufCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _hideLockedBalloon();
    _ufCtrl.dispose();
    super.dispose();
  }

  void _hideLockedBalloon() {
    _lockedBalloonEntry?.remove();
    _lockedBalloonEntry = null;
  }

  String _norm(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _nameInSet(Set<String> set, String name) {
    final target = _norm(name);

    return set.any((e) => _norm(e) == target);
  }

  String? _findInSet(Set<String> set, String name) {
    final target = _norm(name);

    try {
      return set.firstWhere((e) => _norm(e) == target);
    } catch (_) {
      return null;
    }
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
      List<Polygon<Map<String, dynamic>>> polygons,
      ) {
    if (polygons.isEmpty) return const <LatLng>[];

    final points = <LatLng>[];

    for (final polygon in polygons) {
      points.addAll(polygon.points);

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];

      for (final hole in holes) {
        points.addAll(hole);
      }
    }

    return points;
  }

  void _syncSelectionWithPolygons(IBGELocationState state) {
    if (state.cityPolygons.isEmpty) return;

    final availableNames = state.cityPolygons
        .map(_polygonTitle)
        .where((name) => name.isNotEmpty)
        .toList();

    final nextSelectedCities = _selectedCities.where((name) {
      return availableNames.any((n) => _norm(n) == _norm(name));
    }).toSet();

    if (nextSelectedCities.length == _selectedCities.length) return;

    setState(() {
      _selectedCities = nextSelectedCities;
    });
  }

  LatLng? _computePolygonCenter(Polygon<Map<String, dynamic>> polygon) {
    final pts = polygon.points;

    if (pts.isEmpty) return null;

    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  LatLng? _computeCenter(List<Polygon<Map<String, dynamic>>> polys) {
    final pts = <LatLng>[];

    for (final polygon in polys) {
      pts.addAll(polygon.points);

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];

      for (final hole in holes) {
        pts.addAll(hole);
      }
    }

    if (pts.isEmpty) return null;

    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  void _showLockedBalloonAtPolygon(
      String regionName,
      IBGELocationState state,
      ) {
    final overlayState = Overlay.of(context);
    final map = _mapController;

    if (map == null) return;
    if (state.cityPolygons.isEmpty) return;

    final polygon = state.cityPolygons.firstWhere(
          (p) => _norm(_polygonTitle(p)) == _norm(regionName),
      orElse: () => state.cityPolygons.first,
    );

    final center = _computePolygonCenter(polygon);
    if (center == null) return;

    final cam = map.camera;

    final Offset localMapPosition = SipGedGeoMath.latLngToScreen(
      cam,
      center,
    );

    final renderObj = context.findRenderObject();
    if (renderObj is! RenderBox) return;

    final Offset globalPosition = renderObj.localToGlobal(localMapPosition);

    final overlayObject = overlayState.context.findRenderObject();
    if (overlayObject is! RenderBox) return;

    _hideLockedBalloon();

    _lockedBalloonEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideLockedBalloon,
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              overlayBox: overlayObject,
              globalAnchor: globalPosition,
              width: 280,
              maxHeight: 180,
              topGap: 8,
              screenMargin: 12,
              tipSide: BalloonTipSide.bottom,
              title: 'Município bloqueado',
              headerIcon: Icons.lock_outline_rounded,
              emptyMessage: 'Nenhuma informação encontrada.',
              items: [
                BalloonTileData(
                  id: 'locked_$regionName',
                  title: regionName,
                  subtitle: 'Este município já está vinculado a outra região.',
                  details: 'Remova o vínculo anterior para selecionar aqui.',
                  icon: Icons.lock_outline_rounded,
                  accentColor: Colors.orange.shade800,
                ),
              ],
            ),
          ],
        );
      },
    );

    overlayState.insert(_lockedBalloonEntry!);
  }

  Polygon<Map<String, dynamic>> _colorizePolygon(
      Polygon<Map<String, dynamic>> polygon,
      ) {
    final name = _polygonTitle(polygon);

    final isSelected = _nameInSet(_selectedCities, name);
    final isLocked = _nameInSet(_lockedCities, name) && !isSelected;

    late final Color fill;
    late final Color border;
    late final double stroke;

    if (isSelected) {
      fill = const Color(0xFF5E35B1).withValues(alpha: 0.40);
      border = const Color(0xFF311B92);
      stroke = 2.2;
    } else if (isLocked) {
      fill = Colors.grey.withValues(alpha: 0.55);
      border = Colors.grey.shade900;
      stroke = 2.0;
    } else {
      fill = Colors.grey.withValues(alpha: 0.18);
      border = Colors.grey.shade400;
      stroke = 1.0;
    }

    final tooltipText = isLocked ? '$name (já vinculado a outra região)' : name;

    final hit = Map<String, dynamic>.from(polygon.hitValue ?? {});
    final props = Map<String, dynamic>.from(
      (hit['properties'] is Map<String, dynamic>)
          ? hit['properties'] as Map<String, dynamic>
          : <String, dynamic>{},
    );

    props['tooltip'] = tooltipText;

    hit['title'] = hit['title'] ?? name;
    hit['nome'] = hit['nome'] ?? name;
    hit['processo'] = hit['processo'] ?? name;
    hit['properties'] = props;

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
  }

  void _handlePolygonTap(
      Polygon<Map<String, dynamic>>? polygon,
      IBGELocationState state,
      ) {
    _hideLockedBalloon();

    if (polygon == null) {
      setState(() {});
      return;
    }

    final region = _polygonTitle(polygon);

    if (region.trim().isEmpty) {
      setState(() {});
      return;
    }

    final isLocked =
        _nameInSet(_lockedCities, region) && !_nameInSet(_selectedCities, region);

    if (isLocked) {
      _showLockedBalloonAtPolygon(region, state);
      return;
    }

    final selectedMatch = _findInSet(
      _selectedCities,
      region,
    );

    if (selectedMatch != null) {
      setState(() {
        _selectedCities.remove(selectedMatch);
      });
      return;
    }

    setState(() {
      _selectedCities.add(region);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<IBGELocationCubit, IBGELocationState>(
      listener: (context, state) {
        if (_mapController != null &&
            state.selectedState != null &&
            state.cityPolygons.isNotEmpty) {
          final center = _computeCenter(state.cityPolygons);

          if (center != null) {
            _mapController!.move(center, 7.8);
          }
        }

        if (state.selectedState != null) {
          final st = state.selectedState!;
          final label = '${st.sigla} - ${st.nome}';

          if (_ufCtrl.text != label) {
            _ufCtrl.text = label;
          }
        }

        _syncSelectionWithPolygons(state);
      },
      builder: (context, state) {
        final ufItems = state.states
            .map(
              (IBGELocationStateData st) => '${st.sigla} - ${st.nome}',
        )
            .toList();

        final styledPolygons = state.cityPolygons
            .map(_colorizePolygon)
            .toList(growable: false);

        final geometryPoints = _geometryPointsFromPolygons(styledPolygons);

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MapChange(
                    key: ValueKey(
                      'setup-region-map-${state.selectedState?.id ?? 'none'}',
                    ),

                    features: const <FeatureData>[],
                    layersById: const <String, LayerData>{},
                    orderedActiveLayerIds: const <String>[],

                    selectedFeatureKey: null,
                    loading: state.isLoading,

                    visualDataSignature: Object.hash(
                      'setup-region-map',
                      state.selectedState?.id,
                      styledPolygons.length,
                      _selectedCities.length,
                      _lockedCities.length,
                    ),

                    initialCenter: const LatLng(-9.6658, -35.7353),
                    initialZoom: 7.8,
                    minZoom: 4,
                    maxZoom: 14,

                    showSearch: true,
                    showControls: true,

                    initialGeometryPoints: geometryPoints,
                    fitInitialGeometryOnce: geometryPoints.isNotEmpty,

                    externalPolygons: styledPolygons,

                    onControllerReady: (ctrl) {
                      _mapController = ctrl;
                    },

                    onCameraChanged: (_, _) {},

                    onFeatureTap: (_) {},

                    onExternalPolygonTap: (polygon) {
                      _handlePolygonTap(polygon, state);
                    },
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: SizedBox(
                      width: 200,
                      child: DropDownChange(
                        controller: _ufCtrl,
                        labelText: 'Estado',
                        items: ufItems,
                        enabled: ufItems.isNotEmpty && !state.isLoading,
                        menuMaxHeight: 260,
                        onChanged: (value) {
                          if (value == null || value.isEmpty) return;

                          final st = state.states.firstWhere(
                                (s) => '${s.sigla} - ${s.nome}' == value,
                            orElse: () => state.states.first,
                          );

                          context
                              .read<IBGELocationCubit>()
                              .changeSelectedState(st.id);

                          _hideLockedBalloon();

                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, -2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedCities.isEmpty
                        ? [
                      Text(
                        'Nenhum município selecionado. Toque no mapa para selecionar ou desmarcar.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ]
                        : _selectedCities.map(
                          (name) {
                        return Chip(
                          backgroundColor: const Color(0xFFE1F5FE),
                          label: Text(name),
                          onDeleted: () {
                            _hideLockedBalloon();

                            setState(() {
                              _selectedCities.remove(name);
                            });
                          },
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Total selecionado: ${_selectedCities.length}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _hideLockedBalloon();

                          setState(() {
                            _selectedCities.clear();
                          });
                        },
                        child: const Text('Limpar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          _hideLockedBalloon();

                          Navigator.of(context).pop(
                            _selectedCities.toList(),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Salvar seleção'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}