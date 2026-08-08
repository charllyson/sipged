import 'package:flutter/material.dart';

class PushPanelShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onClose;
  final bool highlightResizeEdge;

  const PushPanelShell({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.highlightResizeEdge = false,
  });

  // Mesmo padrão visual do cabeçalho dos painéis de docking
  // (ver DockPanelHeader) — altura, cores, espaçamentos e tipografia
  // idênticos, para que "Área de trabalho", "Catálogo", "Ferramentas" e
  // "Atributos" fiquem visualmente consistentes.
  @override
  Widget build(BuildContext context) {
    const headerHeight = 30.0;

    const headerColor = Color(0xFFF2F3F5);
    final borderColor = Colors.black.withValues(alpha: 0.08);
    final textColor = Colors.black.withValues(alpha: 0.85);
    final buttonColor = Colors.black54;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              width: 1.0,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 3),
                  Icon(
                    icon,
                    size: 16,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: buttonColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}