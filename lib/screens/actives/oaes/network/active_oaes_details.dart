// lib/screens/sectors/actives/oaes/active_oaes_details.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/actives/oaes/storage_only_bloc.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

// 🔎 filtro por ano/mês
import 'package:siged/_widgets/dates/selector/selectorDates.dart';

// 📷 componentes de fotos
import 'package:siged/_widgets/images/carousel/photo_item.dart';
import 'package:siged/_widgets/images/carousel/photo_gallery_dialog.dart';
import 'package:siged/_widgets/images/carousel/photo_thumb.dart';
import 'package:siged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

// ⬇️ Botão quadrado de câmera/galeria + preview
import 'package:siged/_widgets/images/carousel/photo_picker_square.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/screens/actives/oaes/network/details_panel_body.dart';
import 'package:siged/screens/actives/oaes/network/panel_header.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';

class ActiveOaesDetails extends StatefulWidget {
  const ActiveOaesDetails({
    super.key,
    required this.marker,
    this.onClose,

    // ▶️ SideListBox (compatível com String | Attachment)
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
    this.isEditable = true,
    this.titleSideList = 'Projetos e Documentos',
  });

  final TaggedChangedMarker<ActiveOaesData> marker;
  final VoidCallback? onClose;

  // ---- SideListBox props ----
  final List<dynamic> sideItems; // Aceita List<Attachment> OU List<String>
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;
  final bool isEditable;
  final String titleSideList;

  @override
  State<ActiveOaesDetails> createState() => _ActiveOaesDetailsState();
}

class _ActiveOaesDetailsState extends State<ActiveOaesDetails> {
  final _photosCtrl = StreamController<List<Attachment>>.broadcast();
  final _storage = StorageOnlyBloc();
  final _db = FirebaseFirestore.instance;

  List<Attachment> _allPhotos = const [];
  List<Attachment> _filtered = const [];

  int? _selectedYear;
  int? _selectedMonth;

  // ===== BUSY / BARRIER =====
  bool _busy = false;

  Future<T> _withBusy<T>(Future<T> Function() task) async {
    if (mounted) setState(() => _busy = true);
    try {
      return await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _wrapBusy(VoidCallback? fn) async {
    if (fn == null) return;
    await _withBusy(() async => fn());
  }

  Future<void> _wrapBusyIndex(void Function(int index)? fn, int index) async {
    if (fn == null) return;
    await _withBusy(() async => fn(index));
  }

  @override
  void initState() {
    super.initState();
    _loadInitialPhotos();
  }

  // 🔁 Reage à troca de OAE (marker)
  @override
  void didUpdateWidget(covariant ActiveOaesDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.marker.data.id;
    final newId = widget.marker.data.id;
    if (oldId != newId) {
      // limpamos estado de filtro e fotos e recarregamos pra nova OAE
      _selectedYear = null;
      _selectedMonth = null;
      _allPhotos = const [];
      _filtered = const [];
      _photosCtrl.add(const []);
      _loadInitialPhotos();
      setState(() {});
    } else {
      _applyCurrentFilter();
    }
  }

  Future<void> _loadInitialPhotos() async {
    try {
      final id = widget.marker.data.id;
      if (id == null) {
        _photosCtrl.add(const []);
        return;
      }

      final snap = await _db.collection('actives_oaes').doc(id).get();
      final data = (snap.data() ?? <String, dynamic>{});
      final raw = (data['photos'] as List?) ?? const [];

      final list = raw.map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList(growable: true);

      // Ordena por data decrescente
      list.sort((a, b) {
        final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

      _allPhotos = list;
      _filtered = List<Attachment>.from(_allPhotos);
      _photosCtrl.add(_allPhotos);
      setState(() {});
    } catch (_) {
      _allPhotos = const [];
      _filtered = const [];
      _photosCtrl.add(const []);
      setState(() {});
    }
  }

  Future<void> _persistPhotos() async {
    final id = widget.marker.data.id;
    if (id == null) return;
    await _db.collection('actives_oaes').doc(id).set({
      'photos': _allPhotos.map((a) => a.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ====== upload a partir de bytes (câmera/galeria) ======
  Future<void> _addPhotoFromBytes(Uint8List bytes) async {
    await _withBusy(() async {
      final d = widget.marker.data;
      if (d.id == null) return;

      final baseDir = 'actives_oaes/${d.id}/photos';
      final att = await _storage.uploadBytes(
        baseDir: baseDir,
        bytes: bytes,
        originalName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (_) {},
        forcedLabel: 'Foto ${DateTime.now().toIso8601String()}',
      );

      _allPhotos = [..._allPhotos, att];
      _applyCurrentFilter();
      _photosCtrl.add(_allPhotos);
      await _persistPhotos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto adicionada com sucesso!')),
      );
    });
  }

  Future<void> _handleDelete(Attachment att) async {
    await _withBusy(() async {
      await _storage.deleteByPath(att.path ?? '');
      _allPhotos = List<Attachment>.from(_allPhotos)
        ..removeWhere((e) => (e.path ?? e.url) == (att.path ?? att.url));
      _applyCurrentFilter();
      _photosCtrl.add(_allPhotos);
      await _persistPhotos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto removida.')),
      );
    });
  }

  void _applyCurrentFilter() {
    if (_selectedYear == null && _selectedMonth == null) {
      _filtered = List<Attachment>.from(_allPhotos);
      setState(() {});
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
    setState(() {});
  }

  @override
  void dispose() {
    _photosCtrl.close();
    _storage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.marker.data;

    final entries = <MapEntry<String, String>>[
      MapEntry('Identificação', d.identificationName ?? '-'),
      MapEntry('UF', d.state ?? '-'),
      MapEntry('Município', d.state ?? '-'), // TODO: substituir quando houver campo específico
      MapEntry('Nota', (d.score != null) ? d.score!.toStringAsFixed(1) : '-'),
      MapEntry('Ordem', d.order?.toString() ?? '-'),
      MapEntry(
        'Coordenadas',
        '${widget.marker.point.latitude.toStringAsFixed(5)}, ${widget.marker.point.longitude.toStringAsFixed(5)}',
      ),
      ...widget.marker.properties.entries.map(
            (e) => MapEntry(e.key, e.value?.toString() ?? ''),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          BackgroundClean(),
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
                    onAddPressed: widget.isEditable && !_busy
                        ? () => _wrapBusy(widget.onAddSideItem)
                        : null,
                    onTap: !_busy
                        ? (i) => _wrapBusyIndex(widget.onTapSideItem, i)
                        : null,
                    onDelete: widget.isEditable && !_busy
                        ? (i) => _wrapBusyIndex(widget.onDeleteSideItem, i)
                        : null,
                    onEditLabel: widget.isEditable && !_busy
                        ? (i) => _wrapBusyIndex(widget.onEditLabelSideItem, i)
                        : null,
                  ),
                ),
              );

              final details = DetailsPanelBody(entries: entries);

              // ====== HEADER NO INÍCIO ======
              final header = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: PanelHeader(
                  title: d.identificationName ?? 'Detalhes da OAE',
                  onClose: _busy ? null : widget.onClose,
                ),
              );

              final double photosHeight = const CarouselPhotoTheme().itemSize;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- Cabeçalho ----------
                    header,
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // ---------- Linha horizontal: [ PhotoPickerSquare | thumbs... ] ----------
                    SizedBox(
                      height: photosHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: (_filtered.isEmpty ? 0 : _filtered.length) +
                            (widget.isEditable ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          // índice 0 reservado para o botão de adicionar
                          final bool hasAdder = widget.isEditable;
                          final int offset = hasAdder ? 1 : 0;

                          if (hasAdder && index == 0) {
                            return PhotoPickerSquare(
                              enabled: !_busy,
                              onPickFromCamera: (bytes) => _addPhotoFromBytes(bytes),
                              onPickFromGallery: (bytes) => _addPhotoFromBytes(bytes),
                              editorMaxScale: 5.0,
                              editorExportQuality: 100,
                              editorCircleCrop: false,
                              editorAspectRatios: const [1, 4 / 3, 16 / 9],
                            );
                          }

                          // itens de foto
                          final att = _filtered[index - offset];
                          final item = att.toPhotoItem();

                          return PhotoThumb(
                            item: item,
                            theme: const CarouselPhotoTheme(),
                            onTap: () async {
                              // abre a galeria iniciando no índice visível (considerando adder)
                              final items = _filtered.map((a) => a.toPhotoItem()).toList();
                              final start = index - offset;
                              await showPhotoGalleryDialog(
                                context,
                                items: items,
                                initialIndex: start.clamp(0, items.length - 1),
                              );
                            },
                            onRemove: (widget.isEditable && !_busy)
                                ? () => _handleDelete(att)
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ---------- Seletor de ano/mês ----------
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
                              setState(() {});
                            },
                            onSelectionChanged: ({
                              required filteredItems,
                              int? selectedYear,
                              int? selectedMonth,
                            }) {
                              _selectedYear = selectedYear;
                              _selectedMonth = selectedMonth;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DividerText(title: 'Projetos e Documentos da OAE'),
                    const SizedBox(width: 12),
                    // ---------- Campos / SideList ----------
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: isSmall
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          side,
                          const SizedBox(height: 12),
                          DividerText(title: 'Informações gerais da OAE'),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: details,
                          ),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          side,
                          const SizedBox(width: 12),
                          DividerText(title: 'Informações gerais da OAE'),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: details,
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

          // ===== Overlay / Barrier enquanto ocupado =====
          if (_busy) ...[
            Positioned.fill(
              child: ModalBarrier(
                color: Colors.black.withOpacity(0.20),
                dismissible: false,
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 4),
                          CircularProgressIndicator(strokeWidth: 3),
                          SizedBox(width: 12),
                          Text('Processando...', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Adaptador: Attachment -> PhotoItem (PhotoUrlItem) + CarouselMetadata
/// ---------------------------------------------------------------------------
extension _AttachmentToPhoto on Attachment {
  PhotoItem toPhotoItem() {
    final meta = pm.CarouselMetadata(
      url: url,
      name: label,
      takenAt: createdAt,
      uploadedAtMs: createdAt?.millisecondsSinceEpoch,
      uploadedBy: updatedBy,
    );
    return PhotoUrlItem(url ?? '', meta: meta);
  }
}

