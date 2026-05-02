// lib/screens/modules/operation/operation/civil/schedule_civil_workspace_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';

import 'package:sipged/screens/modules/operation/schedule/physical/vertical/schedule_civil_controller.dart';

import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_event.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/vertical/schedule_civil_widget.dart';

import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

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

    setState(() => _panelOpen = !_panelOpen);
  }

  ProcessData get _notificationContract {
    final id = _cleanContractId;

    if (id.isEmpty) {
      return ProcessData.empty();
    }

    return ProcessData.empty().copyWith(id: id);
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

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return BlocProvider<CivilScheduleBloc>(
      create: (_) => CivilScheduleBloc()
        ..add(
          CivilWarmupRequested(
            _cleanContractId,
            initialPage: 0,
          ),
        ),
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
                contractId: _cleanContractId,
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