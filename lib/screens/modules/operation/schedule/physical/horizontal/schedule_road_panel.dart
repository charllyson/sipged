import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/horizontal/lane/schedule_lane_edit_section.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/horizontal/schedule_header.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ScheduleRoadPanel extends StatefulWidget {
  final ProcessData contract;
  final bool enabled;
  final VoidCallback? onSaved;

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
  bool _importingGeometry = false;

  Future<void> _openEditLanes(
      BuildContext context,
      ScheduleRoadState st,
      ) async {
    final cubit = context.read<ScheduleRoadCubit>();

    final rows = await showDialog<List<ScheduleRoadData>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScheduleLaneEdit(
        initialRows: st.lanes,
        selectedServiceKey: st.currentServiceKey,
        selectedServiceLabel: st.titleForHeader,
      ),
    );

    if (!mounted) return;

    if (rows != null) {
      cubit.saveLanes(rows);

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

  Future<void> _importGeometry(
      BuildContext context,
      ScheduleRoadState st,
      ) async {
    if (_importingGeometry) return;

    final cubit = context.read<ScheduleRoadCubit>();

    final summarySubjectContract =
        st.summarySubjectContract ?? widget.contract.id;

    setState(() => _importingGeometry = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['geojson', 'json'],
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        throw Exception(
          'Não foi possível ler o arquivo no navegador. Tente selecionar novamente.',
        );
      }

      final raw = utf8.decode(bytes);
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('O arquivo selecionado não contém um GeoJSON válido.');
      }

      await cubit.importGeoJson(
        geojson: decoded,
        summarySubjectContract: summarySubjectContract,
      );

      if (!mounted) return;

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Geometria importada com sucesso'),
          type: AppNotificationType.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao importar geometria: $e'),
          type: AppNotificationType.error,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _importingGeometry = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackgroundChange(),
        BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
          builder: (ctx, st) {
            final canEdit = widget.enabled && !st.loadingLanes && !st.isBusy;

            final canImportGeometry =
                widget.enabled && !_importingGeometry && !st.isBusy;

            final double vConcluido =
            st.pctConcluido.isFinite ? st.pctConcluido : 0;

            final double vAndamento =
            st.pctAndamento.isFinite ? st.pctAndamento : 0;

            final double vAIniciar =
            st.pctAIniciar.isFinite ? st.pctAIniciar : 0;

            final labels = const [
              'Concluído',
              'Em andamento',
              'A iniciar',
            ];

            final values = <double>[
              vConcluido,
              vAndamento,
              vAIniciar,
            ];

            final cores = <Color>[
              Colors.green.shade600,
              Colors.amber.shade700,
              Colors.blueGrey.shade400,
            ];

            final hasGeometry = st.axis.isNotEmpty ||
                (st.multiLine?.isNotEmpty ?? false) ||
                (st.points?.isNotEmpty ?? false);

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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Editar faixas'),
                        onPressed: canEdit
                            ? () => _openEditLanes(context, st)
                            : null,
                      ),
                      FilledButton.icon(
                        icon: _importingGeometry
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          hasGeometry
                              ? 'Reimportar geometria'
                              : 'Importar geometria',
                        ),
                        onPressed: canImportGeometry
                            ? () => _importGeometry(context, st)
                            : null,
                      ),
                      if (st.loadingLanes)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: LoadingTreeDotsGrey(
                            size: 18,
                            centered: false,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _kv(
                    'Serviço atual',
                    st.titleForHeader.isEmpty ? 'GERAL' : st.titleForHeader,
                  ),
                  _kv('Qtd. faixas', '${st.lanes.length}'),
                  _kv('Estacas (20 m)', '${st.totalEstacas}'),
                  _kv(
                    'Geometria',
                    hasGeometry ? 'Carregada' : 'Não carregada',
                  ),
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
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(v),
          ),
        ],
      ),
    );
  }
}