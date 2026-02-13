// lib/_widgets/common/stamp.dart
import 'package:flutter/material.dart';

/// Selo reutilizável:
/// - Desktop: ícone + texto; Mobile (compact=true): apenas ícone.
/// - Controla altura com `dense` e paddings.
/// - Cores/ícones/labels por parâmetro.
class Stamp extends StatefulWidget {
  final bool approved;

  /// Quando true, renderiza versão compacta (ícone apenas).
  final bool compact;

  /// Deixa o chip mais “baixo” (pouco padding) para não aumentar o banner.
  final bool dense;

  /// Fator de escala visual (ajuste fino do tamanho).
  final double scaleFactor;

  // Labels
  final String approvedLabel;
  final String pendingLabel;

  // Ícones customizáveis
  final IconData approvedIcon;
  final IconData pendingIcon;

  // Cores customizáveis (tint base)
  final Color approvedColor;
  final Color pendingColor;

  /// Padding vertical/horizontal custom — se quiser sobrepor o `dense`.
  final double? verticalPadding;
  final double? horizontalPadding;

  /// Tamanho do ícone (auto-ajustado se null).
  final double? iconSize;

  const Stamp({
    super.key,
    required this.approved,
    this.compact = false,
    this.dense = false,
    this.scaleFactor = 1.0,
    this.approvedLabel = 'Etapa aprovada',
    this.pendingLabel = 'Etapa pendente',
    this.approvedIcon = Icons.verified_outlined,
    this.pendingIcon = Icons.verified_user_outlined,
    this.approvedColor = Colors.green,
    this.pendingColor = Colors.grey,
    this.verticalPadding,
    this.horizontalPadding,
    this.iconSize,
  });

  @override
  State<Stamp> createState() => _StampState();
}

class _StampState extends State<Stamp> {
  bool _hover = false;

  @override
  void didUpdateWidget(covariant Stamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.approved != widget.approved ||
        oldWidget.compact != widget.compact ||
        oldWidget.dense != widget.dense ||
        oldWidget.approvedColor != widget.approvedColor ||
        oldWidget.pendingColor != widget.pendingColor ||
        oldWidget.verticalPadding != widget.verticalPadding ||
        oldWidget.horizontalPadding != widget.horizontalPadding ||
        oldWidget.iconSize != widget.iconSize) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final approved = widget.approved;
    final baseTint = approved ? widget.approvedColor : widget.pendingColor;
    final bgOpacity = _hover ? 0.20 : 0.12;
    final borderOpacity = _hover ? 0.65 : 0.40;
    final iconTextOpacity = _hover ? 0.95 : 0.85;
    final scale = (_hover ? 1.04 : 1.0) * widget.scaleFactor;

    final iconData = approved ? widget.approvedIcon : widget.pendingIcon;
    final label = approved ? widget.approvedLabel : widget.pendingLabel;

    final chip = _StampChip(
      approved: approved,
      baseTint: baseTint,
      bgOpacity: bgOpacity,
      borderOpacity: borderOpacity,
      iconTextOpacity: iconTextOpacity,
      label: label,
      iconData: iconData,
      compact: widget.compact,
      dense: widget.dense,
      verticalPadding: widget.verticalPadding,
      horizontalPadding: widget.horizontalPadding,
      iconSize: widget.iconSize,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.basic,
      child: Tooltip(
        message: label,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: chip,
          ),
        ),
      ),
    );
  }
}

class _StampChip extends StatelessWidget {
  final bool approved;
  final Color baseTint;
  final double bgOpacity;
  final double borderOpacity;
  final double iconTextOpacity;
  final String label;
  final IconData iconData;
  final bool compact;
  final bool dense;
  final double? verticalPadding;
  final double? horizontalPadding;
  final double? iconSize;

  const _StampChip({
    required this.approved,
    required this.baseTint,
    required this.bgOpacity,
    required this.borderOpacity,
    required this.iconTextOpacity,
    required this.label,
    required this.iconData,
    required this.compact,
    required this.dense,
    this.verticalPadding,
    this.horizontalPadding,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = approved
        ? Colors.green.shade900.withValues(alpha: iconTextOpacity)
        : Colors.grey.shade800.withValues(alpha: iconTextOpacity);

    // Paddings e tamanhos mais baixos quando "dense"
    final vPad = verticalPadding ?? (dense ? 4.0 : 8.0);
    final hPad = horizontalPadding ?? (dense ? (compact ? 8.0 : 10.0) : (compact ? 10.0 : 14.0));
    final ico = iconSize ?? (dense ? 18.0 : 22.0);
    final fontSize = dense ? 14.0 : 15.5;

    return AnimatedContainer(
      key: ValueKey<String>('${approved ? 'ok' : 'pend'}-${compact ? 'c' : 'f'}-${dense ? 'd' : 'n'}'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: dense ? 28 : 34), // <- trava altura mínima
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: baseTint.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: baseTint.withValues(alpha: borderOpacity), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: baseTint.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Icon(iconData, size: ico, color: fgColor)
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: fgColor, size: ico),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
