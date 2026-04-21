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
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/map/tooltip/tooltip_overlay.dart';

/// Abre um dialog com mapa IBGE para selecionar múltiplos municípios.
/// [initialSelected] = municípios já vinculados a ESTA região.
/// [lockedMunicipios] = municípios já usados em OUTRAS regiões (não podem ser selecionados aqui).
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
  final String title;
  final List<String> initialSelected;
  final List<String> lockedMunicipios;

  const _RegionMunicipiosSelectorBody({
    required this.title,
    required this.initialSelected,
    required this.lockedMunicipios,
  });

  @override
  State<_RegionMunicipiosSelectorBody> createState() =>
      _RegionMunicipiosSelectorBodyState();
}

class _RegionMunicipiosSelectorBodyState
    extends State<_RegionMunicipiosSelectorBody> {
  MapController? _mapController;

  /// Conjunto de municípios selecionados (por nome) nesta região
  late Set<String> _selectedCities;

  /// Municípios bloqueados (já vinculados a outras regiões)
  late Set<String> _lockedCities;


  /// Controller para UF (usado pelo DropDownButtonChange)
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
    _ufCtrl.dispose();
    super.dispose();
  }

  // Helpers para comparar nomes ignorando maiúsc./minúsc. e espaços
  bool _nameInSet(Set<String> set, String name) {
    final lower = name.trim().toLowerCase();
    return set.any((e) => e.trim().toLowerCase() == lower);
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

  /// Garante que a seleção atual (_selectedCities) só contenha municípios
  /// que existem nos polígonos carregados do estado atual.
  void _syncSelectionWithPolygons(IBGELocationState state) {
    if (state.cityPolygons.isEmpty) return;

    final availableNames = state.cityPolygons
        .map((p) => (p.title).trim())
        .where((name) => name.isNotEmpty)
        .toList();

    setState(() {
      _selectedCities = _selectedCities
          .where(
            (name) => availableNames.any(
              (n) => n.toLowerCase() == name.trim().toLowerCase(),
        ),
      )
          .toSet();
    });
  }

  /// Centro geométrico simples de um polígono (média dos pontos)
  LatLng? _computePolygonCenter(PolygonChangedData poly) {
    final pts = poly.polygon.points;
    if (pts.isEmpty) return null;

    final lat =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  LatLng? _computeCenter(List<PolygonChangedData> polys) {
    final pts = <LatLng>[];
    for (final p in polys) {
      pts.addAll(p.polygon.points);
    }
    if (pts.isEmpty) return null;

    final lat =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lon =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    return LatLng(lat, lon);
  }

  /// Mostra tooltip flutuante ancorado no centro do polígono bloqueado
  void _showLockedTooltipAtPolygon(String regionName, IBGELocationState state) {
    final overlay = Overlay.of(context);
    final map = _mapController;
    if (map == null) return;

    if (state.cityPolygons.isEmpty) return;

    // Encontra o polígono pelo nome (title)
    final poly = state.cityPolygons.firstWhere(
          (p) => (p.title).trim().toLowerCase() ==
          regionName.trim().toLowerCase(),
      orElse: () => state.cityPolygons.first,
    );

    final center = _computePolygonCenter(poly);
    if (center == null) return;

    // Usa o mesmo helper que você já usa em PlanningRightWay: MapMath.latLngToScreen
    final cam = map.camera;
    final Offset localPos = SipGedGeoMath.latLngToScreen(cam, center);

    // Converte para coordenada GLOBAL
    final renderObj = context.findRenderObject();
    if (renderObj is! RenderBox) return;
    final Offset global = renderObj.localToGlobal(localPos);

    TooltipOverlay.hide();
    TooltipOverlay.show(
      overlayState: overlay,
      position: global,
      title: 'Município bloqueado',
      subtitle: '$regionName já está vinculado a outra região.',
      maxWidth: 280,
      forceDownArrow: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<IBGELocationCubit, IBGELocationState>(
      listener: (context, state) {
        // Centraliza o mapa quando carrega o estado
        if (_mapController != null &&
            state.selectedState != null &&
            state.cityPolygons.isNotEmpty) {
          final center = _computeCenter(state.cityPolygons);
          if (center != null) {
            _mapController!.move(center, 7.8);
          }
        }

        // Atualiza o texto do dropdown de UF quando o estado selecionado mudar
        if (state.selectedState != null) {
          final st = state.selectedState!;
          final label = '${st.sigla} - ${st.nome}';
          if (_ufCtrl.text != label) {
            _ufCtrl.text = label;
          }
        }

        // Ajusta a seleção para o UF atual (evita falhas ao trocar de estado)
        _syncSelectionWithPolygons(state);
      },
      builder: (context, state) {
        final ufItems = state.states
            .map((IBGELocationStateData st) => '${st.sigla} - ${st.nome}')
            .toList();

        return Column(
          children: [
            // ====== Mapa (ocupa largura toda do WindowDialog) ======
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

                    // 👇 grupo selecionado desta região
                    selectedRegionNames: _selectedCities.toList(),

                    allowMultiSelect: true,
                    showSearch: true,
                    onControllerReady: (ctrl) {
                      _mapController = ctrl;
                    },
                    onRegionTap: (region) {
                      if (region == null) {
                        setState(() {
                        });
                        return;
                      }

                      // 🔒 Bloqueado? (pertence a outra região e não a esta)
                      final bool isLocked =
                          _nameInSet(_lockedCities, region) &&
                              !_nameInSet(_selectedCities, region);

                      if (isLocked) {
                        // Mostra tooltip flutuante ancorado no centro do polígono
                        _showLockedTooltipAtPolygon(region, state);
                        return;
                      }

                      // Toggle normal (seleção/deseleção)
                      final String? selectedMatch =
                      _findInSet(_selectedCities, region);

                      if (selectedMatch != null) {
                        setState(() {
                          _selectedCities.remove(selectedMatch);
                        });
                        return;
                      }

                      state.cityPolygons.firstWhere(
                            (p) => p.title == region,
                        orElse: () => state.cityPolygons.first,
                      );

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

                          setState(() {
                          });

                          // Ao trocar estado, esconde tooltip, se existir
                          TooltipOverlay.hide();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ====== Lista de selecionados + ações ======
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        : _selectedCities
                        .map(
                          (name) => Chip(
                        backgroundColor: const Color(0xFFE1F5FE),
                        label: Text(name),
                        onDeleted: () {
                          setState(() {
                            _selectedCities.remove(name);
                          });
                        },
                      ),
                    )
                        .toList(),
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
                          setState(() {
                            _selectedCities.clear();
                          });
                          TooltipOverlay.hide();
                        },
                        child: const Text('Limpar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          TooltipOverlay.hide();
                          Navigator.of(context)
                              .pop(_selectedCities.toList());
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
  /// - selecionados nesta região (destaque),
  /// - já usados em outras regiões (cinza),
  /// - disponíveis (cinza clarinho).
  PolygonChangedData _colorizePolygon(PolygonChangedData p) {
    final String name = p.title;

    final bool isSelected = _nameInSet(_selectedCities, name);
    final bool isLocked =
        _nameInSet(_lockedCities, name) && !isSelected; // outra região

    Color fill;
    Color border;
    double stroke;

    if (isSelected) {
      // ✅ Selecionado nesta região -> destaque (roxo)
      fill = const Color(0xFF5E35B1).withValues(alpha: 0.40);
      border = const Color(0xFF311B92);
      stroke = 2.2;
    } else if (isLocked) {
      // 🔒 Bloqueado (pertence a OUTRA região) -> CINZA bem visível
      fill = Colors.grey.withValues(alpha: 0.55);
      border = Colors.grey.shade900;
      stroke = 2.0;
    } else {
      // 🌐 Disponível -> cinza clarinho
      fill = Colors.grey.withValues(alpha: 0.18);
      border = Colors.grey.shade400;
      stroke = 1.0;
    }

    // Tooltip configurado via editor (se o MapInteractivePage usar)
    final String tooltipText =
    isLocked ? '$name (já vinculado a outra região)' : name;

    final List<Map<String, dynamic>> props =
        (p.properties?.map((e) => Map<String, dynamic>.from(e)).toList()) ??
            <Map<String, dynamic>>[];

    if (props.isEmpty) {
      props.add({'tooltip': tooltipText});
    } else {
      props[0]['tooltip'] = tooltipText;
    }

    return PolygonChangedData(
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
