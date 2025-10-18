// lib/screens/actives/roads/network/active_roads_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_blocs/actives/roads/active_roads_state.dart';

import 'active_roads_map.dart';
import 'active_roads_panel.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  const ActiveRoadsNetworkPage({super.key});

  @override
  State<ActiveRoadsNetworkPage> createState() => _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  late final ActiveRoadsBloc _bloc;

  // 👉 painel inicia visível
  bool _showPanel = true;

  // 👉 fração de altura do MAPA no layout empilhado (tablet/mobile)
  double _stackedMapFraction = 0.56; // 56% mapa / 44% painel

  @override
  void initState() {
    super.initState();
    _bloc = ActiveRoadsBloc()..add(const ActiveRoadsWarmupRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearFilters() {
    _bloc.add(const ActiveRoadsRegionFilterChanged(null));
    _bloc.add(const ActiveRoadsSurfaceFilterChanged(null));
    _bloc.add(const ActiveRoadsPieFilterChanged(null));
  }

  void _togglePanel() => setState(() => _showPanel = !_showPanel);

  // ----- divisor arrastável (só para layout empilhado) -----
  Widget _buildDraggableHorizontalDivider(double totalH) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          final delta = details.delta.dy;
          setState(() {
            final currentMapH = _stackedMapFraction * totalH;
            final newMapH = (currentMapH + delta).clamp(220.0, totalH * 0.9);
            _stackedMapFraction = (newMapH / totalH).clamp(0.2, 0.9);
          });
        },
        child: Container(
          height: 10,
          color: Colors.white,
          child: Center(
            child: Container(width: double.infinity, height: 1, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: UpBar(
            showPhotoMenu: true,
            actions: [
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                onPressed: _clearFilters,
              ),
              IconButton(
                tooltip: _showPanel ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(
                  _showPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),
        body: BlocBuilder<ActiveRoadsBloc, ActiveRoadsState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;

                if (isWide) {
                  // =======================
                  // DESKTOP (lado a lado)
                  // =======================
                  return Row(
                    children: [
                      Expanded(
                        child: ActiveRoadsMap(state: state),
                      ),
                      if (_showPanel) ...[
                        const VerticalDivider(width: 1),
                        const SizedBox(
                          width: 600,
                          child: ActiveRoadsPanel(),
                        ),
                      ],
                    ],
                  );
                }

                // ==================================
                // TABLET/MOBILE (empilhado - mapa em cima)
                // ==================================
                final double totalH = constraints.maxHeight;
                final double minMapH = 220.0;
                final double maxMapH = (totalH * 0.9).clamp(minMapH, totalH);
                final double mapH = (_stackedMapFraction * totalH).clamp(minMapH, maxMapH);

                return Column(
                  children: [
                    // MAPA (em cima)
                    SizedBox(
                      width: double.infinity,
                      height: _showPanel ? mapH : null,
                      child: _showPanel
                          ? ActiveRoadsMap(state: state)
                          : Expanded(child: ActiveRoadsMap(state: state)),
                    ),

                    if (_showPanel) _buildDraggableHorizontalDivider(totalH),

                    // PAINEL (embaixo)
                    if (_showPanel)
                      const Expanded(
                        child: ActiveRoadsPanel(),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
