import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// Estado unificado (usado para refresh após import)
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/screens/sectors/planning/rightWay/property/planning_right_way_property_details.dart';

// MAPA e PAINEL
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_map.dart';
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_panel.dart';

// 🔹 Botões/serviço de import
import 'package:siged/_widgets/services/floating_buttons.dart';
import 'package:siged/_services/geoJson/send_firebase.dart';

// Bloc do domínio (opcional se já estiver em outro lugar)
import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';

class PlanningRightWayPropertyWorkspace extends StatefulWidget {
  final ContractData contractData;
  const PlanningRightWayPropertyWorkspace({super.key, required this.contractData});

  @override
  State<PlanningRightWayPropertyWorkspace> createState() =>
      _PlanningRightWayPropertyWorkspaceState();
}

class _PlanningRightWayPropertyWorkspaceState
    extends State<PlanningRightWayPropertyWorkspace> {
  bool _panelOpen = false;
  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

  // Recebe o id do imóvel clicado no mapa (“Ver detalhes”)
  final ValueNotifier<String?> _selectedPropertyIdVN = ValueNotifier<String?>(null);

  // 🔄 Notificador para forçar reload do mapa (markers/polígonos)
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

  // Confirma e apaga o traçado salvo (projeto/Board)
  Future<void> _confirmDeleteProjectGeometry() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar traçado'),
        content: const Text(
          'Tem certeza que deseja remover o traçado (geometry) salvo para este contrato? '
              'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );

    if (ok == true && mounted) {
      final bloc = context.read<ScheduleRoadBloc>();
      bloc.add(const ScheduleProjectDeleteRequested());
      bloc.add(const ScheduleRefreshRequested());

      // 🔄 força refresh do mapa
      _mapRefreshVN.value++;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traçado removido.')),
      );
    }
  }

  // Painel à direita: alterna entre “genérico” e “detalhes”
  Widget _buildRightPanel() {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedPropertyIdVN,
      builder: (ctx, propId, _) {
        if (propId == null) {
          // Painel padrão (cards de ações)
          return PlanningRightWayPropertyPanel(
            contractData: widget.contractData,
            // ✅ ao voltar do formulário, peça o refresh do mapa
            onRequestMapRefresh: () => _mapRefreshVN.value++,
          );
        }
        // Painel de detalhes do imóvel selecionado
        return PlanningRightWayPropertyDetailsPanel(
          contract: widget.contractData,
          propertyId: propId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kRightPanelWidth = 600.0;

    final left = Stack(
      children: [
        PlanningRightWayPropertyMap(
          contractData: widget.contractData,
          externalPanelController: _panelVN,                  // abre/fecha via mapa
          selectedPropertyIdNotifier: _selectedPropertyIdVN,  // recebe o propertyId do mapa
          refreshListenable: _mapRefreshVN,                   // ✅ liga o refresh do mapa
        ),

        GeoJsonActionsButtons(
          collectionPath: 'planning_highway_domain',
          initiallyExpanded: true,
          position: const GeoJsonActionsPosition.bottomLeft(),
          onImportGeoJson: (ctx) async {
            final bloc = context.read<ScheduleRoadBloc>();
            try {
              await GeoJsonSendFirebase(ctx, fixedPath: 'planning_highway_domain');
            } finally {
              bloc.add(const ScheduleRefreshRequested());
              // 🔄 força refresh do mapa logo após o import
              _mapRefreshVN.value++;
            }
          },
          onDeleteCollection: () async => _confirmDeleteProjectGeometry(),
          onCheckDistances: () async {},
        ),
      ],
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
                icon: Icon(_panelOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined, color: Colors.white),
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            return isWide
                ? Row(
              children: [
                Expanded(child: left),
                if (_panelOpen) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(width: kRightPanelWidth, child: rightPanel),
                ],
              ],
            )
                : Column(
              children: [
                Expanded(child: left),
                if (_panelOpen) ...[
                  const Divider(height: 1),
                  SizedBox(height: 420, child: rightPanel),
                ],
              ],
            );
          },
        ),
        bottomNavigationBar: const FootBar(),
      ),
    );
  }
}
