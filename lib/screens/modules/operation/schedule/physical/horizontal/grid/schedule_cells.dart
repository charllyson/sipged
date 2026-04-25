import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';

class ScheduleCells extends StatelessWidget {
  final ScheduleRoadData scheduleData;
  final double height;
  final Color cor;
  final VoidCallback onTap;

  final bool isSelected;
  final Color highlightColor;

  final Duration waitDuration;
  final Duration showDuration;

  /// Resolve UID → nome legível
  final String Function(String? uid)? userLabelResolver;

  /// Controla se a célula está habilitada (faixa aplicável ao serviço)
  final bool enabled;

  const ScheduleCells({
    super.key,
    required this.scheduleData,
    required this.height,
    required this.cor,
    required this.onTap,
    this.isSelected = false,
    this.highlightColor = const Color(0xFF1E88E5),
    this.waitDuration = const Duration(milliseconds: 250),
    this.showDuration = const Duration(seconds: 4),
    this.userLabelResolver,
    this.enabled = true,
  });

  bool get _hasComment => (scheduleData.comentario?.trim().isNotEmpty ?? false);

  bool get _hasPhotos => scheduleData.fotos.any((u) => u.trim().isNotEmpty);

  int get _photosCount =>
      scheduleData.fotos.where((u) => u.trim().isNotEmpty).length;

  DateTime? _primaryDate() {
    if (scheduleData.takenAt != null) return scheduleData.takenAt;

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
          try {
            d = DateTime.parse(rawTaken);
          } catch (_) {}
        }
      } else if (rawTaken is DateTime) {
        d = rawTaken;
      }

      if (d == null) {
        final up = m['uploadedAtMs'];
        if (up is int) d = DateTime.fromMillisecondsSinceEpoch(up);
        if (up is String) {
          final asInt = int.tryParse(up);
          if (asInt != null) d = DateTime.fromMillisecondsSinceEpoch(asInt);
        }
      }

      if (d != null && (best == null || d.isAfter(best))) {
        best = d;
      }
    }

    return best ?? scheduleData.updatedAt ?? scheduleData.createdAt;
  }

  String _richTooltipText() {
    final status = scheduleData.statusLabel;
    final uid = (scheduleData.updatedBy?.isNotEmpty ?? false)
        ? scheduleData.updatedBy
        : scheduleData.createdBy;

    final usuario = userLabelResolver?.call(uid) ?? '—';
    final comentario = scheduleData.comentario?.trim();

    String data = '—';
    String hour = '—';

    final dt = _primaryDate();
    if (dt != null) {
      data = SipGedFormatDates.dateToDdMMyyyy(dt);
      hour = SipGedFormatDates.timeToHHmm(dt);
    }

    final buf = StringBuffer()
      ..writeln('Status: ${status.isEmpty ? "—" : status}')
      ..writeln('Atualizado por: $usuario')
      ..writeln('Data: $data às $hour');

    if (_hasPhotos) {
      buf.writeln('Fotos: $_photosCount');
    }
    if ((comentario ?? '').isNotEmpty) {
      buf.writeln('Comentário: $comentario');
    }

    final msg = buf.toString().trim();
    return msg.isEmpty ? 'A iniciar' : msg;
  }

  Widget _buildCenterIcon() {
    if (_hasPhotos) {
      return const Icon(
        Icons.camera_alt,
        size: 16,
        color: Colors.black38,
      );
    }

    if (_hasComment) {
      return const Icon(
        Icons.info_outline_rounded,
        size: 15,
        color: Colors.black38,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final String tooltipMessage = !enabled
        ? 'Não necessário nestas estacas'
        : (scheduleData.statusCanonical == 'a_iniciar'
        ? 'A iniciar'
        : _richTooltipText());

    final bool showCommentIcon = enabled && _hasComment && !_hasPhotos;
    final bool showPhotoIcon = enabled && _hasPhotos;
    final bool showCenterIcon = showCommentIcon || showPhotoIcon;

    final core = GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
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
                  border: isSelected && enabled
                      ? Border.all(color: highlightColor, width: 2)
                      : null,
                ),
              ),
            ),
            if (showCenterIcon)
              Positioned.fill(
                child: Center(
                  child: _buildCenterIcon(),
                ),
              ),
            if (!enabled)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiagonalStripesPainter(),
                ),
              ),
          ],
        ),
      ),
    );

    final bool shouldShowTooltip = enabled &&
        (scheduleData.statusCanonical != 'a_iniciar' ||
            _hasComment ||
            _hasPhotos);

    if (!shouldShowTooltip) return core;

    return Tooltip(
      message: tooltipMessage,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: core,
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  const _DiagonalStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.grey.shade200;
    canvas.drawRect(Offset.zero & size, bg);

    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.35);
    const double w = 8.0;

    for (double x = -size.height; x < size.width + size.height; x += w * 2) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w, 0)
        ..lineTo(x + w - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}