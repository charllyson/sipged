// lib/screens/sectors/actives/oaes/active_oaes_network_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import 'active_oaes_map.dart';
import 'active_oaes_panel.dart';
import 'active_oaes_details.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_repository.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_blocs/actives/oaes/storage_only_bloc.dart';

enum _RightPanelMode { none, analytics, details }

class ActiveOAEsNetworkPage extends StatefulWidget {
  const ActiveOAEsNetworkPage({super.key});

  @override
  State<ActiveOAEsNetworkPage> createState() => _ActiveOAEsNetworkPageState();
}

class _ActiveOAEsNetworkPageState extends State<ActiveOAEsNetworkPage> {
  late final ActiveOaesBloc _bloc;
  final _repo = ActiveOaesRepository();

  _RightPanelMode _mode = _RightPanelMode.analytics;
  bool _showPanel = true;

  TaggedChangedMarker<ActiveOaesData>? _detailsMarker;
  int? _selectedSideIndex;

  // ✅ StorageOnlyBloc (uploader genérico)
  final StorageOnlyBloc _storageOnly = StorageOnlyBloc();

  @override
  void initState() {
    super.initState();
    _bloc = ActiveOaesBloc()..add(const ActiveOaesWarmupRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    _storageOnly.dispose();
    super.dispose();
  }

  // ======== FILTROS E PAINEL ========

  void _clearFilters() {
    _bloc.add(const ActiveOaesPieFilterChanged(null));
    _bloc.add(const ActiveOaesRegionFilterChanged(null));
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

  void _openAnalytics() {
    setState(() {
      _mode = _RightPanelMode.analytics;
      _showPanel = true;
      _detailsMarker = null;
      _selectedSideIndex = null;
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

  String _attachmentsDir(ActiveOaesData d) => 'actives_oaes/${d.id}/attachments';
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

    final att = await _storageOnly.pickAndUploadSingle(
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
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
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
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          att.label.isNotEmpty ? att.label : 'Documento PDF',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Abrir em outra aba',
                        onPressed: () {
                          final uri = Uri.tryParse(att.url);
                          if (uri != null) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
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
      },
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir anexo'),
        content: Text('Deseja remover "${items[index].label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirm != true) return;

    final path = items[index].path;
    if (path.isNotEmpty) await _storageOnly.deleteByPath(path);

    final next = [...items]..removeAt(index);
    await _persistAttachments(next);

    setState(() {
      if (_selectedSideIndex != null && _selectedSideIndex! >= next.length) {
        _selectedSideIndex = next.isEmpty ? null : next.length - 1;
      }
    });
  }

  Future<void> _onEditLabelSideItem(int index) async {
    final items = _currentAttachments();
    if (index < 0 || index >= items.length) return;

    final current = items[index];
    final ctrl = TextEditingController(text: current.label);
    final newLabel = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar rótulo'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Rótulo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (newLabel == null) return;

    final updated = current.copyWith(
      label: newLabel.isEmpty ? current.label : newLabel,
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
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
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
                  _showPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _togglePanelVisibility,
              ),
            ],
          ),
        ),

        body: BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
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
                  final sideItems = marker.data.attachments ?? const <Attachment>[];
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

            return ResponsiveSplitView(
              left: ActiveOaesMap(
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
      ),
    );
  }
}
