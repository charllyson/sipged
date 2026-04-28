// lib/screens/map/setup_region_map.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_data.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';

import 'package:sipged/_utils/geometry/sipged_geo_math.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_data.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

/// Abre um dialog com mapa IBGE para selecionar múltiplos municípios.
///
/// [initialSelected] = municípios já vinculados a ESTA região.
/// [lockedMunicipios] = municípios já usados em OUTRAS regiões, não podem ser selecionados aqui.
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

  /// Balão exibido ao tocar em município bloqueado.
  OverlayEntry? _lockedBalloonEntry;

  /// Conjunto de municípios selecionados por nome nesta região.
  late Set<String> _selectedCities;

  /// Municípios bloqueados, já vinculados a outras regiões.
  late Set<String> _lockedCities;

  /// Controller para UF usado pelo DropDownChange.
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

  bool _nameInSet(Set<String> set, String name) {
    final lower = name.trim().toLowerCase();

    return set.any(
          (e) => e.trim().toLowerCase() == lower,
    );
  }

  String? _findInSet(Set<String> set, String name) {
    final lower = name.trim().toLowerCase();

    try {
      return set.firstWhere(
            (e) => e.trim().toLowerCase() == lower,
      );
    } catch (_) {
      return null;
    }
  }

  /// Garante que a seleção atual contenha apenas municípios existentes
  /// nos polígonos carregados do estado atual.
  void _syncSelectionWithPolygons(IBGELocationState state) {
    if (state.cityPolygons.isEmpty) return;

    final availableNames = state.cityPolygons
        .map((p) => p.title.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final nextSelectedCities = _selectedCities.where(
          (name) {
        return availableNames.any(
              (n) => n.toLowerCase() == name.trim().toLowerCase(),
        );
      },
    ).toSet();

    if (nextSelectedCities.length == _selectedCities.length) {
      return;
    }

    setState(() {
      _selectedCities = nextSelectedCities;
    });
  }

  /// Centro geométrico simples de um polígono usando média dos pontos.
  LatLng? _computePolygonCenter(PolygonData poly) {
    final pts = poly.polygon.points;

    if (pts.isEmpty) return null;

    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  LatLng? _computeCenter(List<PolygonData> polys) {
    final pts = <LatLng>[];

    for (final p in polys) {
      pts.addAll(p.polygon.points);
    }

    if (pts.isEmpty) return null;

    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  /// Mostra o BalloonChange ancorado no centro do polígono bloqueado.
  void _showLockedBalloonAtPolygon(
      String regionName,
      IBGELocationState state,
      ) {
    final overlayState = Overlay.of(context);
    final map = _mapController;

    if (map == null) return;
    if (state.cityPolygons.isEmpty) return;

    final poly = state.cityPolygons.firstWhere(
          (p) {
        return p.title.trim().toLowerCase() ==
            regionName.trim().toLowerCase();
      },
      orElse: () => state.cityPolygons.first,
    );

    final center = _computePolygonCenter(poly);
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

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MapInteractivePage<void>(
                    initialZoom: 7.8,
                    minZoom: 4,
                    maxZoom: 14,
                    activeMap: true,
                    showLegend: false,
                    polygonsChanged: state.cityPolygons
                        .map((p) => _colorizePolygon(p))
                        .toList(),
                    selectedRegionNames: _selectedCities.toList(),
                    allowMultiSelect: true,
                    showSearch: true,
                    onControllerReady: (ctrl) {
                      _mapController = ctrl;
                    },
                    onRegionTap: (region) {
                      _hideLockedBalloon();

                      if (region == null) {
                        setState(() {});
                        return;
                      }

                      final bool isLocked =
                          _nameInSet(_lockedCities, region) &&
                              !_nameInSet(_selectedCities, region);

                      if (isLocked) {
                        _showLockedBalloonAtPolygon(region, state);
                        return;
                      }

                      final String? selectedMatch = _findInSet(
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

  /// Interpola cor dos polígonos marcando:
  /// - selecionados nesta região;
  /// - já usados em outras regiões;
  /// - disponíveis.
  PolygonData _colorizePolygon(PolygonData p) {
    final String name = p.title;

    final bool isSelected = _nameInSet(_selectedCities, name);
    final bool isLocked = _nameInSet(_lockedCities, name) && !isSelected;

    Color fill;
    Color border;
    double stroke;

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

    final String tooltipText = isLocked
        ? '$name (já vinculado a outra região)'
        : name;

    final List<Map<String, dynamic>> props =
        p.properties?.map((e) => Map<String, dynamic>.from(e)).toList() ??
            <Map<String, dynamic>>[];

    if (props.isEmpty) {
      props.add({'tooltip': tooltipText});
    } else {
      props[0]['tooltip'] = tooltipText;
    }

    return PolygonData(
      polygon: Polygon(
        points: p.polygon.points,
        borderColor: border,
        borderStrokeWidth: stroke,
        color: fill,
      ),
      title: p.title,
      properties: props,
    );
  }
}