// lib/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_buttons.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_date.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_header.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_photo.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_status.dart';

import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';

import 'package:sipged/_widgets/sheets/draggable_sheet/draggable_sheet.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleModalWidget extends StatefulWidget {
  final String currentUserId;
  final String tipoLabel;

  final ScheduleType type;
  final List<ScheduleApplyTarget> targets;

  final String? initialName;
  final ScheduleStatus initialStatus;
  final DateTime? initialTakenAt;
  final String? initialComment;
  final double? initialProgress;

  /// Usado somente para apagar área no cronograma civil.
  final VoidCallback? onDelete;

  /// Mantido por compatibilidade.
  ///
  /// Atenção:
  /// este callback NÃO é mais chamado automaticamente ao cancelar/fechar,
  /// para evitar disparar salvamento/notificação indevidos.
  final VoidCallback? onClose;

  const ScheduleModalWidget({
    super.key,
    required this.currentUserId,
    required this.tipoLabel,
    required this.type,
    required this.targets,
    this.initialName,
    this.initialStatus = ScheduleStatus.aIniciar,
    this.initialTakenAt,
    this.initialComment,
    this.initialProgress,
    this.onDelete,
    this.onClose,
  });

  int get _applyCount => targets.length;

  String _confirmLabel() {
    if (_applyCount <= 1) return 'Salvar';

    final unit = _applyCount == 1 ? type.singularUnit : type.pluralUnit;

    return 'Aplicar em $_applyCount $unit';
  }

  IconData _confirmIcon() {
    return _applyCount <= 1 ? Icons.done : Icons.done_all;
  }

  @override
  State<ScheduleModalWidget> createState() => _ScheduleModalWidgetState();
}

class _ScheduleModalWidgetState extends State<ScheduleModalWidget> {
  late final TextEditingController _commentCtrl;
  late DateTime _selectedDate;
  late ScheduleStatus _status;
  late double _progress;

  bool _progressTouched = false;

  bool _picking = false;
  bool _saving = false;

  List<String> _existingUrls = <String>[];
  Map<String, Map<String, dynamic>> _existingMetaByUrl =
  <String, Map<String, dynamic>>{};

  final List<Uint8List> _newPhotos = <Uint8List>[];
  final List<pm.CarouselMetadata> _newMetas = <pm.CarouselMetadata>[];
  final List<String> _newNames = <String>[];

  bool get _isMulti => widget.targets.length > 1;

  bool get _isBusy => _picking || _saving;

  double _initialProgressForStatus(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.aIniciar:
        return 0;

      case ScheduleStatus.emAndamento:
        return 1;

      case ScheduleStatus.concluido:
        return 100;
    }
  }

  String _statusToString(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.aIniciar:
        return 'a_iniciar';

      case ScheduleStatus.emAndamento:
        return 'em_andamento';

      case ScheduleStatus.concluido:
        return 'concluido';
    }
  }

  bool get _hasComment => _commentCtrl.text.trim().isNotEmpty;

  bool get _hasPhotos => _existingUrls.isNotEmpty || _newPhotos.isNotEmpty;

  void _closeOnly(BuildContext context) {
    if (_isBusy) return;

    Navigator.of(
      context,
      rootNavigator: false,
    ).maybePop();
  }

  void _bumpProgressIfNeeded() {
    if (_progressTouched) return;
    if (!_hasComment && !_hasPhotos) return;
    if (_progress > 0) return;

    if (!mounted) return;

    setState(() {
      _progress = 1;
    });
  }

  void _onCommentChanged() {
    _bumpProgressIfNeeded();
  }

  @override
  void initState() {
    super.initState();

    _commentCtrl = TextEditingController(
      text: widget.initialComment ?? '',
    );

    _commentCtrl.addListener(_onCommentChanged);

    _status = widget.initialStatus;

    if (widget.initialProgress != null) {
      _progress = widget.initialProgress!.clamp(0, 100).toDouble();
      _progressTouched = true;
    } else {
      _progress = _initialProgressForStatus(widget.initialStatus);
      _progressTouched = false;
    }

    final now = DateTime.now();

    _selectedDate =
        widget.initialTakenAt ?? DateTime(now.year, now.month, now.day);

    if (!_isMulti && widget.targets.isNotEmpty) {
      final cubit = context.read<ScheduleRoadCubit>();
      final state = cubit.state;
      final target = widget.targets.first;

      final fotos = state.fotosAtuaisFor(
        target.estaca,
        target.faixaIndex,
      );

      _existingUrls = List<String>.from(fotos);

      final data = state.execIndex[target.estaca]?[target.faixaIndex];

      if (data != null) {
        final metaMap = <String, Map<String, dynamic>>{};

        for (final meta in data.fotosMeta) {
          final url = (meta['url'] as String?) ?? '';

          if (url.isNotEmpty) {
            metaMap[url] = Map<String, dynamic>.from(meta);
          }
        }

        _existingMetaByUrl = metaMap;

        if ((widget.initialComment ?? '').trim().isEmpty &&
            (data.comentario ?? '').trim().isNotEmpty) {
          _commentCtrl.text = data.comentario!;
        }

        if (widget.initialTakenAt == null && data.primaryDate != null) {
          _selectedDate = data.primaryDate!;
        }
      }
    }

    if (_hasComment || _hasPhotos) {
      _bumpProgressIfNeeded();
    }
  }

  @override
  void dispose() {
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.dispose();

    super.dispose();
  }

  void _setDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _setStatus(ScheduleStatus status) {
    setState(() {
      _status = status;

      if (!_progressTouched) {
        _progress = _initialProgressForStatus(status);
      }
    });
  }

  void _setProgress(double value) {
    setState(() {
      _progressTouched = true;
      _progress = value.clamp(0, 100).toDouble();
    });
  }

  Future<void> _addNewPhotoBytes(
      Uint8List bytes,
      String suggestedName,
      ) async {
    setState(() {
      _newPhotos.add(bytes);
      _newMetas.add(const pm.CarouselMetadata());
      _newNames.add(suggestedName);
    });

    _bumpProgressIfNeeded();
  }

  Future<void> _pickPhotos() async {
    if (_isBusy) return;

    try {
      setState(() {
        _picking = true;
      });

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.image,
      );

      if (result == null) return;

      for (final file in result.files) {
        final bytes = file.bytes;

        if (bytes == null) continue;

        await _addNewPhotoBytes(
          bytes,
          file.name.isNotEmpty ? file.name : 'file.jpg',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
        });
      }
    }
  }

  void _removeNewAt(int index) {
    if (_isBusy) return;
    if (index < 0 || index >= _newPhotos.length) return;

    setState(() {
      _newPhotos.removeAt(index);
      _newMetas.removeAt(index);
      _newNames.removeAt(index);
    });
  }

  void _removeExistingAt(int index) {
    if (_isBusy) return;
    if (index < 0 || index >= _existingUrls.length) return;

    setState(() {
      _existingMetaByUrl.remove(_existingUrls[index]);
      _existingUrls.removeAt(index);
    });
  }

  Future<void> _handleConfirm(
      BuildContext context,
      VoidCallback closeOnly,
      ) async {
    if (_saving || _picking) return;

    final cubit = context.read<ScheduleRoadCubit>();

    setState(() {
      _saving = true;
    });

    var success = false;

    try {
      final comment = _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim();

      final statusString = _statusToString(_status);
      final takenAt = _selectedDate;

      for (int i = 0; i < widget.targets.length; i++) {
        final target = widget.targets[i];

        final List<String> finalUrls;

        if (_isMulti) {
          finalUrls = cubit.state.fotosAtuaisFor(
            target.estaca,
            target.faixaIndex,
          );
        } else {
          finalUrls = List<String>.from(_existingUrls);
        }

        await cubit.applySquareToCell(
          estaca: target.estaca,
          faixaIndex: target.faixaIndex,
          tipoLabel: widget.tipoLabel,
          status: statusString,
          comentario: comment,
          takenAt: takenAt,
          finalPhotoUrls: finalUrls,
          newFilesBytes: _isMulti ? const <Uint8List>[] : _newPhotos,
          newFileNames: _isMulti ? null : _newNames,
          newPhotoMetas:
          _isMulti ? const <pm.CarouselMetadata>[] : _newMetas,
          currentUserId: widget.currentUserId,
          reloadAfter: i == widget.targets.length - 1,
        );
      }

      success = true;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }

      if (success && mounted) {
        closeOnly();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPopNow = !_saving && !_picking;

    return BlocListener<ScheduleRoadCubit, ScheduleRoadState>(
      listenWhen: (previous, current) {
        return previous.error != current.error;
      },
      listener: (context, state) {
        if (state.error == null || state.error!.trim().isEmpty) return;

        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      child: PopScope(
        canPop: canPopNow,
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (sheetContext, scrollController) {
              final clampedProgress = _progress.clamp(0, 100).toDouble();

              void closeOnly() {
                _closeOnly(sheetContext);
              }

              return BaseDraggableSheet(
                title: widget.tipoLabel,
                icon: widget.type == ScheduleType.rodoviario
                    ? Icons.alt_route
                    : Icons.apartment,
                isLoading: _isBusy,
                scrollController: scrollController,
                backgroundColor: Colors.white,
                borderColor: Colors.grey.withValues(alpha: 0.2),
                headerIconColor: Colors.blueGrey,
                titleColor: Colors.black87,
                footerBackgroundColor: Colors.grey.shade50,

                /// Fechar pelo X não salva e não dispara callback externo.
                onClose: closeOnly,

                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScheduleScheduleHeader(
                      type: widget.type,
                      name: widget.initialName ?? '',
                      targets: widget.targets,
                    ),
                    const SizedBox(height: 8),
                    ScheduleModalStatus(
                      showSlider: true,
                      status: _status,
                      progress: clampedProgress,
                      enabled: !_isBusy,
                      onStatusChanged: _setStatus,
                      onProgressChanged: _setProgress,
                    ),
                    const SizedBox(height: 12),
                    ScheduleModalDate(
                      labelPrefix: 'Data do serviço:',
                      selectedDate: _selectedDate,
                      enabled: !_isBusy,
                      onChanged: _setDate,
                    ),
                    const SizedBox(height: 12),
                    ScheduleModalPhoto(
                      isMulti: _isMulti,
                      picking: _picking,
                      saving: _saving,
                      existingUrls: _existingUrls,
                      existingMetaByUrl: _existingMetaByUrl,
                      newPhotos: _newPhotos,
                      newMetas: _newMetas,
                      onAddNewPhotoBytes:
                      _isMulti ? null : _addNewPhotoBytes,
                      onPickPhotos: _isMulti || !kIsWeb ? null : _pickPhotos,
                      onRemoveNew: _isMulti ? null : _removeNewAt,
                      onRemoveExisting: _isMulti ? null : _removeExistingAt,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                      ),
                      child: CustomTextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        enabled: !_isBusy,
                        labelText: 'Comentário (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                bottomArea: ScheduleModalButtons(
                  type: widget.type,
                  confirmLabel: widget._confirmLabel(),
                  confirmIcon: widget._confirmIcon(),
                  onDelete: widget.onDelete,
                  onClose: closeOnly,
                  picking: _picking,
                  saving: _saving,
                  onConfirm: _handleConfirm,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}