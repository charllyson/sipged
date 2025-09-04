// lib/_widgets/schedule/schedule_modal_square.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Utils / domínio
import 'package:siged/_widgets/schedule/schedule_photo_utils.dart';
import 'package:siged/_widgets/schedule/schedule_status.dart';

// BLoC
import 'package:siged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/schedule_event.dart';

// Carrossel e metadados
import 'package:siged/_widgets/carousel/photo_carousel.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_photo.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;
import 'package:siged/_blocs/widgets/carousel/carousel_photo_theme.dart';

// Widgets separados
import 'package:siged/_widgets/carousel/photo_picker_square.dart';
import 'package:siged/screens/sectors/operation/schedule/status_chips.dart';

class ScheduleModalSquare extends StatefulWidget {
  final int estaca;
  final int trackIndex;
  final String currentUserId;

  /// Label do serviço (mostra e salva como `tipo`)
  final String tipoLabel;

  /// Fotos já salvas na célula
  final List<String> existingUrls;
  final Map<String, pm.CarouselMetadata> existingMetaByUrl;

  /// Status inicial do modal
  final ScheduleStatus initialStatus;

  /// Data inicial opcional da célula (ex.: campo `takenAtMs` salvo no doc)
  final DateTime? initialTakenAt;

  const ScheduleModalSquare({
    super.key,
    required this.estaca,
    required this.trackIndex,
    required this.currentUserId,
    required this.tipoLabel,
    this.existingUrls = const [],
    this.existingMetaByUrl = const {},
    this.initialStatus = ScheduleStatus.concluido,
    this.initialTakenAt,
  });

  @override
  State<ScheduleModalSquare> createState() => _ScheduleModalSquareState();
}

class _ScheduleModalSquareState extends State<ScheduleModalSquare> {
  late ScheduleStatus _status;
  final _commentCtrl = TextEditingController();

  /// A data exibida/alterada no modal
  late DateTime _selectedDate;

  bool _busy = false;

  // ====== Fotos (estado local para thumbs) ======
  late List<String> _existingUrls; // já salvas (podem ser removidas localmente)
  late Map<String, pm.CarouselMetadata> _existingMetaByUrl;

  final List<CarouselPhoto> _newPhotos = [];          // pendentes (bytes + nome)
  final List<pm.CarouselMetadata> _newMetas = [];     // pendentes (EXIF)

  @override
  void initState() {
    super.initState();

    _status = widget.initialStatus;
    _existingUrls = List<String>.from(widget.existingUrls);
    _existingMetaByUrl = Map<String, pm.CarouselMetadata>.from(widget.existingMetaByUrl);

    // Define a data inicial:
    // 1) usa initialTakenAt (se informada pelo chamador)
    // 2) senão, infere a MAIOR data "takenAt" das fotos existentes
    // 3) fallback: hoje
    _selectedDate = widget.initialTakenAt ??
        _inferTakenAtFromExistingMetas() ??
        DateTime.now();

    if (kDebugMode) {
      debugPrint('[MODAL] init — estaca=${widget.estaca} faixa=${widget.trackIndex} tipo=${widget.tipoLabel}');
      debugPrint('[MODAL] init — initialStatus=${_status.key} existingUrls=${_existingUrls.length}');
      debugPrint('[MODAL] init — selectedDate=$_selectedDate');
    }
  }

  /// Procura a MAIOR data disponível nas metas existentes.
  /// Tenta `meta.takenAt` e, na falta, `uploadedAtMs` como aproximação.
  DateTime? _inferTakenAtFromExistingMetas() {
    if (_existingMetaByUrl.isEmpty) return null;

    DateTime? best;
    for (final m in _existingMetaByUrl.values) {
      DateTime? d = m.takenAt;
      // fallback: se não tiver takenAt, tenta uploadedAtMs
      if (d == null && (m.uploadedAtMs != null)) {
        try {
          d = DateTime.fromMillisecondsSinceEpoch(m.uploadedAtMs!);
        } catch (_) {}
      }
      if (d == null) continue;
      if (best == null || d.isAfter(best)) best = d;
    }
    return best;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  // ---------- PICK (somente prepara thumbs; upload só no "Salvar") ----------
  Future<void> _pickPhotos() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
        withReadStream: true,
      );
      if (res == null) return;

      for (final f in res.files) {
        Uint8List? data = f.bytes;
        if (data == null && f.readStream != null) {
          data = await SchedulePhotoUtils.readAll(f.readStream!);
        }
        if (data == null) continue;

        final converted = await SchedulePhotoUtils.convertAndExtract(
          original: data,
          originalName: f.name,
          fallbackTakenAt: _selectedDate, // usa a data atual do modal
        );

        _newPhotos.add(CarouselPhoto(name: converted.name, bytes: converted.bytes));
        _newMetas.add(converted.meta);
      }

      if (mounted) setState(() {});
      if (kDebugMode) {
        debugPrint('[MODAL] picked ${_newPhotos.length} new photos (total new metas: ${_newMetas.length})');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Remoções locais ----------
  void _removeExistingAt(int index) {
    setState(() {
      final removed = _existingUrls.removeAt(index);
      _existingMetaByUrl.remove(removed);
    });
    if (kDebugMode) {
      debugPrint('[MODAL] removed existing at $index');
    }
  }

  void _removeNewAt(int index) {
    setState(() {
      _newPhotos.removeAt(index);
      _newMetas.removeAt(index);
    });
    if (kDebugMode) {
      debugPrint('[MODAL] removed new at $index');
    }
  }

  // ---------- Salvar: APLICA TUDO (status + comentário + data + fotos) ----------
  Future<void> _onSave(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final finalPhotoUrls = List<String>.from(_existingUrls);

      if (kDebugMode) {
        debugPrint('[MODAL] saving — status=${_status.key} takenAt=$_selectedDate comment="${_commentCtrl.text.trim()}"');
        debugPrint('[MODAL] saving — finalPhotoUrls=${finalPhotoUrls.length} newPhotos=${_newPhotos.length}');
      }

      context.read<ScheduleBloc>().add(
        ScheduleSquareApplyRequested(
          estaca: widget.estaca,
          faixaIndex: widget.trackIndex,
          tipoLabel: widget.tipoLabel,
          status: _status.key,
          comentario: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          takenAt: _selectedDate, // salva/atualiza a data da célula
          finalPhotoUrls: finalPhotoUrls,
          newFilesBytes: _newPhotos.map((p) => p.bytes).toList(),
          newFileNames: _newPhotos.map((p) => p.name).toList(),
          newPhotoMetas: List<pm.CarouselMetadata>.from(_newMetas),
          currentUserId: widget.currentUserId,
        ),
      );

      if (mounted) {
        if (kDebugMode) {
          debugPrint('[MODAL] closing — SaveSummary(newCount=${_newPhotos.length})');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar execução — ${widget.tipoLabel}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status chips (o widget já faz rolagem horizontal quando necessário)
              StatusChips(
                selected: _status,
                onSelect: _busy ? null : (s) => setState(() => _status = s),
              ),

              const SizedBox(height: 12),

              // Data
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data: ${_selectedDate.day.toString().padLeft(2, '0')}/'
                          '${_selectedDate.month.toString().padLeft(2, '0')}/'
                          '${_selectedDate.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setState(() => _selectedDate = d);
                        if (kDebugMode) {
                          debugPrint('[MODAL] date changed -> $_selectedDate');
                        }
                      }
                    },
                    child: const Text('Alterar'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Carrossel com thumbs (existentes + novas)
              PhotoCarousel.fromSeparated(
                leading: PhotoPickerSquare(
                  enabled: !_busy,
                  onTap: _pickPhotos,
                ),
                existingUrls: _existingUrls,
                existingMetaByUrl: _existingMetaByUrl,
                newPhotos: _newPhotos,
                newMetas: _newMetas,
                onRemoveNew: _busy ? null : _removeNewAt,
                onRemoveExisting: _busy ? null : _removeExistingAt,
                theme: const CarouselPhotoTheme(itemSize: 96, spacing: 8),
              ),

              const SizedBox(height: 12),

              // Comentário
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _onSave(context),
                      icon: const Icon(Icons.done),
                      label: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
