import 'dart:ui';
import 'package:flutter/material.dart';

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
              ? _OverlayChrome(
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

class _OverlayChrome extends StatelessWidget {
  final String? message;
  final String? details;
  final double? progress;
  final IconData? icon;
  final Color barrierColor;
  final bool keepAppBarUndimmed;
  final Duration animationDuration;

  const _OverlayChrome({
    super.key,
    required this.message,
    required this.details,
    required this.progress,
    required this.icon,
    required this.barrierColor,
    required this.keepAppBarUndimmed,
    required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = keepAppBarUndimmed
        ? (Scaffold.maybeOf(context)?.appBarMaxHeight ?? 0)
        : 0.0;

    // Tons adaptativos (claro/escuro)
    final isDark = theme.brightness == Brightness.dark;
    final glassFill = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.10);
    final barrier = barrierColor.withOpacity(0.12); // bem leve
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.25 : 0.10),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];

    return Stack(
      children: [
        // Bloqueio de interação (ModalBarrier suave, não dispensável)
        Positioned.fill(
          child: ModalBarrier(
            color: barrier,
            dismissible: false,
          ),
        ),

        // Blur suave de fundo, sem “apertar” a AppBar (opcional)
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: TweenAnimationBuilder<double>(
              duration: animationDuration,
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, t, _) {
                // Blur pequeno e progressivo para não “distorcer” a UI
                final sigma = lerpDouble(0, 3.5, t)!; // antes: 6.0
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),

        // AbsorbPointer extra por garantia (além do ModalBarrier)
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: SafeArea(
              // Card central com “glass”
              child: Align(
                alignment: Alignment.center,
                child: _AnimatedScaleFade(
                  duration: animationDuration,
                  child: _GlassCard(
                    icon: icon ?? Icons.sync,
                    message: message ?? 'Processando...',
                    details: details,
                    progress: progress,
                    glassFill: glassFill,
                    glassBorder: glassBorder,
                    shadows: cardShadow,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? details;
  final double? progress;

  final Color glassFill;
  final Color glassBorder;
  final List<BoxShadow> shadows;

  const _GlassCard({
    required this.icon,
    required this.message,
    required this.details,
    required this.progress,
    required this.glassFill,
    required this.glassBorder,
    required this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final indicator = (progress == null)
        ? const SizedBox(
      width: 22, // menor, mais delicado
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    )
        : SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress!.clamp(0.0, 1.0)),
          ),
          const SizedBox(height: 8),
          Text('${(progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
          boxShadow: shadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (details != null) ...[
                const SizedBox(height: 6),
                Text(
                  details!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              indicator,
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedScaleFade extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const _AnimatedScaleFade({
    required this.child,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.96, end: 1),
      builder: (context, scale, _) {
        return AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOut,
          opacity: 1,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}
