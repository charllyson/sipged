import 'package:flutter/material.dart';

/// Botão flutuante que abre o Drawer, alinhado com uma "barra" de [barHeight]
/// logo abaixo do status bar (safeTop). Funciona no mobile e no web.
/// OBS: Use este widget **como filho de um Stack**.
class FloatButtonMenu extends StatelessWidget {
  /// Altura visual da sua barra “fake” (equivalente a AppBar). Default: 56.
  final double barHeight;

  /// Diâmetro do botão (usado para centralizar verticalmente).
  final double buttonSize;

  /// Lado da tela onde o botão ficará.
  final AlignmentGeometry sideAlignment; // Alignment.topLeft ou topRight

  /// Margem lateral (e opcionalmente extra no topo).
  final EdgeInsets margin;

  /// Elevação do botão (sombra).
  final double elevation;

  /// Ícone do botão.
  final IconData icon;

  const FloatButtonMenu({
    super.key,
    this.barHeight = 56.0,
    this.buttonSize = 48.0,
    this.sideAlignment = Alignment.topLeft,
    this.margin = const EdgeInsets.symmetric(horizontal: 12.0),
    this.elevation = 6.0,
    this.icon = Icons.menu,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    // centraliza o botão dentro da faixa da barra
    final computedTop = safeTop + (barHeight - buttonSize) / 2;

    final isRight = sideAlignment == Alignment.topRight;

    return Positioned(
      top: computedTop + margin.top,
      left: isRight ? null : margin.left,
      right: isRight ? margin.right : null,
      child: _Button(
        size: buttonSize,
        elevation: elevation,
        icon: icon,
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final double size;
  final double elevation;
  final IconData icon;

  const _Button({
    required this.size,
    required this.elevation,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(
      builder: (ctx) => Material(
        elevation: elevation,
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: InkResponse(
          onTap: () {
            final scaffold = Scaffold.maybeOf(ctx);
            if (scaffold != null) {
              scaffold.openDrawer();
            } else {
              debugPrint('FloatButtonMenu: Nenhum Scaffold com drawer encontrado.');
            }
          },
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            child: Icon(
              icon,
              size: 22,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
