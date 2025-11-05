// lib/_pages/actives/railway/active_railways_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';

import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_services/geoJson/send_firebase.dart';
import 'package:siged/_services/geoJson/check_jumps_between_points.dart';

// 🔀 Layout responsivo com divisor arrastável
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import '../../../../_widgets/services/floating_buttons.dart';
import 'active_railways_map.dart';
import 'active_railways_panel.dart';

// ✅ Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

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

  void _onDeleteCollection() async {
    final ids = _bloc.state.all.map((e) => e.id).whereType<String>().toList();
    for (final id in ids) {
      _bloc.add(ActiveRailwaysDeleteRequested(id));
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Exclusão solicitada'),
        subtitle: Text('${ids.length} ferrovia(s) marcada(s) para exclusão.'),
        type: AppNotificationType.warning,
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
                return ResponsiveSplitView(
                  // conteúdo principal (mapa)
                  left: ActiveRailwaysMap(state: state),

                  // painel lateral/inferior
                  right: const ActiveRailwaysPanel(),

                  // controle de exibição
                  showRightPanel: _showRightPanel,

                  // tamanhos e comportamento padrão
                  breakpoint: 980.0,
                  rightPanelWidth: 600.0,
                  bottomPanelHeight: 420.0,
                  showDividers: true,
                );
              },
            ),

            // ===== Botões de GeoJSON (flutuantes) =====
            GeoJsonActionsButtons(
              collectionPath: 'actives_railways',
              initiallyExpanded: true,
              position: const GeoJsonActionsPosition.bottomLeft(),
              onImportGeoJson: (ctx) async {
                await GeoJsonSendFirebase(ctx);
              },
              onDeleteCollection: _onDeleteCollection,
              onCheckDistances: () async {
                final ids = await checkJumpsBetweenPoints(
                  collectionPath: 'actives_railways',
                  distanciaMaxEmKm: 2.0,
                );

                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Verificação concluída'),
                    subtitle: Text(
                      '${ids.length} documento(s) com possíveis saltos > 2 km',
                    ),
                    type: ids.isEmpty
                        ? AppNotificationType.success
                        : AppNotificationType.warning,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
