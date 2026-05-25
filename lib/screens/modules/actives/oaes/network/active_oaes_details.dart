// lib/screens/modules/actives/oaes/network/active_oaes_details.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_repository.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/DataTime/selector/selector_dates.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_thumb.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/photo_gallery_dialog.dart';
import 'package:sipged/_widgets/images/carousel/photo_picker_square.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/screens/modules/actives/oaes/card_3d.dart';
import 'package:sipged/screens/modules/actives/oaes/network/details_panel_body.dart';
import 'package:sipged/screens/modules/actives/oaes/network/panel_header.dart';

class ActiveOaesDetails extends StatefulWidget {
  const ActiveOaesDetails({
    super.key,
    required this.data,
    required this.repository,
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
  final ActiveOaesRepository repository;

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
  ActiveOaesRepository get _repo => widget.repository;

  List<Attachment> _allPhotos = const <Attachment>[];
  List<Attachment> _filtered = const <Attachment>[];

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
      _allPhotos = const <Attachment>[];
      _filtered = const <Attachment>[];
      _loadInitialPhotos();

      if (mounted) setState(() {});
    } else {
      _applyCurrentFilter();
    }
  }

  void _notifySuccess(String message) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Sucesso',
        subtitle: message,
        type: NotificationStatus.success,
        leadingLabel: 'OAE',
      ),
    );
  }

  void _notifyError(String message) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Erro',
        subtitle: message,
        type: NotificationStatus.error,
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
        _allPhotos = const <Attachment>[];
        _filtered = const <Attachment>[];

        if (mounted) setState(() {});
        return;
      }

      final list = await _repo.loadPhotos(id);

      _allPhotos = list;
      _filtered = List<Attachment>.from(_allPhotos);

      _applyCurrentFilter();
    } catch (_) {
      _allPhotos = const <Attachment>[];
      _filtered = const <Attachment>[];

      if (mounted) setState(() {});
    }
  }

  Future<void> _persistPhotos() async {
    final id = widget.data.id;

    if (id == null) return;

    await _repo.savePhotos(id, _allPhotos);
  }

  Future<void> _addPhotoFromPhoto(PhotoData photo) async {
    await _withBusy(() async {
      final d = widget.data;

      if (d.id == null) return;

      final bytes = photo.bytes;

      if (bytes == null || bytes.isEmpty) {
        _notifyError('A foto selecionada não possui bytes para envio.');
        return;
      }

      final photoName = photo.name.trim().isNotEmpty
          ? photo.name.trim()
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final createdAt = photo.takenAt ?? DateTime.now();

      final att = await _repo.uploadPhotoBytes(
        oaeId: d.id!,
        bytes: bytes,
        originalName: photoName,
        onProgress: (_) {},
        forcedLabel: photoName,
      );

      final normalized = att.copyWith(
        label: att.label.trim().isNotEmpty ? att.label : photoName,
        createdAt: att.createdAt ?? createdAt,
        updatedBy: att.updatedBy ?? photo.uploadedBy,
      );

      _allPhotos = <Attachment>[
        ..._allPhotos,
        normalized,
      ];

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
      'tenantId',
      'createdAt',
      'createdBy',
      'updatedAt',
      'updatedBy',
      'migrationSourcePath',
      'migrationSourceDocId',
      'migratedAt',
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
                  child: BoxListFiles(
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
                              onPickFromCamera: _addPhotoFromPhoto,
                              onPickFromGallery: _addPhotoFromPhoto,
                              editorMaxScale: 5.0,
                              editorExportQuality: 100,
                              editorCircleCrop: false,
                              editorAspectRatios: const [1, 4 / 3, 16 / 9],
                            );
                          }

                          final att = _filtered[index - offset];
                          final photo = att.toPhotoData();

                          return CarouselPhotoThumb(
                            photo: photo,
                            theme: carouselTheme,
                            onTap: () async {
                              final photos = _filtered
                                  .map((a) => a.toPhotoData())
                                  .toList(growable: false);

                              if (photos.isEmpty) return;

                              final start =
                              (index - offset).clamp(0, photos.length - 1);

                              await showPhotoGalleryDialog(
                                context,
                                photos: photos,
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

extension _AttachmentToPhotoData on Attachment {
  PhotoData toPhotoData() {
    final cleanUrl = url.trim();

    return PhotoData.fromUrl(
      id: path.trim().isNotEmpty ? path.trim() : cleanUrl,
      name: label.trim().isNotEmpty ? label.trim() : _nameFromUrl(cleanUrl),
      url: cleanUrl,
      takenAt: createdAt,
      uploadedAtMs: createdAt?.millisecondsSinceEpoch,
      uploadedBy: updatedBy,
    );
  }

  static String _nameFromUrl(String url) {
    final clean = url.split('?').first.trim();

    if (clean.isEmpty) {
      return 'foto.jpg';
    }

    final parts = clean.split('/');

    if (parts.isEmpty || parts.last.trim().isEmpty) {
      return 'foto.jpg';
    }

    return parts.last.trim();
  }
}