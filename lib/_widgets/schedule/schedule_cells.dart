import 'package:flutter/material.dart';
import '../../_datas/sectors/operation/schedule/schedule_data.dart';

class ScheduleCells extends StatelessWidget {
  final ScheduleData execucao;
  final double altura;
  final Color cor;
  final VoidCallback onTap;

  // Seleção
  final bool isSelected;
  final Color highlightColor;

  // Tooltip estável (recomendado no Web durante arrasto)
  final bool stableTooltip;
  final TooltipTriggerMode activeTooltipTrigger;
  final Duration waitDuration;
  final Duration showDuration;

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
  });

  String _tooltipText() {
    final data = execucao.timestamp;
    final comentario = execucao.comentario;
    final buf = StringBuffer()..writeln("Status: ${execucao.status}");
    if (data != null) {
      buf.writeln(
          "Data: ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}");
    }
    if (comentario != null && comentario.trim().isNotEmpty) {
      buf.writeln("Comentário: $comentario");
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final hasComment = (execucao.comentario?.trim().isNotEmpty ?? false);

    // Conteúdo base da célula
    final base = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(0.5), // 🔹 espaço entre quadrados
        width: double.infinity,
        height: altura, // 🔹 altura vem fechada do pai
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
            if (hasComment)
              const Positioned.fill(
                child: Center(
                  child: Icon(Icons.info_outline_rounded,
                      size: 15, color: Colors.black38),
                ),
              ),
          ],
        ),
      ),
    );

    // Tooltip estável
    final needsTooltip = !((execucao.status?.isEmpty ?? true) || execucao.status == 'a iniciar');

    return Tooltip(
      message: needsTooltip ? _tooltipText() : '',
      triggerMode: needsTooltip ? activeTooltipTrigger : TooltipTriggerMode.manual,
      waitDuration: waitDuration,
      showDuration: showDuration,
      child: base,
    );
  }
}
