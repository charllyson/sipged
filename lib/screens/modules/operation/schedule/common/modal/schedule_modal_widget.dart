// lib/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/sheets/draggable_sheet.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_buttons.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_date.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_header.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_photo.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_status.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';

class ScheduleModalWidget extends StatefulWidget {
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
  /// Este callback não é chamado automaticamente ao cancelar/fechar,
  /// para evitar salvamento/notificação indevidos.
  final VoidCallback? onClose;

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

  final bool _picking = false;
  bool _saving = false;

  List<String> _existingUrls = <String>[];

  Map<String, Map<String, dynamic>> _existingMetaByUrl =
  <String, Map<String, dynamic>>{};

  final List<PhotoData> _newPhotos = <PhotoData>[];

  bool get _isMulti => widget.targets.length > 1;

  bool get _isBusy => _picking || _saving;

  bool get _hasComment => _commentCtrl.text.trim().isNotEmpty;

  bool get _hasPhotos => _existingUrls.isNotEmpty || _newPhotos.isNotEmpty;

  double _initialProgressForStatus(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.aIniciar:
        return 0.0;

      case ScheduleStatus.emAndamento:
        return 1.0;

      case ScheduleStatus.concluido:
        return 100.0;
    }
  }

  ScheduleLinearCellStatus _toCellStatus(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.aIniciar:
        return ScheduleLinearCellStatus.aIniciar;

      case ScheduleStatus.emAndamento:
        return ScheduleLinearCellStatus.emAndamento;

      case ScheduleStatus.concluido:
        return ScheduleLinearCellStatus.concluido;
    }
  }

  String _effectiveServiceKey(ScheduleLinearState state) {
    final current = state.currentServiceKey.trim();

    if (current.isNotEmpty && current != ScheduleLinearServicesData.geralKey) {
      return current;
    }

    return '';
  }

  String _photoId() {
    return 'photo_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _safePhotoName(String suggestedName) {
    final clean = suggestedName.trim();

    if (clean.isEmpty) {
      return 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    return clean;
  }

  bool _photoHasUsableSource(PhotoData photo) {
    final hasBytes = photo.bytes != null && photo.bytes!.isNotEmpty;
    final hasUrl = photo.url != null && photo.url!.trim().isNotEmpty;

    return hasBytes || hasUrl;
  }

  List<PhotoData> _filterValidPhotos(List<PhotoData> photos) {
    return photos.where(_photoHasUsableSource).toList(growable: false);
  }

  PhotoData _normalizePickedPhoto(PhotoData photo) {
    return photo.copyWith(
      id: photo.id.trim().isEmpty ? _photoId() : photo.id,
      name: photo.name.trim().isEmpty ? _safePhotoName('foto.jpg') : photo.name,
      takenAt: photo.takenAt ?? _selectedDate,
      uploadedAtMs: photo.uploadedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      uploadedBy: photo.uploadedBy ?? widget.currentUserId,
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _closeOnly(BuildContext context) {
    if (_isBusy) return;

    Navigator.of(
      context,
      rootNavigator: false,
    ).maybePop(false);
  }

  void _closeSaved(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: false,
    ).pop(true);
  }

  void _bumpProgressIfNeeded() {
    if (_progressTouched) return;
    if (!_hasComment && !_hasPhotos) return;
    if (_progress > 0) return;
    if (!mounted) return;

    setState(() {
      _progress = 1.0;
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
      _progress = widget.initialProgress!.clamp(0.0, 100.0).toDouble();
      _progressTouched = true;
    } else {
      _progress = _initialProgressForStatus(widget.initialStatus);
      _progressTouched = false;
    }

    final now = DateTime.now();

    _selectedDate =
        widget.initialTakenAt ?? DateTime(now.year, now.month, now.day);

    _hydrateSingleTargetInitialData();

    if (_hasComment || _hasPhotos) {
      _bumpProgressIfNeeded();
    }
  }

  void _hydrateSingleTargetInitialData() {
    if (_isMulti || widget.targets.isEmpty) return;

    final cubit = context.read<ScheduleLinearCubit>();
    final state = cubit.state;
    final target = widget.targets.first;

    final serviceKey = _effectiveServiceKey(state);

    if (serviceKey.isEmpty) return;

    final fotos = state.fotosAtuaisForService(
      serviceKey: serviceKey,
      estaca: target.estaca,
      faixa: target.faixaIndex,
    );

    _existingUrls = List<String>.from(fotos);

    final ScheduleLinearCellData? data = state.cellAt(
      serviceKey: serviceKey,
      estaca: target.estaca,
      faixa: target.faixaIndex,
    );

    if (data == null) return;

    final metaMap = <String, Map<String, dynamic>>{};

    for (final meta in data.fotosMeta) {
      final url = meta['url']?.toString() ?? '';

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

  @override
  void dispose() {
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.dispose();

    super.dispose();
  }

  void _setDate(DateTime date) {
    if (_selectedDate == date) return;

    setState(() {
      _selectedDate = date;

      for (int i = 0; i < _newPhotos.length; i++) {
        _newPhotos[i] = _newPhotos[i].copyWith(
          takenAt: date,
        );
      }
    });
  }

  void _setStatus(ScheduleStatus status) {
    if (_status == status && _progressTouched) return;

    setState(() {
      _status = status;

      if (!_progressTouched) {
        _progress = _initialProgressForStatus(status);
      }
    });
  }

  void _setProgress(double value) {
    final next = value.clamp(0.0, 100.0).toDouble();

    if (_progressTouched && _progress == next) return;

    setState(() {
      _progressTouched = true;
      _progress = next;
    });
  }

  Future<void> _addNewPhoto(PhotoData photo) async {
    if (_isBusy) return;

    final normalized = _normalizePickedPhoto(photo);

    if (!_photoHasUsableSource(normalized)) {
      _showError(
        'A foto selecionada não possui imagem válida para salvar. '
            'Tente escolher novamente pela câmera ou galeria.',
      );
      return;
    }

    setState(() {
      _newPhotos.add(normalized);
    });

    _bumpProgressIfNeeded();
  }

  Future<void> _addNewPhotos(List<PhotoData> photos) async {
    if (_isBusy) return;
    if (photos.isEmpty) return;

    final normalizedPhotos = photos.map(_normalizePickedPhoto).toList();
    final validPhotos = _filterValidPhotos(normalizedPhotos);

    if (validPhotos.isEmpty) {
      _showError(
        'Nenhuma das fotos selecionadas possui imagem válida para salvar.',
      );
      return;
    }

    setState(() {
      _newPhotos.addAll(validPhotos);
    });

    _bumpProgressIfNeeded();
  }

  Future<void> _editNewPhotoAt(int index, PhotoData photo) async {
    if (_isBusy) return;
    if (index < 0 || index >= _newPhotos.length) return;

    final normalized = _normalizePickedPhoto(photo);

    if (!_photoHasUsableSource(normalized)) {
      _showError(
        'A foto editada não possui imagem válida para salvar.',
      );
      return;
    }

    setState(() {
      _newPhotos[index] = normalized;
    });

    _bumpProgressIfNeeded();
  }

  void _removeNewAt(int index) {
    if (_isBusy) return;
    if (index < 0 || index >= _newPhotos.length) return;

    setState(() {
      _newPhotos.removeAt(index);
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

  Future<List<PhotoData>> _preparePhotosForUpload({
    required List<PhotoData> photos,
    required DateTime takenAt,
  }) async {
    final output = <PhotoData>[];

    for (final photo in photos) {
      final normalized = photo.copyWith(
        takenAt: photo.takenAt ?? takenAt,
        uploadedAtMs:
        photo.uploadedAtMs ?? DateTime.now().millisecondsSinceEpoch,
        uploadedBy: photo.uploadedBy ?? widget.currentUserId,
      );

      final hasBytes = normalized.bytes != null && normalized.bytes!.isNotEmpty;
      final hasUrl = normalized.url != null && normalized.url!.trim().isNotEmpty;

      if (!hasBytes && !hasUrl) {
        debugPrint(
          '[ScheduleModalWidget] Foto ignorada: sem bytes e sem URL. '
              'id=${normalized.id}, name=${normalized.name}',
        );
        continue;
      }

      output.add(normalized);
    }

    return output;
  }

  List<ScheduleLinearApplyTarget> _buildApplyTargets({
    required ScheduleLinearCubit cubit,
    required String serviceKey,
  }) {
    if (_isMulti) {
      return widget.targets.map((target) {
        final urls = cubit.state.fotosAtuaisForService(
          serviceKey: serviceKey,
          estaca: target.estaca,
          faixa: target.faixaIndex,
        );

        return ScheduleLinearApplyTarget(
          estaca: target.estaca,
          faixaIndex: target.faixaIndex,
          finalPhotoUrls: List<String>.from(urls),
        );
      }).toList(growable: false);
    }

    return widget.targets.map((target) {
      return ScheduleLinearApplyTarget(
        estaca: target.estaca,
        faixaIndex: target.faixaIndex,
        finalPhotoUrls: List<String>.from(_existingUrls),
      );
    }).toList(growable: false);
  }

  Future<void> _handleConfirm(
      BuildContext context,
      VoidCallback closeOnly,
      ) async {
    if (_saving || _picking) return;

    final cubit = context.read<ScheduleLinearCubit>();
    final state = cubit.state;
    final serviceKey = _effectiveServiceKey(state);

    if (serviceKey.isEmpty) {
      _showError(
        'Selecione um serviço específico antes de salvar a execução. '
            'O modo GERAL é apenas leitura.',
      );
      return;
    }

    if (widget.targets.isEmpty) {
      _showError('Nenhum item selecionado para aplicar.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final comment = _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim();

      final cellStatus = _toCellStatus(_status);
      final takenAt = _selectedDate;

      final applyTargets = _buildApplyTargets(
        cubit: cubit,
        serviceKey: serviceKey,
      );

      final photosToSend = _isMulti
          ? const <PhotoData>[]
          : await _preparePhotosForUpload(
        photos: _newPhotos,
        takenAt: takenAt,
      );

      await cubit.applySquareChangesBatch(
        serviceKey: serviceKey,
        targets: applyTargets,
        status: cellStatus,
        comentario: comment,
        takenAtForNew: takenAt,
        newPhotos: photosToSend,
        currentUserId: widget.currentUserId,
      );

      final hasError =
          cubit.state.error != null && cubit.state.error!.trim().isNotEmpty;

      if (!context.mounted) return;

      if (!hasError) {
        _closeSaved(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPopNow = !_saving && !_picking;

    return BlocListener<ScheduleLinearCubit, ScheduleLinearState>(
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
              final clampedProgress = _progress.clamp(0.0, 100.0).toDouble();

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
                onClose: closeOnly,
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScheduleScheduleHeader(
                      type: widget.type,
                      name: widget.initialName ?? '',
                      targets: widget.targets,
                    ),
                    const SizedBox(height: 8.0),
                    ScheduleModalStatus(
                      showSlider: true,
                      status: _status,
                      progress: clampedProgress,
                      enabled: !_isBusy,
                      onStatusChanged: _setStatus,
                      onProgressChanged: _setProgress,
                    ),
                    const SizedBox(height: 12.0),
                    ScheduleModalDate(
                      labelPrefix: 'Data do serviço:',
                      selectedDate: _selectedDate,
                      enabled: !_isBusy,
                      onChanged: _setDate,
                    ),
                    const SizedBox(height: 12.0),
                    ScheduleModalPhoto(
                      isMulti: _isMulti,
                      picking: _picking,
                      saving: _saving,
                      currentUserId: widget.currentUserId,
                      existingUrls: _existingUrls,
                      existingMetaByUrl: _existingMetaByUrl,
                      newPhotos: _newPhotos,
                      onAddNewPhoto: _isMulti ? null : _addNewPhoto,
                      onAddNewPhotos: _isMulti ? null : _addNewPhotos,
                      onEditNewPhoto: _isMulti ? null : _editNewPhotoAt,
                      onPickPhotos: null,
                      onRemoveNew: _isMulti ? null : _removeNewAt,
                      onRemoveExisting: _isMulti ? null : _removeExistingAt,
                    ),
                    const SizedBox(height: 12.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                      ),
                      child: CustomTextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        enabled: !_isBusy,
                        labelText: 'Comentário (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12.0),
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