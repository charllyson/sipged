// lib/screens/_pages/physical_financial/widgets/table/percent_bar.dart
import 'package:flutter/material.dart';

class PhysFinPercentBar extends StatelessWidget {
  final double percent;
  final double width;
  final double height;

  /// Clique (se `disabled` ou `onTap == null`, fica sem interação)
  final VoidCallback? onTap;

  /// Cor da parte preenchida (barra). Padrão: cinza médio.
  final Color fillColor;

  /// Cor do trilho (fundo). Padrão: cinza claro.
  final Color trackColor;

  /// Bordas
  final BorderRadius radius;

  /// Mostra o rótulo “27%” no centro
  final bool showLabel;

  /// Estilo do rótulo
  final TextStyle? labelStyle;

  /// Aparência desabilitada (sem clique e visual suavizado)
  final bool disabled;

  const PhysFinPercentBar({
    super.key,
    required this.percent,
    this.width = 72,
    this.height = 24,
    this.onTap,
    this.fillColor = const Color(0xFF9E9E9E), // Colors.grey[600]
    this.trackColor = const Color(0xFFE0E0E0), // Colors.grey[300]
    this.radius = const BorderRadius.all(Radius.circular(4)),
    this.showLabel = true,
    this.labelStyle,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0.0, 100.0);
    final effectiveOnTap = disabled ? null : onTap;

    // Visualmente suaviza quando desabilitado
    final double opacity = disabled ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: effectiveOnTap,
            child: Stack(
              children: [
                // trilho
                Container(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: radius,
                  ),
                ),
                // preenchimento
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: p <= 0 ? 0 : p / 100.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fillColor, // ⬅️ agora vem por parâmetro (padrão cinza)
                      borderRadius: radius,
                    ),
                  ),
                ),
                // label
                if (showLabel)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        p > 0 ? '${p.toStringAsFixed(p % 1 == 0 ? 0 : 3)}%' : '',
                        style: labelStyle ??
                            const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
