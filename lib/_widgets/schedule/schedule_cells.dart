import 'package:flutter/material.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_data.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_utils/formats/format_field.dart';

class ScheduleCells extends StatelessWidget {
  final ScheduleData execucao;
  final double altura;
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

  /// Resolve UID → nome legível (string pronta para exibir)
  final String Function(String? uid)? userLabelResolver;

  const ScheduleCells({
    super.key,
    required this.execucao,
    required this.altura,
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

  bool get _hasComment => (execucao.comentario?.trim().isNotEmpty ?? false);

  bool get _hasPhotos {
    final f = execucao.fotos;
    if (f != null) return f.isNotEmpty;
    final fm = execucao.fotosMeta;
    return (fm != null && fm.isNotEmpty);
  }

  int get _photosCount {
    final f = execucao.fotos;
    if (f != null) return f.length;
    final fm = execucao.fotosMeta;
    return (fm.length ?? 0);
  }

  String _tooltipText() {
    final status = (execucao.status ?? '').trim();

    // Preferir "updatedBy" (última modificação), senão "createdBy"
    final uid = (execucao.updatedBy?.isNotEmpty ?? false)
        ? execucao.updatedBy
        : execucao.createdBy;

    final usuario = userLabelResolver?.call(uid) ?? '—';
    final comentario = execucao.comentario?.trim();

    String data = '—', hour = '—';
    final dt = execucao.updatedAt ?? execucao.createdAt;
    if (dt != null) {
      try {
        data = convertDateTimeToDDMMYYYY(dt);
        hour = convertTimestampHHMM(dt);
      } catch (_) {
        data =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        hour =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    final buf = StringBuffer()
      ..writeln('Status: ${status.isEmpty ? "—" : status}')
      ..writeln('Atualizado por: $usuario')
      ..writeln('Data: $data às $hour');

    if (_hasPhotos) buf.writeln('Fotos: $_photosCount');
    if (comentario != null && comentario.isNotEmpty) {
      buf.writeln('Comentário: $comentario');
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final needsTooltip =
    !((execucao.status?.isEmpty ?? true) || execucao.status == 'a iniciar');

    final base = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.5),
        width: double.infinity,
        height: altura,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: cor,
                  border: isSelected ? Border.all(color: highlightColor, width: 2) : null,
                ),
              ),
            ),

            // Ícones centrais: comentário / câmera (+badge)
            if (_hasComment || _hasPhotos)
              Positioned.fill(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hasComment)
                        const Icon(Icons.info_outline_rounded, size: 15, color: Colors.black38),
                      if (_hasComment && _hasPhotos) const SizedBox(width: 8),
                      if (_hasPhotos)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.camera_alt, size: 16, color: Colors.black38),
                          ],
                        ),
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
      triggerMode: needsTooltip ? activeTooltipTrigger : TooltipTriggerMode.manual,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: base,
    );
  }
}