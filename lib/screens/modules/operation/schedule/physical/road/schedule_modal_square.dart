// lib/_widgets/schedule/modal/schedule_modal_square.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:siged/_blocs/modules/operation/operation/road/schedule_road_state.dart';
import 'package:siged/_widgets/schedule/modal/actions_row.dart';

// Partes da UI do modal
import 'package:siged/_widgets/schedule/modal/comment_field.dart';
import 'package:siged/_widgets/schedule/modal/date_row.dart';
import 'package:siged/_widgets/schedule/modal/header.dart';
import 'package:siged/_widgets/schedule/modal/photo_section.dart';
import 'package:siged/_widgets/schedule/modal/status_row.dart';

// Tipos
import 'package:siged/_widgets/schedule/modal/type.dart';
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';

// Base genérico da “folha” draggável
import 'package:siged/_widgets/sheets/draggable_sheet/draggable_sheet.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleModalSquare extends StatefulWidget {
  final String currentUserId;
  final String tipoLabel;

  /// Tipo do cronograma (rodoviário/civil)
  final ScheduleType type;

  /// Alvos de aplicação (um ou vários). Para unitário, passe 1 item.
  final List<ScheduleApplyTarget> targets;

  // ===== Estados iniciais comuns à UI =====
  final String? initialName;
  final ScheduleStatus initialStatus;
  final DateTime? initialTakenAt;
  final String? initialComment;

  /// Percentual inicial da célula (se já salvo em algum lugar).
  final double? initialProgress;

  /// Callback disparado pelo botão "Apagar área"
  final VoidCallback? onDelete;

  final VoidCallback? onClose;

  const ScheduleModalSquare({
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

  IconData _confirmIcon() => _applyCount <= 1 ? Icons.done : Icons.done_all;

  @override
  State<ScheduleModalSquare> createState() => _ScheduleModalSquareState();
}

class _ScheduleModalSquareState extends State<ScheduleModalSquare> {
  late final TextEditingController _commentCtrl;
  late DateTime _selectedDate;
  late ScheduleStatus _status;
  late double _progress;

  /// Indica se o usuário já mexeu manualmente no slider de percentual.
  bool _progressTouched = false;

  bool _picking = false;
  bool _saving = false;

  // Fotos (apenas para seleção unitária)
  List<String> _existingUrls = [];
  Map<String, Map<String, dynamic>> _existingMetaByUrl = {};
  final List<Uint8List> _newPhotos = [];
  final List<pm.CarouselMetadata> _newMetas = [];
  final List<String> _newNames = [];

  bool get _isMulti => widget.targets.length > 1;

  /// Percentual "padrão" baseado apenas no status
  /// (usado apenas quando NÃO existe progress salvo).
  ///
  /// Regra:
  ///   - A Iniciar     -> 0%
  ///   - Em andamento  -> 1%  (mínimo visual)
  ///   - Concluído     -> 100%
  double _initialProgressForStatus(ScheduleStatus s) {
    switch (s) {
      case ScheduleStatus.aIniciar:
        return 0;
      case ScheduleStatus.emAndamento:
        return 1; // 👈 ao marcar "em andamento", sobe pra 1% se não tiver valor salvo
      case ScheduleStatus.concluido:
        return 100;
    }
  }

  String _statusToString(ScheduleStatus s) {
    switch (s) {
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

  /// Regra de auto-bump:
  /// - Se ainda NÃO mexeu manualmente no slider;
  /// - E tiver comentário OU foto;
  /// - E o progresso atual for 0;
  /// => sobe para 1%.
  void _bumpProgressIfNeeded() {
    if (_progressTouched) return;
    if (!_hasComment && !_hasPhotos) return;
    if (_progress > 0) return;

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

    _commentCtrl = TextEditingController(text: widget.initialComment ?? '');
    _commentCtrl.addListener(_onCommentChanged);

    _status = widget.initialStatus;

    // Se vier um progress salvo, usamos ele e marcamos como "tocado".
    // Se não vier, usamos o default do status.
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

    // Carrega fotos/comentário/data atuais apenas para seleção unitária
    if (!_isMulti) {
      final cubit = context.read<ScheduleRoadCubit>();
      final st = cubit.state;
      final t = widget.targets.first;

      final fotos = st.fotosAtuaisFor(t.estaca, t.faixaIndex);
      _existingUrls = List<String>.from(fotos);

      final data = st.execIndex[t.estaca]?[t.faixaIndex];
      if (data != null) {
        final metaMap = <String, Map<String, dynamic>>{};
        for (final m in data.fotosMeta) {
          final url = (m['url'] as String?) ?? '';
          if (url.isNotEmpty) {
            metaMap[url] = Map<String, dynamic>.from(m);
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

    // Caso já exista comentário ou foto ao abrir,
    // podemos também dar o bump (desde que progress ainda seja 0 e não tocado).
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

  void _setDate(DateTime d) {
    setState(() {
      _selectedDate = d;
    });
  }

  void _setStatus(ScheduleStatus s) {
    setState(() {
      _status = s;

      // Só aplica default do status se o usuário ainda não mexeu no slider.
      if (!_progressTouched) {
        _progress = _initialProgressForStatus(s);
      }
    });
  }

  void _setProgress(double v) {
    setState(() {
      _progressTouched = true;
      _progress = v.clamp(0, 100).toDouble();
    });
  }

  Future<void> _addNewPhotoBytes(Uint8List bytes, String suggestedName) async {
    setState(() {
      _newPhotos.add(bytes);
      _newMetas.add(const pm.CarouselMetadata());
      _newNames.add(suggestedName);
    });

    // Adicionou foto => pode disparar auto-bump
    _bumpProgressIfNeeded();
  }

  Future<void> _pickPhotos() async {
    try {
      setState(() => _picking = true);
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.image,
      );
      if (result != null) {
        for (final f in result.files) {
          final bytes = f.bytes;
          if (bytes == null) continue;
          await _addNewPhotoBytes(
            bytes,
            f.name.isNotEmpty ? f.name : 'file.jpg',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  void _removeNewAt(int index) {
    if (index < 0 || index >= _newPhotos.length) return;
    setState(() {
      _newPhotos.removeAt(index);
      _newMetas.removeAt(index);
      _newNames.removeAt(index);
    });
    // Remover não derruba o percentual; só subimos, nunca baixamos automaticamente.
  }

  void _removeExistingAt(int index) {
    if (index < 0 || index >= _existingUrls.length) return;
    setState(() {
      _existingMetaByUrl.remove(_existingUrls[index]);
      _existingUrls.removeAt(index);
    });
    // Mesmo comportamento: não abaixa automaticamente.
  }

  /// Salva e depois fecha o modal
  Future<void> _handleConfirm(
      BuildContext context,
      VoidCallback defaultClose,
      ) async {
    final cubit = context.read<ScheduleRoadCubit>();

    setState(() => _saving = true);
    var success = false;

    try {
      final comment = _commentCtrl.text.trim().isEmpty
          ? null
          : _commentCtrl.text.trim();
      final statusString = _statusToString(_status);
      final takenAt = _selectedDate;

      for (int i = 0; i < widget.targets.length; i++) {
        final t = widget.targets[i];

        // Em seleção múltipla, preserva fotos atuais de cada célula
        List<String> finalUrls;
        if (_isMulti) {
          finalUrls = cubit.state.fotosAtuaisFor(t.estaca, t.faixaIndex);
        } else {
          finalUrls = List<String>.from(_existingUrls);
        }

        await cubit.applySquareToCell(
          estaca: t.estaca,
          faixaIndex: t.faixaIndex,
          tipoLabel: widget.tipoLabel,
          status: statusString,
          comentario: comment,
          takenAt: takenAt,
          finalPhotoUrls: finalUrls,
          newFilesBytes: _isMulti ? const [] : _newPhotos,
          newFileNames: _isMulti ? null : _newNames,
          newPhotoMetas: _isMulti ? const [] : _newMetas,
          currentUserId: widget.currentUserId,
          reloadAfter: i == widget.targets.length - 1,
        );

        // 🔸 Se quiser persistir o _progress da célula,
        // aqui é o ponto para chamar um método extra do Cubit/Repository.
      }

      success = true;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
      if (success) {
        defaultClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleRoadCubit, ScheduleRoadState>(
      listenWhen: (prev, curr) =>
      prev.loadingExecucoes != curr.loadingExecucoes ||
          prev.error != curr.error,
      listener: (bctx, state) {
        // Aqui você pode integrar com AppNotification/NotificationCenter
        // se quiser avisar erro no modal.
      },
      child: WillPopScope(
        // Só bloqueia o back se estiver tirando foto ou salvando
        onWillPop: () async => !_saving && !_picking,
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (sheetContext, scrollController) {
              final isLoading = _picking || _saving;

              final onClose = widget.onClose ??
                      () => Navigator.of(
                    sheetContext,
                    rootNavigator: false,
                  ).maybePop();

              final double clampedProgress =
              _progress.clamp(0, 100).toDouble();

              return BaseDraggableSheet(
                title: widget.tipoLabel,
                icon: widget.type == ScheduleType.rodoviario
                    ? Icons.alt_route
                    : Icons.apartment,
                isLoading: isLoading,
                scrollController: scrollController,

                // personaliza pra ficar “claro” como o modal antigo
                backgroundColor: Colors.white,
                borderColor: Colors.grey.withOpacity(0.2),
                headerIconColor: Colors.blueGrey,
                titleColor: Colors.black87,
                footerBackgroundColor: Colors.grey.shade50,
                onClose: onClose,

                // ===== BODY =====
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScheduleHeaderEditable(
                      type: widget.type,
                      name: widget.initialName ?? '',
                      targets: widget.targets,
                    ),
                    const SizedBox(height: 8),

                    ScheduleStatusRow(
                      showSlider: true,
                      status: _status,
                      progress: clampedProgress,
                      enabled: !isLoading,
                      onStatusChanged: _setStatus,
                      onProgressChanged: _setProgress,
                    ),
                    const SizedBox(height: 12),

                    ScheduleDateRow(
                      labelPrefix: 'Data do serviço:',
                      selectedDate: _selectedDate,
                      enabled: !isLoading,
                      onChanged: _setDate,
                    ),
                    const SizedBox(height: 12),

                    SchedulePhotoSection(
                      isMulti: _isMulti,
                      picking: _picking,
                      saving: _saving,
                      existingUrls: _existingUrls,
                      existingMetaByUrl: _existingMetaByUrl,
                      newPhotos: _newPhotos,
                      newMetas: _newMetas,
                      onAddNewPhotoBytes: _isMulti ? null : _addNewPhotoBytes,
                      onPickPhotos: (_isMulti || !kIsWeb) ? null : _pickPhotos,
                      onRemoveNew: _isMulti ? null : _removeNewAt,
                      onRemoveExisting:
                      _isMulti ? null : _removeExistingAt,
                    ),
                    const SizedBox(height: 12),

                    ScheduleCommentField(
                      controller: _commentCtrl,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

                // ===== FOOTER =====
                bottomArea: ScheduleActionsRow(
                  type: widget.type,
                  confirmLabel: widget._confirmLabel(),
                  confirmIcon: widget._confirmIcon(),
                  onDelete: widget.onDelete,
                  onClose: onClose,
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
