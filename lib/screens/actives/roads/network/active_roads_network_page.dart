// lib/screens/actives/roads/network/active_roads_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_blocs/actives/roads/active_roads_state.dart';

import 'package:siged/_widgets/upBar/up_bar.dart';

// 🔀 Layout responsivo com divisor arrastável (↔ / ↕)
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import 'active_roads_map.dart';
import 'active_roads_panel.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  const ActiveRoadsNetworkPage({super.key});

  @override
  State<ActiveRoadsNetworkPage> createState() => _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  late final ActiveRoadsBloc _bloc;

  bool _showPanel = true;

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
            return ResponsiveSplitView(
              left: ActiveRoadsMap(state: state),
              right: const ActiveRoadsPanel(),
              showRightPanel: _showPanel,

              // comportamento padrão
              breakpoint: 980.0,
              rightPanelWidth: 600.0,
              bottomPanelHeight: 420.0,
              showDividers: true,
            );
          },
        ),
      ),
    );
  }
}
