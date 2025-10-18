import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_services/dxf/dxf_enums.dart';
import 'package:siged/_services/dxf/map_overlay_cubit.dart';
import 'package:siged/_widgets/toolBox/tool_widget.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';

import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/civil/civil_schedule_event.dart';
import 'package:siged/_widgets/schedule/civil/schedule_civil_widget.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ScheduleCivilPage extends StatelessWidget {
  const ScheduleCivilPage({
    super.key,
    required this.title,
    required this.controller,
    required this.contractId,
    this.pageNumber = 1,          // ignorado em DXF (mantido por compatibilidade)
    this.initialPdfBytes,         // bytes do DXF (nome mantido por compatibilidade)
    this.allowPickNewPdf = true,  // permite escolher novo DXF (nome mantido)
  });

  final String title;
  final String contractId;
  final int pageNumber;
  final Uint8List? initialPdfBytes;
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;

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
                TextField(
                  controller: txt,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Digite um nome',
                    border: UnderlineInputBorder(),
                  ),
                  onSubmitted: (_) => Navigator.of(ctx).pop(txt.text.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancelar'),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // DXF não tem páginas → inicializa sempre com página 0
      create: (_) => CivilScheduleBloc()
        ..add(CivilWarmupRequested(contractId, initialPage: 0)),
      child: Scaffold(
        body: Stack(
          children: [
            ScheduleCivilWidget(
              title: title,
              controller: controller,
              initialPdfBytes: initialPdfBytes, // tratado como DXF no widget
              pageNumber: 1,                    // fixo (DXF)
              allowPickNewPdf: allowPickNewPdf,
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
            Positioned.fill(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final ready = controller.pagePixelSize != null;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: !ready
                        ? const SizedBox.shrink()
                        : ToolBoxWidget(
                      topPadding: MediaQuery.of(context).padding.top + 72 + 8,
                      snapEnabled: controller.snapEnabled,
                      snapRadius: controller.snapRadius,
                      snapMinGradient: controller.snapMinGradient,
                      canFinishPolygon: controller.canFinishPolygon,
                      canUndo: controller.current.isNotEmpty ||
                          controller.features.isNotEmpty ||
                          controller.texts.isNotEmpty,
                      canClear: controller.current.isNotEmpty ||
                          controller.features.isNotEmpty ||
                          controller.texts.isNotEmpty,
                      hasSelection: controller.hasSelection,
                      onActivatePolygonMode: controller.activateDraw,
                      onActivateSelectionMode: controller.activateSelect,
                      onActivateTextMode: controller.activateText,
                      onToggleSnap: controller.toggleSnap,
                      onChangeSnapRadius: controller.changeSnapRadius,
                      onChangeSnapThreshold: controller.changeSnapThreshold,

                      // ========= FINALIZAR & SALVAR =========
                      onFinishPolygon: () async {
                        await controller.finishPolygon(
                          onAskName: (_) => _askAreaName(context, initial: 'Área'),
                        );
                      },

                      onUndo: controller.undo,
                      onClear: controller.clearAll,
                      onRenameSelected: () => controller.renameSelected(
                        onAskName: (s) => _askAreaName(context, initial: s ?? '').then((v) => v ?? s ?? ''),
                      ),
                      onDeleteSelected: controller.deleteSelected,
                      buildGeoJSON: (normalized) => controller.exportGeoJSON(
                        sourceKind: SourceKind.dxf,
                        pageNumber: 1,
                        normalized: normalized,
                      ),

                      copyToClipboard: (txt) async {
                        await Clipboard.setData(ClipboardData(text: txt));
                        if (context.mounted) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: Text('Copiado'),
                              subtitle: Text('Conteúdo enviado para a área de transferência.'),
                              type: AppNotificationType.info,
                              duration: Duration(seconds: 2),
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
      ),
    );
  }
}
