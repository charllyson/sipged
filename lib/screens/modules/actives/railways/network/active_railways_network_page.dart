import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

// 🔀 Layout responsivo com divisor arrastável
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

// ✅ Notificações

import 'active_railways_map.dart';
import 'active_railways_panel.dart';

class ActiveRailwaysNetworkPage extends StatefulWidget {
  const ActiveRailwaysNetworkPage({super.key});

  @override
  State<ActiveRailwaysNetworkPage> createState() =>
      _ActiveRailwaysNetworkPageState();
}

class _ActiveRailwaysNetworkPageState extends State<ActiveRailwaysNetworkPage> {
  late final ActiveRailwaysCubit _cubit;
  bool _showRightPanel = true;

  @override
  void initState() {
    super.initState();
    _cubit = ActiveRailwaysCubit()..warmup();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _clearFilters() {
    _cubit.setRegionFilter(null);
    _cubit.setStatusFilter(null);
    _cubit.setPieFilter(null);
  }

  void _toggleRightPanel() {
    setState(() => _showRightPanel = !_showRightPanel);
  }

  // =========================
  // Import / Delete helpers
  // =========================


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
                tooltip: _showRightPanel ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(
                  _showRightPanel
                      ? Icons.view_sidebar
                      : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _toggleRightPanel,
              ),
            ],
          ),
        ),

        body: Stack(
          children: [
            BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
              builder: (context, state) {
                return SplitLayout(
                  left: ActiveRailwaysMap(state: state),

                  right: const ActiveRailwaysPanel(),

                  showRightPanel: _showRightPanel,

                  // 🔥 mesma proporção de todos os módulos padronizados
                  breakpoint: 980.0,
                  rightPanelWidth: 580.0,     // estava 600 → agora padrão OAEs/Roads
                  bottomPanelHeight: 420.0,   // igual OAEs/Roads
                  showDividers: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
