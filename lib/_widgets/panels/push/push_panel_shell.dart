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

  @override
  Widget build(BuildContext context) {
    const headerHeight = 40.0;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6F8), // 🔥 cinza bem suave (melhor que F3F4F6)
                border: Border(
                  bottom: BorderSide(
                    width: 0.8,
                    color: Color(0xFFD6DAE1),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: Color(0xFF4B5563),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      tooltip: 'Fechar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      splashRadius: 16,
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
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