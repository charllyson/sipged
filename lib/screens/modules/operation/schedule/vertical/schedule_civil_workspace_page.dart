// lib/screens/modules/operation/operation/civil/schedule_civil_workspace_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_event.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_repository.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
 import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_controller.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_widget.dart';

import 'schedule_civil_panel.dart';

class ScheduleCivilWorkspacePage extends StatefulWidget {
  const ScheduleCivilWorkspacePage({
    super.key,
    required this.title,
    required this.controller,
    required this.contractId,
    this.pageNumber = 1,
    this.initialPdfBytes,
    this.allowPickNewPdf = true,
    this.targetUserIds = const <String>[],
  });

  final String title;
  final String contractId;
  final int pageNumber;
  final Uint8List? initialPdfBytes;
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;

  /// Destinatários explícitos para sino/push.
  ///
  /// Esta página possui apenas `contractId` e `title`, então não consegue
  /// resolver sozinha os usuários vinculados ao contrato.
  ///
  /// Se quiser enviar para fiscais/gestores/participantes, envie a lista
  /// pela tela pai.
  final Iterable<String> targetUserIds;

  @override
  State<ScheduleCivilWorkspacePage> createState() =>
      _ScheduleCivilWorkspacePageState();
}

class _ScheduleCivilWorkspacePageState
    extends State<ScheduleCivilWorkspacePage> {
  bool _panelOpen = false;

  static const double kRightPanelWidth = 520.0;
  static const double kBottomPanelHeight = 380.0;
  static const double kBreakpoint = 980.0;

  String get _cleanTitle {
    final value = widget.title.trim();

    return value.isEmpty ? 'Cronograma civil' : value;
  }

  String get _cleanContractId => widget.contractId.trim();

  String get _module => 'operation_schedule_civil';

  void _togglePanel() {
    if (!mounted) return;

    setState(() {
      _panelOpen = !_panelOpen;
    });
  }

  String _resolveTenantId(BuildContext context) {
    try {
      final PermissionState permissionState =
          context.read<PermissionCubit>().state;

      return permissionState.activeTenantId?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  ContractData get _notificationContract {
    final id = _cleanContractId;

    if (id.isEmpty) {
      return ContractData.empty();
    }

    return ContractData.empty().copyWith(id: id);
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final cleanTitle = title.trim();
    final cleanSubtitle = subtitle?.trim();
    final cleanDetails = details?.trim();

    final contract = _notificationContract;

    await NotificationSchedule.show(
      context: context,
      contract: contract,
      title: cleanTitle.isEmpty ? 'Cronograma civil' : cleanTitle,
      subtitle: cleanSubtitle?.isNotEmpty == true ? cleanSubtitle : null,
      details: cleanDetails?.isNotEmpty == true ? cleanDetails : _cleanTitle,
      leadingLabel: 'Civil',
      module: _module,
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      targetUserIds: widget.targetUserIds,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'module': _module,
        'route': _module,
        'contractId': _cleanContractId,
        'contractTitle': _cleanTitle,
        'contractSummary': _cleanTitle,
        'source': 'schedule_civil_workspace_page',
        'sendPush': sendPush,
        ...extra,
      },
    );
  }

  Future<void> _notifyDxfSent({
    required int lines,
    required int totalVertices,
  }) async {
    await _notify(
      title: 'DXF enviado ao mapa',
      subtitle: '$lines linha(s), $totalVertices vértice(s)',
      details: _cleanTitle,
      type: NotificationStatus.success,
      duration: const Duration(seconds: 3),
      saveInBell: true,
      sendPush: false,
      extra: <String, dynamic>{
        'action': 'civil_dxf_sent_to_map',
        'lines': lines,
        'totalVertices': totalVertices,
      },
    );
  }

  Widget _buildInvalidContext({
    required String title,
    required String message,
  }) {
    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(_cleanTitle),
        ],
      ),
      bottomNavigationBar: const FootBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundChange(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 44,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    final tenantId = _resolveTenantId(context);
    final contractId = _cleanContractId;

    if (tenantId.isEmpty) {
      return _buildInvalidContext(
        title: 'Tenant não selecionado',
        message:
        'Não foi possível abrir o cronograma civil porque o tenant ativo não foi identificado.',
      );
    }

    if (contractId.isEmpty) {
      return _buildInvalidContext(
        title: 'Contrato inválido',
        message:
        'Não foi possível abrir o cronograma civil porque o ID do contrato está vazio.',
      );
    }

    return BlocProvider<CivilScheduleBloc>(
      create: (_) {
        final repository = CivilScheduleRepository(
          tenantId: tenantId,
        );

        return CivilScheduleBloc(
          tenantId: tenantId,
          repository: repository,
        )..add(
          CivilWarmupRequested(
            contractId,
            initialPage: widget.pageNumber > 0 ? widget.pageNumber - 1 : 0,
          ),
        );
      },
      child: Scaffold(
        appBar: UpBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: CircleButtonChange(),
          ),
          titleWidgets: [
            Text(_cleanTitle),
          ],
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
        bottomNavigationBar: const FootBar(),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const BackgroundChange(),
            SplitLayout(
              left: Stack(
                children: [
                  ScheduleCivilWidget(
                    title: _cleanTitle,
                    controller: ctrl,
                    initialPdfBytes: widget.initialPdfBytes,
                    pageNumber: widget.pageNumber,
                    allowPickNewPdf: widget.allowPickNewPdf,
                    onPolylinesReady: (lines) {
                      final totalVertices = lines.fold<int>(
                        0,
                            (total, line) => total + line.length,
                      );

                      context.read<MapOverlayCubit>().showDxfPolylines(lines);

                      unawaited(
                        _notifyDxfSent(
                          lines: lines.length,
                          totalVertices: totalVertices,
                        ),
                      );
                    },
                  ),
                ],
              ),
              right: ScheduleCivilPanel(
                title: _cleanTitle,
                contractId: contractId,
                controller: ctrl,
              ),
              showRightPanel: _panelOpen,
              breakpoint: kBreakpoint,
              rightPanelWidth: kRightPanelWidth,
              bottomPanelHeight: kBottomPanelHeight,
              showDividers: true,
              dividerThickness: 12.0,
              dividerBackgroundColor: Colors.white,
              dividerBorderColor: Colors.black12,
              gripColor: const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }
}