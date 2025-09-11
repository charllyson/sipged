import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_dock.dart';

class PanelShell extends StatelessWidget {
  const PanelShell({
    super.key,
    required this.child,
    required this.maxHeight,
    required this.bg,
  });

  final Widget child;
  final double maxHeight;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      widthFactor: 1,
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E6E6E)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ToolDockState.kFlyoutInnerPadV,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
