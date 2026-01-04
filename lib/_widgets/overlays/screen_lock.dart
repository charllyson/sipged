import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:siged/_widgets/overlays/overlay_screen.dart';

/// Bloqueia interações da tela inteira enquanto [locked] for true,
/// com visual leve: blur suave, glass card translúcido e animações discretas.
class ScreenLock extends StatefulWidget {
  final bool locked;
  final Widget child;

  /// Mensagem principal (ex.: "Salvando DFD...")
  final String? message;

  /// Mensagem secundária opcional (ex.: "Aguarde, aplicando alterações")
  final String? details;

  /// Progresso opcional (0..1). Se nulo, mostra indeterminado.
  final double? progress;

  /// Ícone opcional. Padrão: Icons.sync
  final IconData? icon;

  /// Cor da cortina/barreira (alpha aplicado internamente)
  final Color barrierColor;

  /// Se true, mantém a AppBar sem blur (apenas estética; interação segue bloqueada)
  final bool keepAppBarUndimmed;

  /// Duração das animações de entrada/saída.
  final Duration animationDuration;

  const ScreenLock({
    super.key,
    required this.locked,
    required this.child,
    this.message,
    this.details,
    this.progress,
    this.icon,
    this.barrierColor = const Color(0xFF000000),
    this.keepAppBarUndimmed = true,
    this.animationDuration = const Duration(milliseconds: 180),
  });

  @override
  State<ScreenLock> createState() => _ScreenLockState();
}

class _ScreenLockState extends State<ScreenLock> with SingleTickerProviderStateMixin {
  bool _wasLocked = false;

  @override
  void didUpdateWidget(covariant ScreenLock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !_wasLocked) {
      // Evita digitação “perdida”
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _wasLocked = widget.locked;
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;

    return Stack(
      children: [
        widget.child,
        // Usamos AnimatedSwitcher p/ transições suaves no overlay
        AnimatedSwitcher(
          duration: widget.animationDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: locked
              ? OverlayScreen(
            key: const ValueKey('lock-on'),
            message: widget.message,
            details: widget.details,
            progress: widget.progress,
            icon: widget.icon,
            barrierColor: widget.barrierColor,
            keepAppBarUndimmed: widget.keepAppBarUndimmed,
            animationDuration: widget.animationDuration,
          )
              : const SizedBox.shrink(key: ValueKey('lock-off')),
        ),
      ],
    );
  }
}
