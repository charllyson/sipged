import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'active_roads_map.dart';
import 'active_roads_panel.dart';

class ActiveRoadsNetworkPage extends StatefulWidget {
  const ActiveRoadsNetworkPage({super.key});

  @override
  State<ActiveRoadsNetworkPage> createState() =>
      _ActiveRoadsNetworkPageState();
}

class _ActiveRoadsNetworkPageState extends State<ActiveRoadsNetworkPage> {
  late final ActiveRoadsCubit _cubit;
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    _cubit = ActiveRoadsCubit()..warmup();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _clearFilters() {
    _cubit.clearAllFilters();
  }

  void _togglePanel() {
    setState(() => _showPanel = !_showPanel);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: UpBar(
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
                _showPanel
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
                color: Colors.white,
              ),
              onPressed: _togglePanel,
            ),
          ],
        ),
        body: BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
          builder: (context, state) {
            return SplitLayout(
              left: const ActiveRoadsMap(),
              right: const ActiveRoadsPanel(),
              showRightPanel: _showPanel,
              breakpoint: 980.0,
              rightPanelWidth: 580.0,
              bottomPanelHeight: 420.0,
              showDividers: true,
            );
          },
        ),
      ),
    );
  }
}