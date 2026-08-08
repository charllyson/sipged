// lib/screens/modules/actives/oaes/active_oaes_network_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_repository.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
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
  late final ActiveOaesCubit _cubit;

  String? _lastTenantId;

  _RightPanelMode _mode = _RightPanelMode.analytics;
  bool _showPanel = true;

  ActiveOaesData? _detailsData;
  int? _selectedSideIndex;

  ActiveOaesRepository get _repo => _cubit.repository;

  @override
  void initState() {
    super.initState();

    _cubit = ActiveOaesCubit(
      repository: ActiveOaesRepository(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tenantState = context.read<TenantCubit>().state;
    final permissionState = context.read<PermissionCubit>().state;

    final tenantId = _tenantIdFromTenantState(tenantState);

    _syncTenantPermissionAndWarmup(
      tenantId: tenantId,
      permissionState: permissionState,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String? _cleanId(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;

    return text;
  }

  String? _idFromObject(dynamic object) {
    if (object == null) return null;

    try {
      final clean = _cleanId(object.id);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(object.uid);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  String? _tenantIdFromTenantState(TenantState state) {
    final dynamic s = state;

    try {
      final clean = _cleanId(s.activeTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.currentTenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.tenantId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _cleanId(s.companyId);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.current);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.tenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.currentTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.activeTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedTenant);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.company);
      if (clean != null) return clean;
    } catch (_) {}

    try {
      final clean = _idFromObject(s.selectedCompany);
      if (clean != null) return clean;
    } catch (_) {}

    return null;
  }

  void _syncTenantPermissionAndWarmup({
    required String? tenantId,
    required PermissionState permissionState,
  }) {
    final cleanTenantId = tenantId?.trim();

    final tenantChanged = _lastTenantId != cleanTenantId;

    if (tenantChanged) {
      _lastTenantId = cleanTenantId;

      _detailsData = null;
      _selectedSideIndex = null;
      _mode = _RightPanelMode.analytics;

      _cubit.updatePermissions(
        permissions: permissionState.current,
        tenantId: cleanTenantId,
      );

      if (cleanTenantId == null || cleanTenantId.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cubit.warmup();
      });

      return;
    }

    _cubit.updatePermissions(
      permissions: permissionState.current,
      tenantId: cleanTenantId,
    );
  }

  void _togglePanelVisibility() {
    setState(() {
      _showPanel = !_showPanel;
    });
  }

  Widget _buildPanelToggleButton() {
    final active = _showPanel;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: active ? 1.0 : 0.58,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ]
              : const [],
        ),
        child: CircleButtonChange(
          tooltip: active ? 'Ocultar painel' : 'Mostrar painel',
          icon: active
              ? Icons.view_sidebar_rounded
              : Icons.view_sidebar_outlined,
          onPressed: _togglePanelVisibility,
        ),
      ),
    );
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

  String _attachmentsDir(ActiveOaesData data) {
    final id = data.id?.trim();

    if (id == null || id.isEmpty) {
      return '${_repo.storageBasePath}/sem_id/attachments';
    }

    return '${_repo.storageBasePath}/$id/attachments';
  }

  List<Attachment> _currentAttachments() {
    return _detailsData?.attachments ?? const <Attachment>[];
  }

  Future<void> _persistAttachments(List<Attachment> next) async {
    final data = _detailsData;

    if (data == null || data.id == null || data.id!.trim().isEmpty) return;

    final updated = data.copyWith(
      attachments: next,
    );

    final saved = await _cubit.upsert(updated);

    if (!mounted || saved == null) return;

    setState(() {
      _detailsData = saved;
    });
  }

  Future<void> _onAddSideItem() async {
    final data = _detailsData;

    if (data == null || data.id == null || data.id!.trim().isEmpty) return;

    final att = await _repo.pickAndUploadSingle(
      baseDir: _attachmentsDir(data),
      onProgress: (_) {},
    );

    if (!mounted || att == null) return;

    final next = <Attachment>[
      ..._currentAttachments(),
      att,
    ];

    await _persistAttachments(next);
  }

  bool _isPdfAttachment(Attachment attachment) {
    final ext = attachment.ext.toLowerCase().trim();

    if (ext == 'pdf' || ext == '.pdf') return true;

    final url = attachment.url.toLowerCase();

    return url.endsWith('.pdf') || url.contains('.pdf?');
  }

  Future<void> _openAttachmentInline(Attachment attachment) async {
    if (!_isPdfAttachment(attachment)) {
      final uri = Uri.tryParse(attachment.url);

      if (uri != null) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      return;
    }

    if (!mounted) return;

    final titulo = attachment.label.isNotEmpty
        ? attachment.label
        : 'Documento PDF';

    await showWindowDialog<void>(
      context: context,
      title: titulo,
      width: 1100,
      barrierDismissible: true,
      useSafeArea: true,
      dialogWrapper: (dialog) {
        return PointerInterceptor(
          child: dialog,
        );
      },
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
                  final uri = Uri.tryParse(attachment.url);

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
                attachment.url,
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
        builder: (dialogContext) {
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
                        Navigator.of(dialogContext).pop(false);
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
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

    if (!mounted || confirmed != true) return;

    final path = items[index].path;

    if (path.isNotEmpty) {
      await _repo.deleteByPath(path);
    }

    if (!mounted) return;

    final next = <Attachment>[...items]..removeAt(index);

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

    if (index < 0 || index >= items.length) return false;

    try {
      final next = <Attachment>[...items];

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
    final data = _detailsData;

    if (data == null) return;

    final next = newItems.whereType<Attachment>().toList();

    setState(() {
      _detailsData = data.copyWith(
        attachments: next,
      );
    });
  }

  Widget? _buildRightPane(BuildContext context) {
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
          isEditable: context.watch<ActiveOaesCubit>().isEditable,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActiveOaesCubit>.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<TenantCubit, TenantState>(
            listener: (context, tenantState) {
              final permissionState = context.read<PermissionCubit>().state;
              final tenantId = _tenantIdFromTenantState(tenantState);

              _syncTenantPermissionAndWarmup(
                tenantId: tenantId,
                permissionState: permissionState,
              );
            },
          ),
          BlocListener<PermissionCubit, PermissionState>(
            listenWhen: (previous, current) {
              return previous.current != current.current ||
                  previous.activeTenantId != current.activeTenantId;
            },
            listener: (context, permissionState) {
              final tenantState = context.read<TenantCubit>().state;
              final tenantIdFromTenantState =
              _tenantIdFromTenantState(tenantState);

              final tenantId =
                  tenantIdFromTenantState ?? _cleanId(permissionState.activeTenantId);

              _syncTenantPermissionAndWarmup(
                tenantId: tenantId,
                permissionState: permissionState,
              );
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            final tenantState = context.watch<TenantCubit>().state;
            final permissionState = context.watch<PermissionCubit>().state;

            final tenantIdFromTenantState =
            _tenantIdFromTenantState(tenantState);

            final tenantId =
                tenantIdFromTenantState ?? _cleanId(permissionState.activeTenantId);

            if (tenantId == null || tenantId.isEmpty) {
              return Scaffold(
                appBar: const UpBar(showPhotoMenu: true),
                body: const Center(
                  child: Text(
                    'Selecione uma empresa para visualizar as OAEs.',
                  ),
                ),
              );
            }

            final rightPane = _buildRightPane(context);

            return Scaffold(
              appBar: UpBar(
                showPhotoMenu: true,
                actions: [
                  _buildPanelToggleButton(),
                ],
              ),
              body: BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
                buildWhen: (previous, current) {
                  return previous.loadStatus != current.loadStatus ||
                      previous.initialized != current.initialized ||
                      previous.all != current.all ||
                      previous.regionLabels != current.regionLabels ||
                      previous.selectedPieIndexFilter !=
                          current.selectedPieIndexFilter ||
                      previous.selectedRegionFilter !=
                          current.selectedRegionFilter ||
                      previous.isEditable != current.isEditable;
                },
                builder: (context, state) {
                  if (state.loadStatus == ActiveOaesLoadStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.error ?? 'Erro ao carregar OAEs.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
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
          },
        ),
      ),
    );
  }
}