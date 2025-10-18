import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:siged/_widgets/schedule/linear/schedule_status.dart';
import 'package:siged/_widgets/schedule/linear/schedule_photo_utils.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_widgets/modals/type.dart'; // <- tipos centralizados

import 'package:siged/_widgets/carousel/carousel_photo.dart';
import 'package:siged/_widgets/carousel/carousel_metadata.dart' as pm;

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ScheduleModalController extends ChangeNotifier {
  final ScheduleRoadBloc bloc;

  // ——— Parâmetros fixos do modal
  final String currentUserId;
  final String tipoLabel;

  /// Lista de alvos (1 = célula única, >1 = seleção múltipla)
  final List<ScheduleApplyTarget> targets;

  // ——— Estado editável
  final TextEditingController nameCtrl;
  final TextEditingController commentCtrl;

  ScheduleStatus status;
  double progress; // 0..100
  DateTime selectedDate;

  bool picking = false;
  bool saving = false;
  bool awaitingApply = false;

  // guardamos o callback de fechar (do sheet) passado pela UI
  VoidCallback? _pendingClose;

  // Fotos novas que serão anexadas (somente quando unitário)
  final List<CarouselPhoto> newPhotos = [];
  final List<pm.CarouselMetadata> newMetas = [];

  // Fotos existentes (mutáveis apenas em modo unitário p/ permitir remoção)
  final List<String> _existingUrls;
  final Map<String, pm.CarouselMetadata> _existingMetaByUrl;

  // ==== Conveniências ====
  bool get isMulti => targets.length > 1;
  bool get canAddPhotos => !isMulti;

  List<String> get existingUrls => _existingUrls;
  Map<String, pm.CarouselMetadata> get existingMetaByUrl => _existingMetaByUrl;

  ScheduleModalController({
    required this.bloc,
    required this.currentUserId,
    required this.tipoLabel,
    required this.targets,

    String? initialName,
    ScheduleStatus initialStatus = ScheduleStatus.aIniciar,
    DateTime? initialTakenAt,
    String? initialComment,
    double? initialProgress,
  })  : nameCtrl = TextEditingController(text: (initialName ?? '').trim()),
        commentCtrl = TextEditingController(text: (initialComment ?? '').trim()),
        status = initialProgress != null
            ? _progressToStatus(initialProgress.clamp(0, 100))
            : initialStatus,
        progress = initialProgress != null
            ? initialProgress.clamp(0, 100)
            : _statusToProgress(initialStatus),
  // Em multi não carregamos fotos; em unitário usamos o primeiro target
        _existingUrls = targets.length == 1
            ? List<String>.from(targets.first.existingUrls)
            : <String>[],
        _existingMetaByUrl = targets.length == 1
            ? Map<String, pm.CarouselMetadata>.from(targets.first.existingMetaByUrl)
            : <String, pm.CarouselMetadata>{},
        selectedDate = initialTakenAt ??
            _inferTakenAtFromExistingMetas(
              targets.length == 1 ? targets.first.existingMetaByUrl : const {},
            ) ??
            DateTime.now() {
    _ensureInProgressIfHasContent();
    nameCtrl.addListener(_notify);
    commentCtrl.addListener(_onCommentChanged);
  }

  void disposeAll() {
    nameCtrl.removeListener(_notify);
    commentCtrl.removeListener(_onCommentChanged);
    nameCtrl.dispose();
    commentCtrl.dispose();
    super.dispose();
  }

  // 🔔 helper de notificação
  void _notifyToast(String title,
      {AppNotificationType type = AppNotificationType.info, String? subtitle}) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        type: type,
      ),
    );
  }

  // ——— Helpers de status/progresso
  static double _statusToProgress(ScheduleStatus s) {
    switch (s) {
      case ScheduleStatus.aIniciar:
        return 0;
      case ScheduleStatus.emAndamento:
        return 50;
      case ScheduleStatus.concluido:
        return 100;
    }
  }

  static ScheduleStatus _progressToStatus(double p) {
    if (p >= 100) return ScheduleStatus.concluido;
    if (p <= 0) return ScheduleStatus.aIniciar;
    return ScheduleStatus.emAndamento;
  }

  static DateTime? _inferTakenAtFromExistingMetas(Map<String, pm.CarouselMetadata> metas) {
    if (metas.isEmpty) return null;
    DateTime? best;
    for (final m in metas.values) {
      DateTime? d = m.takenAt;
      if (d == null && m.uploadedAtMs != null) {
        try {
          d = DateTime.fromMillisecondsSinceEpoch(m.uploadedAtMs!);
        } catch (_) {}
      }
      if (d == null) continue;
      if (best == null || d.isAfter(best)) best = d;
    }
    return best;
  }

  void _notify() => notifyListeners();

  void setStatus(ScheduleStatus s) {
    status = s;
    progress = _statusToProgress(s);
    notifyListeners();
  }

  void onSliderChanged(double v) {
    progress = v;
    status = _progressToStatus(v);
    notifyListeners();
  }

  void setDate(DateTime d) {
    selectedDate = d;
    notifyListeners();
  }

  void _onCommentChanged() {
    if (progress == 0 &&
        commentCtrl.text.trim().isNotEmpty &&
        status == ScheduleStatus.aIniciar) {
      setStatus(ScheduleStatus.emAndamento);
    } else {
      notifyListeners();
    }
  }

  void _ensureInProgressIfHasContent() {
    final hasComment = commentCtrl.text.trim().isNotEmpty;
    final hasPhotos = _existingUrls.isNotEmpty || newPhotos.isNotEmpty; // unitário apenas
    if (progress == 0 && (hasComment || hasPhotos) && status == ScheduleStatus.aIniciar) {
      setStatus(ScheduleStatus.emAndamento);
    }
  }

  // ——— Fotos (somente quando canAddPhotos == true) ———
  Future<void> addNewPhotoBytes(Uint8List data, {String suggestedName = 'image.jpg'}) async {
    if (!canAddPhotos) return;
    final converted = await SchedulePhotoUtils.convertAndExtract(
      original: data,
      originalName: suggestedName,
      fallbackTakenAt: selectedDate,
    );
    newPhotos.add(CarouselPhoto(name: converted.name, bytes: converted.bytes));
    newMetas.add(converted.meta);
    _ensureInProgressIfHasContent();
    notifyListeners();
  }

  Future<void> pickPhotos() async {
    if (!canAddPhotos) return;
    if (picking || saving) return;
    picking = true;
    notifyListeners();
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
        withReadStream: true,
      );
      if (res == null) {
        _notifyToast('Seleção de fotos cancelada', type: AppNotificationType.warning);
        return;
      }
      for (final f in res.files) {
        Uint8List? data = f.bytes;
        if (data == null && f.readStream != null) {
          data = await SchedulePhotoUtils.readAll(f.readStream!);
        }
        if (data != null) {
          await addNewPhotoBytes(data, suggestedName: f.name);
        }
      }
      if (res.files.isNotEmpty) {
        _notifyToast('Fotos adicionadas', type: AppNotificationType.success,
            subtitle: '${res.files.length} arquivo(s)');
      }
    } finally {
      picking = false;
      notifyListeners();
    }
  }

  void removeExistingAt(int i) {
    if (!canAddPhotos) return; // em multi não removemos
    if (saving) return;
    final removed = _existingUrls.removeAt(i);
    _existingMetaByUrl.remove(removed);
    _ensureInProgressIfHasContent();
    notifyListeners();
  }

  void removeNewAt(int i) {
    if (!canAddPhotos) return;
    if (saving) return;
    newPhotos.removeAt(i);
    newMetas.removeAt(i);
    _ensureInProgressIfHasContent();
    notifyListeners();
  }

  // ——— Salvar (AGORA ACEITA onClose) ———
  Future<void> save(
      BuildContext context, {
        VoidCallback? onClose,
      }) async {
    if (picking || saving) return;

    _ensureInProgressIfHasContent();
    saving = true;
    awaitingApply = true;
    _pendingClose = onClose; // 👈 guardamos para usar quando o BLoC confirmar
    notifyListeners();

    for (final t in targets) {
      final keepUrls =
      isMulti ? List<String>.from(t.existingUrls) : List<String>.from(_existingUrls);

      bloc.add(
        ScheduleSquareApplyRequested(
          estaca: t.estaca,
          faixaIndex: t.faixaIndex,
          tipoLabel: tipoLabel,
          status: status.key,
          comentario: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
          takenAt: selectedDate,
          finalPhotoUrls: keepUrls,
          newFilesBytes: canAddPhotos ? newPhotos.map((p) => p.bytes).toList() : const [],
          newFileNames: canAddPhotos ? newPhotos.map((p) => p.name).toList() : const [],
          newPhotoMetas: canAddPhotos ? List<pm.CarouselMetadata>.from(newMetas) : const [],
          currentUserId: currentUserId,
        ),
      );
    }
  }

  // ——— Feedback do BLoC
  void onBlocStateChanged(BuildContext ctx,
      {required bool loadingExecucoes, String? error}) {
    if (!awaitingApply) return;

    if (!loadingExecucoes) {
      if (error == null) {
        // sucesso: fecha o modal via callback injetado
        saving = false;
        awaitingApply = false;
        notifyListeners();

        _pendingClose?.call();          // 👈 fecha só o bottom sheet
        _pendingClose = null;

        _notifyToast('Atualização aplicada', type: AppNotificationType.success);
      } else {
        // erro: mantém modal aberto e notifica
        saving = false;
        awaitingApply = false;
        notifyListeners();
        _notifyToast('Falha ao salvar', type: AppNotificationType.error, subtitle: error);
      }
    }
  }
}
