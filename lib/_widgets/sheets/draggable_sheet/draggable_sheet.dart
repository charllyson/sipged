import 'package:flutter/material.dart';

/// Modelo genérico de “folha” para ser usado dentro de um DraggableScrollableSheet.
///
/// Suporta DOIS modos de uso:
///  - MODO LISTA: [itemCount] + [itemBuilder]
///  - MODO BODY:  [body] (qualquer widget)
///
/// Use **apenas um dos modos** por vez.
class BaseDraggableSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLoading;

  /// Controller fornecido pelo DraggableScrollableSheet
  final ScrollController scrollController;

  /// ===== MODO LISTA =====
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  /// ===== MODO BODY (FORM / CONTEÚDO LIVRE) =====
  final Widget? body;

  /// Callback de fechar (ex: Navigator.pop)
  final VoidCallback? onClose;

  /// Área opcional de rodapé (botões, input, etc.)
  final Widget? bottomArea;

  /// Personalização básica de cores (opcional)
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? headerIconColor;
  final Color? titleColor;
  final Color? footerBackgroundColor;

  const BaseDraggableSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.isLoading,
    required this.scrollController,
    this.itemCount,
    this.itemBuilder,
    this.body,
    this.onClose,
    this.bottomArea,
    this.backgroundColor,
    this.borderColor,
    this.headerIconColor,
    this.titleColor,
    this.footerBackgroundColor,
  }) : assert(
  // ou lista OU body
  (itemCount != null && itemBuilder != null && body == null) ||
      (itemCount == null && itemBuilder == null && body != null),
  'Use EITHER list mode (itemCount + itemBuilder) OR body mode (body), not both.',
  );

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.grey[900]!;
    final bColor = borderColor ?? Colors.blueAccent.withValues(alpha: 0.4);
    final iconColor = headerIconColor ?? Colors.lightBlueAccent;
    final tColor = titleColor ?? Colors.white;
    final footerColor = footerBackgroundColor ?? Colors.black.withValues(alpha: 0.7);

    // Decide o conteúdo scrollável conforme o modo
    final Widget scrollChild;
    if (body != null) {
      // MODO BODY (form/conteúdo livre)
      scrollChild = SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: body!,
      );
    } else {
      // MODO LISTA
      scrollChild = ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: itemCount!,
        itemBuilder: itemBuilder!,
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: bColor,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: tColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: tColor.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Barra de progresso
          AnimatedOpacity(
            opacity: isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 2,
              child: isLoading
                  ? const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Colors.lightBlueAccent,
              )
                  : const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 4),

          // Área scrollável (lista ou body)
          Expanded(child: scrollChild),

          // Rodapé opcional
          if (bottomArea != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: footerColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: bottomArea,
            ),
        ],
      ),
    );
  }
}
