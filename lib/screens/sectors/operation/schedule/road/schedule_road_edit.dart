// lib/screens/sectors/planning/projects/panels/planning_project_edit_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// Bloc do Board (para acessar lanes, serviço atual e salvar)
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_event.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_state.dart';

// Editor de faixas
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_edit_section.dart';

class PlanningProjectEditPanel extends StatefulWidget {
  final ContractData contract;
  final bool enabled;
  final VoidCallback? onSaved; // opcional: callback após "Salvar" (stub)

  const PlanningProjectEditPanel({
    super.key,
    required this.contract,
    this.enabled = true,
    this.onSaved,
  });

  @override
  State<PlanningProjectEditPanel> createState() => _PlanningProjectEditPanelState();
}

class _PlanningProjectEditPanelState extends State<PlanningProjectEditPanel> {

  Future<void> _openEditLanes(BuildContext context, ScheduleRoadBoardState st) async {
    final rows = await showDialog<List<ScheduleLaneClass>>(
      context: context,
      builder: (_) => ScheduleLaneEdit(
        initialRows: st.lanes,
        selectedServiceKey: st.currentServiceKey,
        selectedServiceLabel: st.titleForHeader,
      ),
    );

    if (rows != null && context.mounted) {
      context.read<ScheduleRoadBoardBloc>().add(ScheduleLanesSaveRequested(rows));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faixas atualizadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleRoadBoardBloc, ScheduleRoadBoardState>(
      builder: (ctx, st) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Botão para editar FAIXAS (agora aqui!)
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Editar faixas'),
                onPressed: () => _openEditLanes(context, st),
              ),
            ],
          ),
        );
      },
    );
  }
}
