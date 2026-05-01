import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
class DrawerButtonChange extends StatelessWidget {
  const DrawerButtonChange({super.key});

  @override
  Widget build(BuildContext context) {
    const double barHeight = 56.0;
    const double buttonSize = 48.0;
    const EdgeInsets margin = EdgeInsets.symmetric(horizontal: 12.0);

    final safeTop = MediaQuery.of(context).padding.top;
    final computedTop = safeTop + (barHeight - buttonSize) / 2;

    return Positioned(
      top: computedTop,
      left: margin.left,
      child: Builder(
        builder: (ctx) {
          return CircleButtonChange(
            icon: Icons.menu,
            tooltip: 'Abrir menu',
            radius: buttonSize / 2,
            onPressed: () {
              final scaffold = Scaffold.maybeOf(ctx);

              if (scaffold != null) {
                scaffold.openDrawer();
              }
            },
          );
        },
      ),
    );
  }
}