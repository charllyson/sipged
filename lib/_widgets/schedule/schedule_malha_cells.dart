import 'package:flutter/material.dart';
import '../../../../_datas/sectors/operation/calculationMemory/calculation_memory_data.dart';

class MalhaCell extends StatelessWidget {
  final CalculationMemoryData execucao;
  final double altura;
  final Color cor;
  final VoidCallback onTap;

  // <<< NOVO
  final bool isSelected;
  final Color highlightColor;

  const MalhaCell({
    super.key,
    required this.execucao,
    required this.altura,
    required this.cor,
    required this.onTap,
    this.isSelected = false,
    this.highlightColor = const Color(0xFF1E88E5),
  });

  String _tooltipText() {
    final data = execucao.timestamp;
    final comentario = execucao.comentario;
    final buf = StringBuffer()..writeln("Status: ${execucao.status}");
    if (data != null) {
      buf.writeln("Data: ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}");
    }
    if (comentario != null && comentario.trim().isNotEmpty) {
      buf.writeln("Comentário: $comentario");
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final hasComment = (execucao.comentario?.trim().isNotEmpty ?? false);

    final child = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 20,
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
            if (hasComment)
              const Positioned.fill(
                child: Center(
                  child: Icon(Icons.info_outline_rounded, size: 15, color: Colors.black38),
                ),
              ),
          ],
        ),
      ),
    );

    if ((execucao.status?.isEmpty ?? true) || execucao.status == 'a iniciar') {
      return child;
    } else {
      return Tooltip(message: _tooltipText(), child: child);
    }
  }
}
