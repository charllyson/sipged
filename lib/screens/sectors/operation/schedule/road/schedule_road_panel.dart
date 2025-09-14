// lib/screens/sectors/planning/projects/schedule_road_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_state.dart';

class PlanningProjectPanel extends StatelessWidget {
  const PlanningProjectPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleRoadBoardBloc, ScheduleRoadBoardState>(
      builder: (context, st) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                st.summarySubjectContract ?? 'Contrato',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('ContractId: ${st.contractId ?? "-"}'),
              const SizedBox(height: 12),
              Text('Estacas (20 m): ${st.totalEstacas}'),
            ],
          ),
        );
      },
    );
  }
}
