// lib/screens/modules/actives/roads/network/active_roads_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

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

  // =========================
  // Ações da UpBar
  // =========================

  void _clearFilters() {
    _cubit.setRegionFilter(null);
    _cubit.setSurfaceFilter(null);
    _cubit.setPieFilter(null);
  }

  void _togglePanel() {
    setState(() => _showPanel = !_showPanel);
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
                  _showPanel
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),

        // =========================
        // Layout principal com mapa + painel
        // =========================
        body: BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
          builder: (context, state) {
            return SplitLayout(
              left: const ActiveRoadsMap(),

              // Painel lateral (igual OAE)
              right: const ActiveRoadsPanel(),

              // Mostrar/Ocultar
              showRightPanel: _showPanel,

              // 🔥 Exatamente os mesmos valores do OAEs
              breakpoint: 980.0,
              rightPanelWidth: 580.0, // mesmo do OAE
              bottomPanelHeight: 420.0, // mesmo do OAE
              showDividers: true,
            );
          },
        ),
      ),
    );
  }
}
