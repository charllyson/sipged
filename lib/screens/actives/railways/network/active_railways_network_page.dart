import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';

import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/admPanel/converters/geoJson/geo_json_mult_line_send_firebase.dart';
import 'package:siged/admPanel/converters/geoJson/geo_json_mult_line_check_jumps_in_collection.dart';

import '../../../../admPanel/converters/geoJson/geo_json_mult_line_actions_floating_buttons.dart';
import 'active_railways_map.dart';
import 'active_railways_panel.dart';

class ActiveRailwaysNetworkPage extends StatefulWidget {
  const ActiveRailwaysNetworkPage({super.key});

  @override
  State<ActiveRailwaysNetworkPage> createState() =>
      _ActiveRailwaysNetworkPageState();
}

class _ActiveRailwaysNetworkPageState extends State<ActiveRailwaysNetworkPage> {
  late final ActiveRailwaysBloc _bloc;
  bool _showRightPanel = false;

  @override
  void initState() {
    super.initState();
    // >>> Mesma lógica do ActiveRoadsNetworkPage (sem passar repo no ctor)
    _bloc = ActiveRailwaysBloc()..add(const ActiveRailwaysWarmupRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearFilters() {
    _bloc.add(const ActiveRailwaysRegionFilterChanged(null));
    _bloc.add(const ActiveRailwaysStatusFilterChanged(null));
  }

  void _toggleRightPanel() {
    setState(() => _showRightPanel = !_showRightPanel);
  }

  // =========================
  // Import / Delete helpers
  // =========================


  /// Deleta todos os documentos atualmente carregados no estado.
  void _onDeleteCollection() async {
    final ids = _bloc.state.all.map((e) => e.id).whereType<String>().toList();
    for (final id in ids) {
      _bloc.add(ActiveRailwaysDeleteRequested(id));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitada exclusão de todas as ferrovias carregadas.')),
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
        bottomNavigationBar: const FootBar(),
        body: Stack(
          children: [
            BlocBuilder<ActiveRailwaysBloc, ActiveRailwaysState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWide = constraints.maxWidth >= 980;

                    if (isWide) {
                      // Desktop / telas largas: mapa + painel lado a lado
                      return Row(
                        children: [
                          Expanded(child: ActiveRailwaysMap(state: state)),
                          if (_showRightPanel) ...[
                            const VerticalDivider(width: 1),
                            const SizedBox(
                              width: 600,
                              child: ActiveRailwaysPanel(),
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Mobile / tablets: mapa sobre o painel
                      return Column(
                        children: [
                          Expanded(child: ActiveRailwaysMap(state: state)),
                          if (_showRightPanel) ...[
                            const Divider(height: 1),
                            const SizedBox(
                              height: 420,
                              child: ActiveRailwaysPanel(),
                            ),
                          ],
                        ],
                      );
                    }
                  },
                );
              },
            ),

            // Botões de Importar / Deletar GeoJSON (flutuantes)
            GeoJsonActionsButtons(
              onImportGeoJson: (ctx) => GeoJsonSendFirebase(ctx),
              onDeleteCollection: _onDeleteCollection,
              onCheckDistances: () async {
                final ids = await geoJsonCheckJumpsInCollection(
                  collectionPath: 'actives_railways',
                  distanciaMaxEmKm: 2.0,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verificação concluída. ${ids.length} docs com saltos.')),
                  );
                }
              },
              collectionPath: 'actives_railways', // <<< novo param
            ),

          ],
        ),
      ),
    );
  }
}
