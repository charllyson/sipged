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
import 'package:sipged/screens/modules/operation/schedule/lanes/schedule_lane_edit.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_header.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class ScheduleLinearPanel extends StatefulWidget {
  final ContractData contract;
  final bool enabled;
  final VoidCallback? onSaved;

  const ScheduleLinearPanel({
    super.key,
    required this.contract,
    this.enabled = true,
    this.onSaved,
  });

  @override
  State<ScheduleLinearPanel> createState() => _ScheduleLinearPanelState();
}

class _ScheduleLinearPanelState extends State<ScheduleLinearPanel> {
  bool _importingGeometry = false;
  bool _savingConfiguration = false;

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
      ScheduleRoadState state,
      ) async {
    if (_savingConfiguration) return;

    final cubit = context.read<ScheduleRoadCubit>();

    final result = await showDialog<ScheduleLaneResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScheduleLaneEdit(
        initialRows: state.lanes,
        initialServices: state.services,
        selectedServiceKey: state.currentServiceKey,
        selectedServiceLabel: state.titleForHeader,
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    setState(() {
      _savingConfiguration = true;
    });

    try {
      await cubit.saveScheduleConfiguration(
        lanes: result.lanes,
        services: result.services,
      );

      /// Força a releitura completa do documento:
      /// /tenants/{tenantId}/contracts/{contractId}/schedule/lanes
      ///
      /// Isso evita o mapa ficar preso em cache ou em um estado anterior.
      await cubit.refresh();

      if (!mounted) return;

      final refreshedState = cubit.state;

      await _notifySchedule(
        title: 'Cronograma configurado',
        subtitle:
        '${refreshedState.lanes.length} faixa(s) e ${refreshedState.services.length} serviço(s) configurado(s) por ${_actorName()}.',
        details:
        refreshedState.summarySubjectContract ?? widget.contract.displaySummary,
        type: NotificationStatus.success,
        duration: const Duration(seconds: 4),
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'schedule_configuration_updated',
          'serviceKey': refreshedState.currentServiceKey,
          'serviceLabel': refreshedState.titleForHeader,
          'lanesCount': refreshedState.lanes.length,
          'servicesCount': refreshedState.services.length,
          'totalEstacas': refreshedState.totalEstacas,
          'source': 'schedule_road_panel',
        },
      );

      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;

      _notify(
        title: 'Erro ao salvar configuração',
        subtitle: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingConfiguration = false;
        });
      }
    }
  }

  Future<void> _importGeometry(
      BuildContext context,
      ScheduleRoadState state,
      ) async {
    if (_importingGeometry) return;

    final cubit = context.read<ScheduleRoadCubit>();

    final contractId = state.contractId ?? widget.contract.id ?? '';
    final summarySubjectContract =
        state.summarySubjectContract ?? widget.contract.displaySummary;

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

      await cubit.refresh();

      if (!mounted) return;

      final refreshedState = cubit.state;

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
          'serviceKey': refreshedState.currentServiceKey,
          'serviceLabel': refreshedState.titleForHeader,
          'fileName': file.name,
          'totalEstacas': refreshedState.totalEstacas,
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
          builder: (context, state) {
            final canEdit = widget.enabled &&
                !_savingConfiguration &&
                !state.loadingLanes &&
                !state.loadingServices &&
                !state.isBusy;

            final canImportGeometry = widget.enabled &&
                !_importingGeometry &&
                !_savingConfiguration &&
                !state.isBusy;

            final double vConcluido =
            state.pctConcluido.isFinite ? state.pctConcluido : 0;

            final double vAndamento =
            state.pctAndamento.isFinite ? state.pctAndamento : 0;

            final double vAIniciar =
            state.pctAIniciar.isFinite ? state.pctAIniciar : 0;

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

            final hasGeometry = state.axis.isNotEmpty ||
                (state.multiLine?.isNotEmpty ?? false) ||
                (state.points?.isNotEmpty ?? false);

            final isWorking = state.loadingLanes ||
                state.loadingServices ||
                state.loadingExecucoes ||
                state.savingOrImporting ||
                _savingConfiguration ||
                _importingGeometry;

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  ScheduleHeader(
                    title: state.titleForHeader.isEmpty
                        ? (state.summarySubjectContract ?? 'Cronograma')
                        : state.titleForHeader,
                    colorStripe: state.colorForHeader,
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: _savingConfiguration
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.tune),
                        label: Text(
                          _savingConfiguration
                              ? 'Salvando configuração...'
                              : 'Faixas e serviços',
                        ),
                        onPressed: canEdit
                            ? () => _openEditLanes(
                          context,
                          state,
                        )
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
                            ? () => _importGeometry(
                          context,
                          state,
                        )
                            : null,
                      ),
                      if (isWorking)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: LoadingTreeDots(
                            size: 18,
                            centered: false,
                          ),
                        ),
                    ],
                  ),
                  if (state.error != null && state.error!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _errorBox(state.error!),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}