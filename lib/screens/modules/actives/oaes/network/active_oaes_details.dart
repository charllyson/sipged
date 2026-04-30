// lib/screens/modules/actives/oaes/network/active_oaes_details.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_repository.dart';
import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/DataTime/selector/selector_dates.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/photo_gallery_dialog.dart';
import 'package:sipged/_widgets/images/carousel/photo_item.dart';
import 'package:sipged/_widgets/images/carousel/photo_picker_square.dart';
import 'package:sipged/_widgets/images/carousel/photo_thumb.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/screens/modules/actives/oaes/card_3d.dart';
import 'package:sipged/screens/modules/actives/oaes/network/details_panel_body.dart';
import 'package:sipged/screens/modules/actives/oaes/network/panel_header.dart';

class ActiveOaesDetails extends StatefulWidget {
  const ActiveOaesDetails({
    super.key,
    required this.data,
    this.onClose,
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onRenamePersist,
    this.onItemsChanged,
    this.sideLoading = false,
    this.sideUploadProgress,
    this.isEditable = true,
    this.titleSideList = 'Projetos e Documentos',
  });

  final ActiveOaesData data;
  final VoidCallback? onClose;

  final List<dynamic> sideItems;
  final int? selectedSideIndex;

  final FutureOr<void> Function()? onAddSideItem;
  final FutureOr<void> Function(int index)? onTapSideItem;
  final FutureOr<void> Function(int index)? onDeleteSideItem;

  final Future<bool> Function({
  required int index,
  required Attachment oldItem,
  required Attachment newItem,
  })? onRenamePersist;

  final void Function(List<dynamic> newItems)? onItemsChanged;

  final bool sideLoading;
  final double? sideUploadProgress;

  final bool isEditable;
  final String titleSideList;

  @override
  State<ActiveOaesDetails> createState() => _ActiveOaesDetailsState();
}

class _ActiveOaesDetailsState extends State<ActiveOaesDetails> {
  final _repo = ActiveOaesRepository();

  List<Attachment> _allPhotos = const [];
  List<Attachment> _filtered = const [];

  int? _selectedYear;
  int? _selectedMonth;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPhotos();
  }

  @override
  void didUpdateWidget(covariant ActiveOaesDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.data.id;
    final newId = widget.data.id;

    if (oldId != newId) {
      _selectedYear = null;
      _selectedMonth = null;
      _allPhotos = const [];
      _filtered = const [];
      _loadInitialPhotos();

      if (mounted) setState(() {});
    } else {
      _applyCurrentFilter();
    }
  }

  void _notifySuccess(String message) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: 'Sucesso',
        subtitle: message,
        type: NotificationType.success,
        leadingLabel: 'OAE',
      ),
    );
  }

  void _notifyError(String message) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: 'Erro',
        subtitle: message,
        type: NotificationType.error,
        leadingLabel: 'OAE',
      ),
    );
  }

  Future<T> _withBusy<T>(Future<T> Function() task) async {
    if (mounted) setState(() => _busy = true);

    try {
      return await task();
    } catch (_) {
      _notifyError('Falha ao processar a operação.');
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wrapBusy(FutureOr<void> Function()? fn) async {
    if (fn == null) return;

    try {
      await _withBusy(() async => Future.sync(fn));
    } catch (_) {}
  }

  Future<void> _wrapBusyIndex(
      FutureOr<void> Function(int index)? fn,
      int index,
      ) async {
    if (fn == null) return;

    try {
      await _withBusy(() async => Future.sync(() => fn(index)));
    } catch (_) {}
  }

  Future<void> _loadInitialPhotos() async {
    try {
      final id = widget.data.id;

      if (id == null) {
        _allPhotos = const [];
        _filtered = const [];

        if (mounted) setState(() {});
        return;
      }

      final list = await _repo.loadPhotos(id);

      _allPhotos = list;
      _filtered = List<Attachment>.from(_allPhotos);

      _applyCurrentFilter();
    } catch (_) {
      _allPhotos = const [];
      _filtered = const [];

      if (mounted) setState(() {});
    }
  }

  Future<void> _persistPhotos() async {
    final id = widget.data.id;

    if (id == null) return;

    await _repo.savePhotos(id, _allPhotos);
  }

  Future<void> _addPhotoFromBytes(Uint8List bytes) async {
    await _withBusy(() async {
      final d = widget.data;

      if (d.id == null) return;

      final att = await _repo.uploadPhotoBytes(
        oaeId: d.id!,
        bytes: bytes,
        originalName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (_) {},
        forcedLabel: 'Foto ${DateTime.now().toIso8601String()}',
      );

      _allPhotos = [..._allPhotos, att];

      _applyCurrentFilter();

      await _persistPhotos();

      _notifySuccess('Foto adicionada com sucesso.');
    });
  }

  Future<void> _handleDelete(Attachment att) async {
    await _withBusy(() async {
      final path = att.path;

      if (path.isNotEmpty) {
        await _repo.deleteByPath(path);
      }

      _allPhotos = List<Attachment>.from(_allPhotos)
        ..removeWhere((e) => e.path == att.path);

      _applyCurrentFilter();

      await _persistPhotos();

      _notifySuccess('Foto removida.');
    });
  }

  void _applyCurrentFilter() {
    if (_selectedYear == null && _selectedMonth == null) {
      _filtered = List<Attachment>.from(_allPhotos)
        ..sort((a, b) {
          final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });

      if (mounted) setState(() {});
      return;
    }

    _filtered = _allPhotos.where((a) {
      final dt = a.createdAt;

      if (dt == null) return false;

      final okYear = (_selectedYear == null) || dt.year == _selectedYear;
      final okMonth = (_selectedMonth == null) || dt.month == _selectedMonth;

      return okYear && okMonth;
    }).toList()
      ..sort((a, b) {
        final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

    if (mounted) setState(() {});
  }

  String _coordText(ActiveOaesData d) {
    final lat = d.latitude;
    final lon = d.longitude;

    if (lat == null || lon == null) return '-';

    return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }

  List<MapEntry<String, String>> _buildEntries(ActiveOaesData d) {
    final baseKeys = <String>{
      'id',
      'order',
      'score',
      'state',
      'road',
      'region',
      'identificationName',
      'latitude',
      'longitude',
      'altitude',
      'attachments',
    };

    final extraEntries = d.toMap().entries.where((e) {
      if (baseKeys.contains(e.key)) return false;
      if (e.value == null) return false;

      final value = e.value.toString().trim();
      if (value.isEmpty || value == '[]') return false;

      return true;
    }).map(
          (e) => MapEntry(e.key, e.value.toString()),
    );

    return <MapEntry<String, String>>[
      MapEntry('Identificação', d.identificationName ?? '-'),
      MapEntry('UF', d.state ?? '-'),
      MapEntry('Município', d.region ?? '-'),
      MapEntry('Rodovia', d.road ?? '-'),
      MapEntry('Nota', d.score != null ? d.score!.toStringAsFixed(1) : '-'),
      MapEntry('Ordem', d.order?.toString() ?? '-'),
      MapEntry('Coordenadas', _coordText(d)),
      ...extraEntries,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final entries = _buildEntries(d);
    final carouselTheme = const CarouselPhotoTheme();

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundChange(),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 860;
              final double sideWidth = isSmall ? constraints.maxWidth : 300.0;

              final side = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  width: sideWidth,
                  child: SideListBox(
                    title: widget.titleSideList,
                    items: widget.sideItems,
                    selectedIndex: widget.selectedSideIndex,
                    openOnTap: false,
                    onAddPressed: widget.isEditable && !_busy
                        ? () => _wrapBusy(widget.onAddSideItem)
                        : null,
                    onTap: !_busy
                        ? (i) => _wrapBusyIndex(widget.onTapSideItem, i)
                        : null,
                    onDelete: widget.isEditable && !_busy
                        ? (i) => _wrapBusyIndex(widget.onDeleteSideItem, i)
                        : null,
                    enableRename: widget.isEditable,
                    onRenamePersist: widget.onRenamePersist,
                    onItemsChanged: widget.onItemsChanged,
                    loading: widget.sideLoading,
                    uploadProgress: widget.sideUploadProgress,
                    width: sideWidth,
                  ),
                ),
              );

              final details = DetailsPanelBody(entries: entries);

              final header = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: PanelHeader(
                  title: d.identificationName ?? 'Detalhes da OAE',
                  onClose: _busy ? null : widget.onClose,
                ),
              );

              final double photosHeight = carouselTheme.itemSize;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: photosHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: (_filtered.isEmpty ? 0 : _filtered.length) +
                            (widget.isEditable ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final bool hasAdder = widget.isEditable;
                          final int offset = hasAdder ? 1 : 0;

                          if (hasAdder && index == 0) {
                            return PhotoPickerSquare(
                              enabled: !_busy,
                              onPickFromCamera: _addPhotoFromBytes,
                              onPickFromGallery: _addPhotoFromBytes,
                              editorMaxScale: 5.0,
                              editorExportQuality: 100,
                              editorCircleCrop: false,
                              editorAspectRatios: const [1, 4 / 3, 16 / 9],
                            );
                          }

                          final att = _filtered[index - offset];
                          final item = att.toPhotoItem();

                          return PhotoThumb(
                            item: item,
                            theme: carouselTheme,
                            onTap: () async {
                              final items = _filtered
                                  .map((a) => a.toPhotoItem())
                                  .toList();

                              if (items.isEmpty) return;

                              final start =
                              (index - offset).clamp(0, items.length - 1);

                              await showPhotoGalleryDialog(
                                context,
                                items: items,
                                initialIndex: start,
                              );
                            },
                            onRemove: widget.isEditable && !_busy
                                ? () => _handleDelete(att)
                                : null,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: AbsorbPointer(
                        absorbing: _busy,
                        child: Opacity(
                          opacity: _busy ? 0.6 : 1,
                          child: SelectorDates<Attachment>(
                            items: _allPhotos,
                            getDate: (att) => att.createdAt,
                            getLabel: (att) => att.label,
                            sortByDate: true,
                            sortDescending: true,
                            onFilterChanged: (filtered) {
                              _filtered = filtered;

                              if (mounted) setState(() {});
                            },
                            onSelectionChanged: ({
                              required filteredItems,
                              int? selectedYear,
                              int? selectedMonth,
                              int? selectedDay,
                            }) {
                              _selectedYear = selectedYear;
                              _selectedMonth = selectedMonth;
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SectionTitle(text: 'Modelo 3D'),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: OaeModel3DCard(
                        data: d,
                        isEditable: widget.isEditable,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const SectionTitle(text: 'Projetos e Documentos da OAE'),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: isSmall
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          side,
                          const SectionTitle(
                            text: 'Informações gerais da OAE',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: details,
                          ),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          side,
                          Flexible(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                const SectionTitle(
                                  text: 'Informações gerais da OAE',
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 12.0,
                                  ),
                                  child: details,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_busy) ...[
            Positioned.fill(
              child: ModalBarrier(
                color: Colors.black.withValues(alpha: 0.20),
                dismissible: false,
              ),
            ),
            const _PositionedFillBusy(),
          ],
        ],
      ),
    );
  }
}

class _PositionedFillBusy extends StatelessWidget {
  const _PositionedFillBusy();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Card(
            elevation: 6,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(width: 4),
                  LoadingTreeDots(size: 36, centered: false),
                  SizedBox(width: 12),
                  Text(
                    'Processando...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _AttachmentToPhoto on Attachment {
  PhotoItem toPhotoItem() {
    final meta = pm.CarouselMetadata(
      url: url,
      name: label,
      takenAt: createdAt,
      uploadedAtMs: createdAt?.millisecondsSinceEpoch,
      uploadedBy: updatedBy,
    );

    return PhotoUrlItem(
      url,
      meta: meta,
    );
  }
}