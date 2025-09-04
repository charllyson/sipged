// lib/screens/actives/oaes/network/active_airports_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart'; // 👈 ajuste o path se necessário

import 'active_airports_map.dart';
import 'active_airports_panel.dart';

class ActiveAirportsNetworkPage extends StatefulWidget {
  const ActiveAirportsNetworkPage({super.key});

  @override
  State<ActiveAirportsNetworkPage> createState() => _ActiveAirportsNetworkPageState();
}

class _ActiveAirportsNetworkPageState extends State<ActiveAirportsNetworkPage> {
  late final ActiveOaesBloc _bloc;
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
                  _showRightPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _toggleRightPanel,
              ),
            ],
          ),
        ),

        // 👉 FootBar fixado no fim
        bottomNavigationBar: const FootBar(),

        body: Stack(
          children: [
            BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
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
                            child: ActiveAirportsMap(state: state),
                          ),
                          if (_showRightPanel) ...[
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: 600, // largura do painel direito
                              child: ActiveAirportsPanel(
                                onClose: _toggleRightPanel,
                              ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Layout empilhado (mobile/tablet)
                      return Column(
                        children: [
                          Expanded(
                            child: ActiveAirportsMap(state: state),
                          ),
                          if (_showRightPanel) ...[
                            const Divider(height: 1),
                            SizedBox(
                              height: 420,
                              child: ActiveAirportsPanel(
                                onClose: _toggleRightPanel,
                              ),
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
