import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sisged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:sisged/_widgets/upBar/up_bar.dart';
import 'package:sisged/_widgets/footBar/foot_bar.dart';

import 'package:sisged/_blocs/actives/roads/active_roads_event.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_state.dart';

import 'roads_left_map.dart';
import 'roads_right_stats_panel.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  const ActiveRoadsNetworkPage({super.key});

  @override
  State<ActiveRoadsNetworkPage> createState() => _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  late final ActiveRoadsBloc _bloc;
  bool _showRightPanel = false;

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

  void _refresh() => _bloc.add(const ActiveRoadsRefreshRequested());

  void _clearFilters() {
    _bloc.add(const ActiveRoadsRegionFilterChanged(null));
    _bloc.add(const ActiveRoadsSurfaceFilterChanged(null));
  }

  void _toggleRightPanel() {
    setState(() => _showRightPanel = !_showRightPanel);
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
                tooltip: 'Recarregar',
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refresh,
              ),
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                onPressed: _clearFilters,
              ),
              IconButton(
                tooltip: _showRightPanel ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(
                  _showRightPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _toggleRightPanel,
              ),
            ],
          ),
        ),

        bottomNavigationBar: const FootBar(),

        body: Stack(
          children: [
            BlocBuilder<ActiveRoadsBloc, ActiveRoadsState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth >= 980;

                    if (isWide) {
                      // Layout lado a lado
                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: RoadsLeftMap(state: state),
                          ),
                          if (_showRightPanel) ...[
                            const VerticalDivider(width: 1),
                            const SizedBox(
                              width: 600,
                              child: RoadsRightStatsPanel(),
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Layout empilhado (mobile/tablet)
                      return Column(
                        children: [
                          Expanded(child: RoadsLeftMap(state: state)),
                          if (_showRightPanel) ...[
                            const Divider(height: 1),
                            const SizedBox(
                              height: 420,
                              child: RoadsRightStatsPanel(),
                            ),
                          ],
                        ],
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
