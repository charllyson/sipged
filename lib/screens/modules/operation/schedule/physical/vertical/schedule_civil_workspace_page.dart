// lib/screens/modules/operation/operation/civil/schedule_civil_workspace_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

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
  });

  final String title;
  final String contractId;
  final int pageNumber;
  final Uint8List? initialPdfBytes;
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;

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

  void _togglePanel() {
    if (!mounted) return;

    setState(() => _panelOpen = !_panelOpen);
  }

  void _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    if (!mounted) return;

    final cleanTitle = title.trim();
    final cleanSubtitle = subtitle?.trim();
    final cleanDetails = details?.trim();
    final cleanContractId = widget.contractId.trim();
    final cleanModule = 'operation_schedule_civil';

    context.read<NotificationCubit>().show(
      NotificationData(
        title: cleanTitle.isEmpty ? 'Cronograma civil' : cleanTitle,
        subtitle: cleanSubtitle?.isNotEmpty == true ? cleanSubtitle : null,
        details: cleanDetails?.isNotEmpty == true
            ? cleanDetails
            : widget.title,
        leadingLabel: 'Civil',
        type: type,
        duration: duration,
        persistInFirebase: saveInBell,
        sendPush: sendPush,
        extra: <String, dynamic>{
          'module': cleanModule,
          'route': cleanModule,
          'contractId': cleanContractId,
          'contractTitle': widget.title,
          'contractSummary': widget.title,
          'source': 'schedule_civil_workspace_page',
          'sendPush': sendPush,
          ...extra,
        },
      ),
      saveInFirebase: saveInBell,
      sendPush: sendPush,
    );
  }

  void _notifyDxfSent({
    required int lines,
    required int totalVertices,
  }) {
    _notify(
      title: 'DXF enviado ao mapa',
      subtitle: '$lines linha(s), $totalVertices vértice(s)',
      details: widget.title,
      type: NotificationType.success,
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

    return BlocProvider(
      create: (_) => CivilScheduleBloc()
        ..add(
          CivilWarmupRequested(
            widget.contractId,
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
            Text(
              widget.title.trim().isEmpty ? 'Cronograma civil' : widget.title,
            ),
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
                    title: widget.title,
                    controller: ctrl,
                    initialPdfBytes: widget.initialPdfBytes,
                    pageNumber: widget.pageNumber,
                    allowPickNewPdf: widget.allowPickNewPdf,
                    onPolylinesReady: (lines) {
                      final total = lines.fold<int>(
                        0,
                            (a, b) => a + b.length,
                      );

                      context.read<MapOverlayCubit>().showDxfPolylines(lines);

                      _notifyDxfSent(
                        lines: lines.length,
                        totalVertices: total,
                      );
                    },
                  ),
                ],
              ),
              right: ScheduleCivilPanel(
                title: widget.title,
                contractId: widget.contractId,
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