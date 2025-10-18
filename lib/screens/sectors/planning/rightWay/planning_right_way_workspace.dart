import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';

// Estado unificado (usado para refresh após import)
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/screens/process/landRegularization/lane_regularization_details.dart';

// MAPA e PAINEL
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_map.dart';
import 'package:siged/screens/sectors/planning/rightWay/planning_right_way_panel.dart';

// 🔹 Botões/serviço de import

// Bloc do domínio (opcional se já estiver em outro lugar)
import 'package:siged/_blocs/sectors/planning/highway_domain/planning_highway_domain_bloc.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

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
      _mapRefreshVN.value++;
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Traçado removido'),
          type: AppNotificationType.success,
          duration: Duration(seconds: 3),
        ),
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
        return LaneRegularizationDetailsPanel(
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
          // Exemplo: para chamar a remoção via painel/mapa, use _confirmDeleteProjectGeometry()
          // e.g., onRequestDeleteGeometry: _confirmDeleteProjectGeometry,
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
              IconButton(
                tooltip: 'Apagar traçado salvo',
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _confirmDeleteProjectGeometry,
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
