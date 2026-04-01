// lib/screens/modules/planning/sigmine/panels/planning_project_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// ✅ Cubit do cronograma (novo)
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';

// Pie
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';

// Editor de faixas
import 'package:sipged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_edit_section.dart';

// Header/SubHeader
import 'package:sipged/_widgets/schedule/linear/schedule_header.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ScheduleRoadPanel extends StatefulWidget {
  final ProcessData contract;
  final bool enabled;
  final VoidCallback? onSaved; // callback após salvar (opcional)

  const ScheduleRoadPanel({
    super.key,
    required this.contract,
    this.enabled = true,
    this.onSaved,
  });

  @override
  State<ScheduleRoadPanel> createState() => _ScheduleRoadPanelState();
}

class _ScheduleRoadPanelState extends State<ScheduleRoadPanel> {
  Future<void> _openEditLanes(
      BuildContext context,
      ScheduleRoadState st,
      ) async {
    final rows = await showDialog<List<ScheduleLaneClass>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScheduleLaneEdit(
        initialRows: st.lanes,
        selectedServiceKey: st.currentServiceKey,
        selectedServiceLabel: st.titleForHeader,
      ),
    );

    if (rows != null && context.mounted) {
      // ✅ Agora chamando o método do Cubit (sem eventos)
      context.read<ScheduleRoadCubit>().saveLanes(rows);

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Faixas atualizadas'),
          type: AppNotificationType.success,
          duration: const Duration(seconds: 3),
        ),
      );
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bool showHeaderSpinner = false;
    (showHeaderSpinner); // só pra evitar warning de não uso caso queira ativar depois

    return Stack(
      children: [
        BackgroundChange(),
        BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
          builder: (ctx, st) {
            final canEdit = widget.enabled && !st.loadingLanes;
            final double vConcluido =
            (st.pctConcluido).isFinite ? (st.pctConcluido) : 0;
            final double vAndamento =
            (st.pctAndamento).isFinite ? (st.pctAndamento) : 0;
            final double vAIniciar =
            (st.pctAIniciar).isFinite ? (st.pctAIniciar) : 0;

            final labels = const ['Concluído', 'Em andamento', 'A iniciar'];
            final values = <double>[vConcluido, vAndamento, vAIniciar];

            // Cores padrão (consistentes com status)
            final cores = <Color>[
              Colors.green.shade600, // Concluído
              Colors.amber.shade700, // Em andamento
              Colors.blueGrey.shade400, // A iniciar
            ];

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  ScheduleHeader(
                    title: st.titleForHeader.isEmpty
                        ? (st.summarySubjectContract ?? 'Cronograma')
                        : st.titleForHeader,
                    colorStripe: st.colorForHeader,
                    leftPadding: 0,
                  ),
                  const SizedBox(height: 8),

                  // ===================== Pie de Status =====================
                  DonutChartChanged(
                    colorCard: Colors.white,
                    valueFormatType: ValueFormatType.decimal,
                    labels: labels,
                    values: values,
                    colorsSlices: cores,
                    selectedIndex: null,
                    heightGraphic: 220,
                  ),

                  const SizedBox(height: 16),

                  // ===================== Ações =====================
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Editar faixas'),
                        onPressed:
                        canEdit ? () => _openEditLanes(context, st) : null,
                      ),
                      const SizedBox(width: 12),
                      if (st.loadingLanes)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===================== Informações do contrato/serviço =====================
                  _kv(
                    'Serviço atual',
                    st.titleForHeader.isEmpty ? 'GERAL' : st.titleForHeader,
                  ),
                  _kv('Qtd. faixas', '${st.lanes.length}'),
                  _kv('Estacas (20 m)', '${st.totalEstacas}'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
