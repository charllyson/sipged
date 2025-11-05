// lib/screens/sectors/planning/rightWay/planning_right_way_workspace_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

// ✅ Split responsivo
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/screens/sectors/planning/rightWay/lane_regularization_details.dart';

// MAPA e PAINEL
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_map.dart';
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_panel.dart';

// Bloc do domínio
import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';

class PlanningRightWayWorkspacePage extends StatefulWidget {
  final ContractData contractData;
  const PlanningRightWayWorkspacePage({super.key, required this.contractData});

  @override
  State<PlanningRightWayWorkspacePage> createState() =>
      _PlanningRightWayWorkspacePageState();
}

class _PlanningRightWayWorkspacePageState
    extends State<PlanningRightWayWorkspacePage> {
  // visibilidade do painel
  bool _panelOpen = false;

  // sincroniza painel com o mapa (o mapa só lê este valor)
  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  // id do imóvel clicado no mapa (“Ver detalhes”)
  final ValueNotifier<String?> _selectedPropertyIdVN = ValueNotifier<String?>(null);

  // força reload do mapa (markers/polígonos)
  final ValueNotifier<int> _mapRefreshVN = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _panelVN.addListener(() {
      if (_panelOpen != _panelVN.value && mounted) {
        setState(() => _panelOpen = _panelVN.value);
      }
    });
  }

  void _togglePanel() {
    final next = !_panelOpen;
    setState(() => _panelOpen = next);
    _panelVN.value = next;
  }

  @override
  void dispose() {
    _panelVN.dispose();
    _selectedPropertyIdVN.dispose();
    _mapRefreshVN.dispose();
    super.dispose();
  }

  // Painel à direita: alterna entre “genérico” e “detalhes”
  Widget _buildRightPanel() {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedPropertyIdVN,
      builder: (ctx, propId, _) {
        if (propId == null) {
          return PlanningRightWayPropertyPanel(
            contractData: widget.contractData,
            onRequestMapRefresh: () => _mapRefreshVN.value++,
          );
        }
        return LaneRegularizationDetailsPanel(
          contract: widget.contractData,
          propertyId: propId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftMap = PlanningRightWayPropertyMap(
      contractData: widget.contractData,
      externalPanelController: _panelVN,                 // abre/fecha via mapa
      selectedPropertyIdNotifier: _selectedPropertyIdVN, // recebe o propertyId do mapa
      refreshListenable: _mapRefreshVN,                  // força refresh do mapa
    );

    final rightPanel = _buildRightPanel();

    return BlocProvider<PlanningHighwayDomainBloc>(
      create: (_) => PlanningHighwayDomainBloc(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: UpBar(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [SizedBox(width: 12), BackCircleButton(), SizedBox(width: 12)],
            ),
            actions: [
              IconButton(
                tooltip: _panelOpen ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(
                  _panelOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),
        bottomNavigationBar: const FootBar(),
        body: ResponsiveSplitView(
          // >= breakpoint: lado a lado (mapa à ESQUERDA); < breakpoint: empilhado (mapa EM CIMA)
          left: leftMap,
          right: rightPanel,
          showRightPanel: _panelOpen,

          // Calibrações próximas do seu layout original:
          breakpoint: 980.0,        // mesmo corte que você já usa em outras telas
          rightPanelWidth: 520.0,   // alvo no wide (painel direito)
          bottomPanelHeight: 380.0, // alvo no stacked (painel embaixo)

          showDividers: true,
          dividerThickness: 12.0,
          dividerBackgroundColor: Colors.white,
          dividerBorderColor: Colors.black12,
          gripColor: const Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}
