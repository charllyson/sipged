import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

class ScheduleCells extends StatelessWidget {
  final ScheduleData scheduleData;
  final double height;
  final Color cor;
  final VoidCallback onTap;

  // Seleção
  final bool isSelected;
  final Color highlightColor;

  // Tooltip
  final bool stableTooltip;
  final TooltipTriggerMode activeTooltipTrigger;
  final Duration waitDuration;
  final Duration showDuration;

  /// Resolve UID → nome legível
  final String Function(String? uid)? userLabelResolver;

  const ScheduleCells({
    super.key,
    required this.scheduleData,
    required this.height,
    required this.cor,
    required this.onTap,
    this.isSelected = false,
    this.highlightColor = const Color(0xFF1E88E5),
    this.stableTooltip = true,
    this.activeTooltipTrigger = TooltipTriggerMode.longPress,
    this.waitDuration = const Duration(milliseconds: 300),
    this.showDuration = const Duration(seconds: 4),
    this.userLabelResolver,
  });

  bool get _hasComment => (scheduleData.comentario?.trim().isNotEmpty ?? false);

  // ✅ Somente URLs reais em `fotos` disparam o ícone da câmera
  bool get _hasPhotos => scheduleData.fotos.any((u) => u.trim().isNotEmpty);

  int get _photosCount => scheduleData.fotos.where((u) => u.trim().isNotEmpty).length;

  /// Escolhe a melhor data para exibir (tooltip):
  /// 1) takenAt da célula (doc.takenAtMs) -> execucao.takenAt
  /// 2) mais recente das fotos (takenAt|takenAtMs|uploadedAtMs em fotos_meta)
  /// 3) updatedAt / createdAt
  DateTime? _primaryDate() {
    // 1) do doc
    if (scheduleData.takenAt != null) return scheduleData.takenAt;

    // 2) mais recente das metas
    DateTime? best;
    for (final m in scheduleData.fotosMeta) {
      DateTime? d;

      final rawTaken = m['takenAt'] ?? m['takenAtMs'];
      if (rawTaken is int) {
        d = DateTime.fromMillisecondsSinceEpoch(rawTaken);
      } else if (rawTaken is String) {
        final asInt = int.tryParse(rawTaken);
        if (asInt != null) {
          d = DateTime.fromMillisecondsSinceEpoch(asInt);
        } else {
          try { d = DateTime.parse(rawTaken); } catch (_) {}
        }
      } else if (rawTaken is DateTime) {
        d = rawTaken;
      }

      // fallback: uploadedAtMs
      if (d == null) {
        final up = m['uploadedAtMs'];
        if (up is int) d = DateTime.fromMillisecondsSinceEpoch(up);
        if (up is String) {
          final asInt = int.tryParse(up);
          if (asInt != null) d = DateTime.fromMillisecondsSinceEpoch(asInt);
        }
      }

      if (d != null && (best == null || d.isAfter(best))) best = d;
    }

    // 3) updatedAt / createdAt
    return best ?? scheduleData.updatedAt ?? scheduleData.createdAt;
  }

  String _tooltipText() {
    final status = scheduleData.statusLabel;

    final uid = (scheduleData.updatedBy?.isNotEmpty ?? false)
        ? scheduleData.updatedBy
        : scheduleData.createdBy;

    final usuario = userLabelResolver?.call(uid) ?? '—';
    final comentario = scheduleData.comentario?.trim();

    String data = '—', hour = '—';
    final dt = _primaryDate();
    if (dt != null) {
      try {
        data = convertDateTimeToDDMMYYYY(dt);
        hour = convertTimestampHHMM(dt);
      } catch (_) {
        data = '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/'
            '${dt.year}';
        hour = '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    final buf = StringBuffer()
      ..writeln('Status: ${status.isEmpty ? "—" : status}')
      ..writeln('Atualizado por: $usuario')
      ..writeln('Data: $data às $hour');

    if (_hasPhotos) buf.writeln('Fotos: $_photosCount');
    if ((comentario ?? '').isNotEmpty) buf.writeln('Comentário: $comentario');

    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final needsTooltip =
    !((scheduleData.status?.isEmpty ?? true) || scheduleData.status == 'a iniciar');

    final base = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.5),
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: cor,
                  border: isSelected
                      ? Border.all(color: highlightColor, width: 2)
                      : null,
                ),
              ),
            ),
            if (_hasComment || _hasPhotos)
              Positioned.fill(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasComment)
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: Colors.black38),
                      if (_hasComment && _hasPhotos) const SizedBox(width: 8),
                      if (_hasPhotos)
                        const Icon(Icons.camera_alt,
                            size: 16, color: Colors.black38),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Tooltip(
      message: needsTooltip ? _tooltipText() : '',
      triggerMode:
      needsTooltip ? activeTooltipTrigger : TooltipTriggerMode.manual,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: base,
    );
  }
}
