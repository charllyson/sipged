// lib/screens/modules/operation/operation/civil/schedule_civil_workspace_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

// UpBar / FootBar / BG
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';

// Toolbox de desenho
import 'package:sipged/_widgets/schedule/civil/schedule_civil_controller.dart';

// Civil
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/operation/civil/civil_schedule_event.dart';
import 'package:sipged/_widgets/schedule/civil/schedule_civil_widget.dart';

// ✅ Split responsivo (lado a lado vs empilhado)
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

// Painel lateral civil
import 'schedule_civil_panel.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ScheduleCivilWorkspacePage extends StatefulWidget {
  const ScheduleCivilWorkspacePage({
    super.key,
    required this.title,
    required this.controller,
    required this.contractId,
    this.pageNumber = 1,          // ignorado em DXF (compat)
    this.initialPdfBytes,         // bytes do DXF (nome mantido)
    this.allowPickNewPdf = true,  // permite escolher novo DXF (nome mantido)
  });

  final String title;
  final String contractId;
  final int pageNumber;
  final Uint8List? initialPdfBytes;
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;

  @override
  State<ScheduleCivilWorkspacePage> createState() => _ScheduleCivilWorkspacePageState();
}

class _ScheduleCivilWorkspacePageState extends State<ScheduleCivilWorkspacePage> {
  bool _panelOpen = false;

  // Constantes visuais (alinhadas às outras telas)
  static const double kRightPanelWidth = 520.0;
  static const double kBottomPanelHeight = 380.0;
  static const double kBreakpoint = 980.0;

  // ---- diálogo com botão "Salvar" que devolve o nome digitado ----


  void _togglePanel() => setState(() => _panelOpen = !_panelOpen);

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return BlocProvider(
      // DXF não tem páginas → inicializa sempre com página 0
      create: (_) => CivilScheduleBloc()..add(CivilWarmupRequested(widget.contractId, initialPage: 0)),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
            actions: [
              IconButton(
                tooltip: _panelOpen ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(_panelOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined, color: Colors.white),
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),

        bottomNavigationBar: const FootBar(),

        body: Stack(
          fit: StackFit.expand,
          children: [
            const BackgroundClean(),

            // ====== Conteúdo base (canvas DXF) ======
            SplitLayout(

              left: Stack(
                children: [
                  // Canvas de desenho / DXF
                  ScheduleCivilWidget(
                    title: widget.title,
                    controller: ctrl,
                    initialPdfBytes: widget.initialPdfBytes, // tratado como DXF no widget
                    pageNumber: 1,                            // fixo (DXF)
                    allowPickNewPdf: widget.allowPickNewPdf,
                    onPolylinesReady: (lines) {
                      final total = lines.fold<int>(0, (a, b) => a + b.length);
                      context.read<MapOverlayCubit>().showDxfPolylines(lines);
                      NotificationCenter.instance.show(
                        AppNotification(
                          title: const Text('DXF enviado ao mapa'),
                          subtitle: Text('${lines.length} linha(s), $total vértice(s)'),
                          type: AppNotificationType.success,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Painel lateral
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
