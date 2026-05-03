// lib/screens/modules/actives/oaes/active_oaes_network_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_repository.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/actives/oaes/network/active_oaes_details.dart';
import 'package:sipged/screens/modules/actives/oaes/network/active_oaes_panel.dart';
import 'package:sipged/screens/modules/actives/oaes/network/maps/active_oaes_map_mapbox.dart';

enum _RightPanelMode {
  none,
  analytics,
  details,
}

class ActiveOAEsNetworkPage extends StatefulWidget {
  const ActiveOAEsNetworkPage({super.key});

  @override
  State<ActiveOAEsNetworkPage> createState() => _ActiveOAEsNetworkPageState();
}

class _ActiveOAEsNetworkPageState extends State<ActiveOAEsNetworkPage> {
  // ---------------------------------------------------------------------------
  // TESTE MANUAL MULTI-TENANT
  //
  // Enquanto o tenant ainda não vem do usuário logado / empresa selecionada,
  // defina manualmente aqui.
  //
  // Quando for integrar oficialmente, substitua por:
  // final tenantId = context.read<TenantCubit>().state.currentTenantId;
  // ou equivalente.
  // ---------------------------------------------------------------------------

  static const String _manualTenantId = 'SZQmefRUqdtLB14ahcuh';

  late final ActiveOaesRepository _repo = ActiveOaesRepository(
    tenantId: _manualTenantId,
  );

  _RightPanelMode _mode = _RightPanelMode.analytics;
  bool _showPanel = true;

  ActiveOaesData? _detailsData;
  int? _selectedSideIndex;

  // ---------------------------------------------------------------------------
  // Actions gerais
  // ---------------------------------------------------------------------------

  void _clearFilters() {
    final cubit = context.read<ActiveOaesCubit>();
    cubit.setPieFilter(null);
    cubit.setRegionFilter(null);
  }

  void _togglePanelVisibility() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  void _openDetails(ActiveOaesData data) {
    setState(() {
      _mode = _RightPanelMode.details;
      _detailsData = data;
      _selectedSideIndex = null;
      _showPanel = true;
    });
  }

  void _closePanel() {
    setState(() {
      _showPanel = false;
      _mode = _RightPanelMode.analytics;
      _detailsData = null;
      _selectedSideIndex = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------

  String _attachmentsDir(ActiveOaesData d) {
    final id = d.id;

    if (id == null || id.trim().isEmpty) {
      return '${_repo.storageBasePath}/sem_id/attachments';
    }

    return '${_repo.storageBasePath}/${id.trim()}/attachments';
  }

  List<Attachment> _currentAttachments() {
    return _detailsData?.attachments ?? const <Attachment>[];
  }

  Future<void> _persistAttachments(List<Attachment> next) async {
    final d = _detailsData;

    if (d == null || d.id == null || d.id!.trim().isEmpty) {
      return;
    }

    final updated = d.copyWith(
      attachments: next,
    );

    final saved = await _repo.upsert(updated);

    if (!mounted) return;

    setState(() {
      _detailsData = saved;
    });
  }

  Future<void> _onAddSideItem() async {
    final d = _detailsData;

    if (d == null || d.id == null || d.id!.trim().isEmpty) {
      return;
    }

    final att = await _repo.pickAndUploadSingle(
      baseDir: _attachmentsDir(d),
      onProgress: (_) {},
    );

    if (att == null) return;

    final next = <Attachment>[
      ..._currentAttachments(),
      att,
    ];

    await _persistAttachments(next);
  }

  bool _isPdfAttachment(Attachment a) {
    final ext = a.ext.toLowerCase().trim();

    if (ext == 'pdf' || ext == '.pdf') return true;

    final url = a.url.toLowerCase();

    return url.endsWith('.pdf') || url.contains('.pdf?');
  }

  Future<void> _openAttachmentInline(Attachment att) async {
    if (!_isPdfAttachment(att)) {
      final uri = Uri.tryParse(att.url);

      if (uri != null) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      return;
    }

    final titulo = att.label.isNotEmpty ? att.label : 'Documento PDF';

    await showWindowDialog<void>(
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
                    launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
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

    setState(() {
      _selectedSideIndex = index;
    });

    await _openAttachmentInline(items[index]);
  }

  Future<void> _onDeleteSideItem(int index) async {
    final items = _currentAttachments();

    if (index < 0 || index >= items.length) return;

    final confirmed = await showWindowDialog<bool>(
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
                      onPressed: () {
                        Navigator.of(dialogCtx).pop(false);
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop(true);
                      },
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

    if (path.isNotEmpty) {
      await _repo.deleteByPath(path);
    }

    final next = <Attachment>[
      ...items,
    ]..removeAt(index);

    await _persistAttachments(next);

    if (!mounted) return;

    setState(() {
      if (_selectedSideIndex != null && _selectedSideIndex! >= next.length) {
        _selectedSideIndex = next.isEmpty ? null : next.length - 1;
      }
    });
  }

  Future<bool> _onRenamePersist({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final items = _currentAttachments();

    if (index < 0 || index >= items.length) {
      return false;
    }

    try {
      final next = <Attachment>[
        ...items,
      ];

      next[index] = newItem.copyWith(
        updatedAt: DateTime.now(),
      );

      await _persistAttachments(next);

      return true;
    } catch (_) {
      return false;
    }
  }

  void _onItemsChanged(List<dynamic> newItems) {
    final d = _detailsData;

    if (d == null) return;

    final next = newItems.whereType<Attachment>().toList();

    setState(() {
      _detailsData = d.copyWith(
        attachments: next,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Right pane separado para não forçar rebuild do mapa
  // ---------------------------------------------------------------------------

  Widget? _buildRightPane() {
    switch (_mode) {
      case _RightPanelMode.none:
        return null;

      case _RightPanelMode.analytics:
        return ActiveOaesPanel(
          onClose: _closePanel,
        );

      case _RightPanelMode.details:
        final data = _detailsData;

        if (data == null) {
          return ActiveOaesPanel(
            onClose: _closePanel,
          );
        }

        final sideItems = data.attachments ?? const <Attachment>[];

        return ActiveOaesDetails(
          key: ValueKey<String>('details_${data.id ?? 'sem_id'}'),
          data: data,
          repository: _repo,
          onClose: _closePanel,
          sideItems: sideItems,
          selectedSideIndex: _selectedSideIndex,
          onAddSideItem: _onAddSideItem,
          onTapSideItem: _onTapSideItem,
          onDeleteSideItem: _onDeleteSideItem,
          onRenamePersist: _onRenamePersist,
          onItemsChanged: _onItemsChanged,
          isEditable: true,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rightPane = _buildRightPane();

    return Scaffold(
      appBar: UpBar(
        showPhotoMenu: true,
        actions: [
          IconButton(
            tooltip: 'Limpar filtros',
            icon: const Icon(
              Icons.filter_alt_off,
              color: Colors.white,
            ),
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
      body: SplitLayout(
        left: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
          buildWhen: (prev, curr) {
            return prev.loadStatus != curr.loadStatus ||
                prev.initialized != curr.initialized ||
                prev.all != curr.all ||
                prev.selectedPieIndexFilter != curr.selectedPieIndexFilter ||
                prev.selectedRegionFilter != curr.selectedRegionFilter;
          },
          builder: (context, state) {
            return ActiveOaesMapMapbox(
              state: state,
              onOpenDetails: _openDetails,
            );
          },
        ),
        right: rightPane ?? const SizedBox.shrink(),
        showRightPanel: _showPanel && rightPane != null,
        breakpoint: 980.0,
        rightPanelWidth: 580.0,
        bottomPanelHeight: 420.0,
        showDividers: true,
      ),
    );
  }
}