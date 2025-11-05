// lib/screens/actives/oaes/network/active_airports_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';

import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

// 🔀 Split responsivo com divisor arrastável (↔/↕)
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import 'active_airports_map.dart';
import 'active_airports_panel.dart';

class ActiveAirportsNetworkPage extends StatefulWidget {
  const ActiveAirportsNetworkPage({super.key});

  @override
  State<ActiveAirportsNetworkPage> createState() =>
      _ActiveAirportsNetworkPageState();
}

class _ActiveAirportsNetworkPageState extends State<ActiveAirportsNetworkPage> {
  late final ActiveOaesBloc _bloc;

  /// Controle de exibição do painel (lado a lado em telas largas; embaixo no mobile)
  bool _showRightPanel = false;

  @override
  void initState() {
    super.initState();
    _bloc = ActiveOaesBloc()..add(const ActiveOaesWarmupRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearFilters() {
    _bloc.add(const ActiveOaesPieFilterChanged(null));
    _bloc.add(const ActiveOaesRegionFilterChanged(null));
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

        // ▶️ FootBar fixo
        bottomNavigationBar: const FootBar(),

        body: BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
          builder: (context, state) {
            return ResponsiveSplitView(
              // conteúdo principal (mapa)
              left: ActiveAirportsMap(state: state),

              // painel (detalhes/controles)
              right: ActiveAirportsPanel(
                onClose: _toggleRightPanel,
              ),

              // visibilidade do painel
              showRightPanel: _showRightPanel,

              // mesmas métricas padrão do SIGED (podem ser ajustadas)
              breakpoint: 980.0,          // >= 980 lado a lado; senão empilhado
              rightPanelWidth: 600.0,     // largura inicial do painel (↔)
              bottomPanelHeight: 420.0,   // altura inicial no mobile (↕)

              // opcional: limites e espessura do divisor
              // minRightPanelWidth: 320,
              // minBottomPanelHeight: 260,
              // dividerThickness: 12.0,
              showDividers: true,
            );
          },
        ),
      ),
    );
  }
}
