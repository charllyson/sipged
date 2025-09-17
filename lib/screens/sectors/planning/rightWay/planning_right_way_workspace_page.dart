// lib/screens/sectors/planning/projects/schedule_road_workspace_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// Estado unificado (usado para refresh após import)
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';

// MAPA e PAINEL
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_map.dart';
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_panel.dart';

// 🔹 Botões/serviço de import
import 'package:siged/_widgets/services/floating_buttons.dart';
import 'package:siged/_services/geoJson/send_firebase.dart';

// ⬇️ ADICIONE:
import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';

class PlanningRightOfWayWorkspacePage extends StatefulWidget {
  final ContractData contractData;
  const PlanningRightOfWayWorkspacePage({super.key, required this.contractData});

  @override
  State<PlanningRightOfWayWorkspacePage> createState() =>
      _PlanningRightOfWayWorkspacePageState();
}

class _PlanningRightOfWayWorkspacePageState
    extends State<PlanningRightOfWayWorkspacePage> {
  bool _panelOpen = false;
  final ValueNotifier<bool> _panelVN = ValueNotifier<bool>(false);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traçado removido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double kRightPanelWidth = 600.0;

    final left = Stack(
      children: [
        PlanningRightWayMap(
          contractData: widget.contractData,
          externalPanelController: _panelVN,
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
            }
          },
          onDeleteCollection: () async => _confirmDeleteProjectGeometry(),
          onCheckDistances: () async {},
        ),
      ],
    );

    final rightPanel = PlanningRightWayPanel(contractData: widget.contractData);

    return BlocProvider<PlanningHighwayDomainBloc>(
      create: (_) => PlanningHighwayDomainBloc(), // ✅ usa o repo padrão
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
