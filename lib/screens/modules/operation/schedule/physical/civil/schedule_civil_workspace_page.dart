// lib/screens/modules/operation/operation/civil/schedule_civil_workspace_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_services/files/dxf/dxf_enums.dart';
import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

// UpBar / FootBar / BG
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';

// Toolbox de desenho
import 'package:sipged/_widgets/toolBox/tool_widget.dart';
import 'package:sipged/_widgets/toolBox/tool_box_controller.dart';

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
  Future<String?> _askAreaName(BuildContext context, {String initial = ''}) async {
    final txt = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nome da área', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: txt,
                  labelText: 'Digite um nome',
                  onSubmitted: (_) => Navigator.of(ctx).pop(txt.text.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(txt.text.trim()),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return (result != null && result.trim().isNotEmpty) ? result.trim() : null;
  }

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
                  Positioned.fill(
                    child: ScheduleCivilWidget(
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
                  ),

                  // Toolbox flutuante — desloca quando painel abre no wide
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: ctrl,
                      builder: (context, _) {
                        final ready = ctrl.pagePixelSize != null;

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !ready
                              ? const SizedBox.shrink()
                              : ToolBoxWidget(
                            // Mantém a posição sob a UpBar e acima da FootBar
                            topPadding: MediaQuery.paddingOf(context).top + 72 + 8,
                            snapEnabled: ctrl.snapEnabled,
                            snapRadius: ctrl.snapRadius,
                            snapMinGradient: ctrl.snapMinGradient,
                            canFinishPolygon: ctrl.canFinishPolygon,
                            canUndo: ctrl.current.isNotEmpty ||
                                ctrl.features.isNotEmpty ||
                                ctrl.texts.isNotEmpty,
                            canClear: ctrl.current.isNotEmpty ||
                                ctrl.features.isNotEmpty ||
                                ctrl.texts.isNotEmpty,
                            hasSelection: ctrl.hasSelection,

                            onActivatePolygonMode: ctrl.activateDraw,
                            onActivateSelectionMode: ctrl.activateSelect,
                            onActivateTextMode: ctrl.activateText,
                            onToggleSnap: ctrl.toggleSnap,
                            onChangeSnapRadius: ctrl.changeSnapRadius,
                            onChangeSnapThreshold: ctrl.changeSnapThreshold,

                            // Finaliza e pede nome
                            onFinishPolygon: () async {
                              await ctrl.finishPolygon(
                                onAskName: (_) => _askAreaName(context, initial: 'Área'),
                              );
                            },

                            onUndo: ctrl.undo,
                            onClear: ctrl.clearAll,
                            onRenameSelected: () => ctrl.renameSelected(
                              onAskName: (s) async {
                                final v = await _askAreaName(context, initial: s);
                                return v ?? s;
                              },
                            ),
                            onDeleteSelected: ctrl.deleteSelected,

                            buildGeoJSON: (normalized) => ctrl.exportGeoJSON(
                              sourceKind: SourceKind.dxf,
                              pageNumber: 1,
                              normalized: normalized,
                            ),

                            copyToClipboard: (txt) async {
                              await Clipboard.setData(ClipboardData(text: txt));
                              if (context.mounted) {
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    title: const Text('Copiado'),
                                    subtitle: const Text('Conteúdo enviado para a área de transferência.'),
                                    type: AppNotificationType.info,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
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
