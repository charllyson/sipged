// lib/screens/sectors/actives/oaes/active_oaes_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:siged/_widgets/windows/show_window_dialog.dart';
import 'package:siged/screens/actives/oaes/network/maps/active_oaes_map_mapbox.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_cubit.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_repository.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/layout/split_layout/split_layout.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

import 'active_oaes_panel.dart';
import 'active_oaes_details.dart';
import '../../../../_blocs/actives/oaes/active_oaes_data.dart';

enum _RightPanelMode { none, analytics, details }

class ActiveOAEsNetworkPage extends StatefulWidget {
  const ActiveOAEsNetworkPage({super.key});

  @override
  State<ActiveOAEsNetworkPage> createState() =>
      _ActiveOAEsNetworkPageState();
}

class _ActiveOAEsNetworkPageState extends State<ActiveOAEsNetworkPage> {
  /// usamos o cubit GLOBAL fornecido no bootstrap.dart (não criamos outro aqui)
  final _repo = ActiveOaesRepository();

  _RightPanelMode _mode = _RightPanelMode.analytics;
  bool _showPanel = true;

  TaggedChangedMarker<ActiveOaesData>? _detailsMarker;
  int? _selectedSideIndex;

  // ======== FILTROS E PAINEL ========

  void _clearFilters() {
    final cubit = context.read<ActiveOaesCubit>();
    cubit.setPieFilter(null);
    cubit.setRegionFilter(null);
  }

  void _togglePanelVisibility() {
    setState(() => _showPanel = !_showPanel);
  }

  void _openDetails(TaggedChangedMarker<ActiveOaesData> marker) {
    setState(() {
      _mode = _RightPanelMode.details;
      _detailsMarker = marker;
      _selectedSideIndex = null;
      _showPanel = true;
    });
  }

  void _closePanel() {
    setState(() {
      _showPanel = false;
      _mode = _RightPanelMode.analytics;
      _detailsMarker = null;
      _selectedSideIndex = null;
    });
  }

  // =============================================================================
  // SIDE LISTBOX — ANEXOS (UPLOAD, EDITAR, EXCLUIR)
  // =============================================================================

  String _attachmentsDir(ActiveOaesData d) =>
      'actives_oaes/${d.id}/attachments';

  List<Attachment> _currentAttachments() =>
      _detailsMarker?.data.attachments ?? const <Attachment>[];

  Future<void> _persistAttachments(List<Attachment> next) async {
    final marker = _detailsMarker;
    final d = marker?.data;
    if (marker == null || d == null || d.id == null) return;

    final updated = d.copyWith(attachments: next);
    await _repo.upsert(updated);

    setState(() {
      _detailsMarker = TaggedChangedMarker<ActiveOaesData>(
        point: marker.point,
        data: updated,
        properties: updated.toMap(),
      );
    });
  }

  Future<void> _onAddSideItem() async {
    final d = _detailsMarker?.data;
    if (d == null || d.id == null) return;

    final att = await _repo.pickAndUploadSingle(
      baseDir: _attachmentsDir(d),
      onProgress: (_) {},
    );
    if (att == null) return;

    final next = [..._currentAttachments(), att];
    await _persistAttachments(next);
  }

  bool _isPdfAttachment(Attachment a) {
    final ext = (a.ext ?? '').toLowerCase();
    if (ext == 'pdf' || ext == '.pdf') return true;
    final u = (a.url).toLowerCase();
    return u.endsWith('.pdf') || u.contains('.pdf?');
  }

  Future<void> _openAttachmentInline(Attachment att) async {
    if (!_isPdfAttachment(att)) {
      final uri = Uri.tryParse(att.url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final titulo = att.label.isNotEmpty ? att.label : 'Documento PDF';

    await showWindowDialogMac<void>(
      context: context,
      title: titulo,
      width: 1100,
      barrierDismissible: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 900,
          minWidth: 320,
          minHeight: 320,
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Abrir em outra aba',
                onPressed: () {
                  final uri = Uri.tryParse(att.url);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SfPdfViewer.network(
                att.url,
                canShowScrollStatus: true,
                canShowPaginationDialog: true,
                enableDoubleTapZooming: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapSideItem(int index) async {
    final items = _currentAttachments();
    if (index < 0 || index >= items.length) return;
    setState(() => _selectedSideIndex = index);
    await _openAttachmentInline(items[index]);
  }

  Future<void> _onDeleteSideItem(int index) async {
    final items = _currentAttachments();
    if (index < 0 || index >= items.length) return;

    final confirmed = await showWindowDialogMac<bool>(
      context: context,
      title: 'Excluir anexo',
      width: 420,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Deseja realmente excluir este anexo?'),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogCtx).pop(true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed != true) return;

    final path = items[index].path;
    if (path != null && path.isNotEmpty) {
      await _repo.deleteByPath(path);
    }

    final next = [...items]..removeAt(index);
    await _persistAttachments(next);

    setState(() {
      if (_selectedSideIndex != null &&
          _selectedSideIndex! >= next.length) {
        _selectedSideIndex = next.isEmpty ? null : next.length - 1;
      }
    });
  }

  Future<void> _onEditLabelSideItem(int index) async {
    final items = _currentAttachments();
    if (index < 0 || index >= items.length) return;

    final current = items[index];

    final newLabel = await askLabelDialog(
      context,
      current.label.isNotEmpty ? current.label : 'Rótulo do arquivo',
    );

    if (newLabel == null) return;

    final trimmed = newLabel.trim();
    if (trimmed.isEmpty || trimmed == current.label) return;

    final updated = current.copyWith(
      label: trimmed,
      updatedAt: DateTime.now(),
    );

    final next = [...items]..[index] = updated;
    await _persistAttachments(next);
  }

  // =============================================================================
  // BUILD
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: UpBar(
          showPhotoMenu: true,
          actions: [
            IconButton(
              tooltip: 'Limpar filtros',
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              onPressed: _clearFilters,
            ),
            IconButton(
              tooltip: _showPanel ? 'Ocultar painel' : 'Mostrar painel',
              icon: Icon(
                _showPanel
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
                color: Colors.white,
              ),
              onPressed: _togglePanelVisibility,
            ),
          ],
        ),
      ),
      body: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
        // 🔥 Rebuilda mapa + painel apenas quando dados/filtros realmente mudam
        buildWhen: (prev, curr) {
          return prev.all != curr.all ||
              prev.selectedPieIndexFilter !=
                  curr.selectedPieIndexFilter ||
              prev.selectedRegionFilter !=
                  curr.selectedRegionFilter ||
              prev.regionLabels != curr.regionLabels;
        },
        builder: (context, state) {
          Widget? rightPane;
          switch (_mode) {
            case _RightPanelMode.none:
              rightPane = null;
              break;
            case _RightPanelMode.analytics:
              rightPane = ActiveOaesPanel(onClose: _closePanel);
              break;
            case _RightPanelMode.details:
              final marker = _detailsMarker;
              if (marker != null) {
                final sideItems =
                    marker.data.attachments ?? const <Attachment>[];
                rightPane = ActiveOaesDetails(
                  key: ValueKey(marker.data.id),
                  marker: marker,
                  onClose: _closePanel,
                  sideItems: sideItems,
                  selectedSideIndex: _selectedSideIndex,
                  onAddSideItem: _onAddSideItem,
                  onTapSideItem: _onTapSideItem,
                  onDeleteSideItem: _onDeleteSideItem,
                  onEditLabelSideItem: _onEditLabelSideItem,
                  isEditable: true,
                );
              } else {
                rightPane = ActiveOaesPanel(onClose: _closePanel);
              }
              break;
          }

          return SplitLayout(
            left: ActiveOaesMapMapbox(
              state: state,
              onOpenDetails: _openDetails,
            ),
            right: rightPane ?? const SizedBox.shrink(),
            showRightPanel: _showPanel && rightPane != null,
            breakpoint: 980.0,
            rightPanelWidth: 580.0,
            bottomPanelHeight: 420.0,
            showDividers: true,
          );
        },
      ),
    );
  }
}
