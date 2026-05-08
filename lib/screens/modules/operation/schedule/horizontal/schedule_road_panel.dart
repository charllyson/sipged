import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_lane_edit_section.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_header.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class ScheduleRoadPanel extends StatefulWidget {
  final ContractData contract;
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

  String _actorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  void _notify({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Cronograma',
        type: type,
        duration: duration,
      ),
    );
  }

  Future<void> _notifySchedule({
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = true,
    bool sendPush = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final actorId = currentUser?.uid.trim();
    final actorName = _actorName();

    await NotificationSchedule.show(
      context: context,
      contract: widget.contract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: leadingLabel ?? 'Cronograma',
      module: 'operation_schedule_road',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: actorId,
      actorName: actorName,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'actorId': actorId,
        'actorName': actorName,
        ...extra,
      },
    );
  }

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
    if (rows == null) return;

    try {
      await cubit.saveLanes(rows);

      await _notifySchedule(
        title: 'Faixas do cronograma atualizadas',
        subtitle: '${rows.length} faixa(s) configurada(s) por ${_actorName()}.',
        details: st.summarySubjectContract ?? widget.contract.displaySummary,
        type: NotificationStatus.success,
        duration: const Duration(seconds: 4),
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'schedule_lanes_updated',
          'serviceKey': st.currentServiceKey,
          'serviceLabel': st.titleForHeader,
          'lanesCount': rows.length,
          'totalEstacas': st.totalEstacas,
          'source': 'schedule_road_panel',
        },
      );

      widget.onSaved?.call();
    } catch (e) {
      _notify(
        title: 'Erro ao salvar faixas',
        subtitle: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _importGeometry(
      BuildContext context,
      ScheduleRoadState st,
      ) async {
    if (_importingGeometry) return;

    final cubit = context.read<ScheduleRoadCubit>();

    final contractId = st.contractId ?? widget.contract.id ?? '';
    final summarySubjectContract =
        st.summarySubjectContract ?? widget.contract.displaySummary;

    if (contractId.isEmpty) {
      _notify(
        title: 'Contrato inválido',
        subtitle: 'Não foi possível identificar o contrato.',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
      return;
    }

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

      await _notifySchedule(
        title: 'Geometria do cronograma importada',
        subtitle: file.name.isNotEmpty
            ? 'Arquivo ${file.name} importado por ${_actorName()}.'
            : 'Geometria importada por ${_actorName()}.',
        details: summarySubjectContract,
        type: NotificationStatus.success,
        duration: const Duration(seconds: 4),
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'schedule_geometry_imported',
          'contractId': contractId,
          'serviceKey': st.currentServiceKey,
          'serviceLabel': st.titleForHeader,
          'fileName': file.name,
          'totalEstacas': st.totalEstacas,
          'source': 'schedule_road_panel',
        },
      );

      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;

      _notify(
        title: 'Erro ao importar geometria',
        subtitle: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
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
        const BackgroundChange(),
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
                        onPressed:
                        canEdit ? () => _openEditLanes(context, st) : null,
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
                          child: LoadingTreeDots(
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