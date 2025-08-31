import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/popUpMenu/pup_up_photo_menu.dart';
import 'package:siged/_widgets/registers/register_class.dart';
import 'package:siged/_widgets/toast/show_stacked_toast.dart';

class UpBar extends StatelessWidget implements PreferredSizeWidget {
  // Alturas das linhas
  final double titleHeight;
  final double subtitleHeight;

  // Conteúdos
  final List<Widget>? titleWidgets;     // linha 1 (sem wrap)
  final List<Widget>? subtitleWidgets;  // linha 2 (sem wrap)

  // Layout/itens fixos
  final Widget? leading;
  final List<Widget> actions;           // ícones pequenos à direita
  final bool showPhotoMenu;
  final Widget? photoMenu;

  // Insights (botão que abre/fecha seu painel de gráficos)
  final bool showInsightsButton;
  final VoidCallback? onInsightsTap;
  final bool insightsOpen;

  // Espaçamentos
  final double itemsSpacing;
  final double sideGap;

  // Estilo de fundo
  final BoxDecoration? decoration;
  final List<Color> backgroundBar;

  // NOVO: controla se a barra deve reservar o espaço do status bar/notch
  final bool includeSafeTop;

  // NOVO: fallback para preferredSize (caso use como appBar sem contexto).
  // No seu caso (sem AppBar), ignore.
  final double safeTopFallback;

  const UpBar({
    super.key,
    this.titleHeight = 56,                // altura visual da "faixa"
    this.subtitleHeight = 30,
    this.titleWidgets,
    this.subtitleWidgets = const [],
    this.leading,
    this.actions = const [],
    this.showPhotoMenu = true,
    this.photoMenu,
    this.showInsightsButton = true,
    this.onInsightsTap,
    this.insightsOpen = false,
    this.itemsSpacing = 12,
    this.sideGap = 8,
    this.decoration,
    this.backgroundBar = const [Color(0xFF1B2031), Color(0xFF1B2039)],
    this.includeSafeTop = true,
    this.safeTopFallback = 0,
  });

  /// Altura total calculada (safeTop + título + opcional subtítulo)
  double totalHeight(BuildContext context) {
    final safeTop = includeSafeTop ? MediaQuery.of(context).padding.top : 0.0;
    final sub = (subtitleWidgets?.isNotEmpty ?? false) ? subtitleHeight : 0.0;
    return safeTop + titleHeight + sub;
  }

  @override
  Size get preferredSize {
    // preferredSize não tem acesso ao context.
    // Usamos o fallback caso alguém use como AppBar.
    final sub = (subtitleWidgets?.isNotEmpty ?? false) ? subtitleHeight : 0.0;
    return Size.fromHeight(safeTopFallback + titleHeight + sub);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = includeSafeTop ? MediaQuery.of(context).padding.top : 0.0;

    // Larguras “apertadas” para reservar espaço aos lados
    final leadingW  = leading != null ? 40.0 + 8.0 : sideGap; // botão/menu
    final avatarW   = showPhotoMenu ? 40.0 + 8.0 : 0.0;

    // cada action ~40+12; insights também conta
    final actionsW  = actions.isNotEmpty ? actions.length * (40.0 + 12.0) : 0.0;
    final insightsW = showInsightsButton ? (40.0 + 12.0) : 0.0;

    final rightW    = avatarW + actionsW + insightsW + sideGap;

    // padding simétrico para o centro não ficar por baixo dos lados
    final sidePad = math.max(leadingW, rightW);

    final bg = decoration ??
        BoxDecoration(
          border: const Border(bottom: BorderSide(color: Colors.white, width: 1)),
          gradient: LinearGradient(
            colors: backgroundBar,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: bg,
        // 👉 Reservamos aqui o safeTop
        padding: EdgeInsets.only(top: safeTop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- Linha 1: título ----------------
            SizedBox(
              height: titleHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centro — título
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sidePad),
                    child: _OneLineRow(
                      textColor: Colors.white,
                      children: _withSpacing(titleWidgets ?? const [], itemsSpacing),
                    ),
                  ),

                  // Esquerda — leading
                  if (leading != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _Tight(child: leading!),
                    ),

                  // Direita — actions + botão insights + foto
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (actions.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _withSpacing(actions, 12),
                          ),
                        if (actions.isNotEmpty) const SizedBox(width: 8),

                        if (showInsightsButton)
                          _Tight(
                            child: IconButton(
                              icon: const Icon(Icons.insights_rounded),
                              tooltip: insightsOpen ? 'Fechar gráficos' : 'Abrir gráficos',
                              onPressed: onInsightsTap,
                              color: Colors.white,
                            ),
                          ),

                        if (showInsightsButton) const SizedBox(width: 8),

                        if (showPhotoMenu)
                          _Tight(child: photoMenu ?? const PopUpPhotoMenu()),
                        SizedBox(width: sideGap),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Linha 2: subtítulo ----------------
            if (subtitleWidgets!.isNotEmpty)
              SizedBox(
                height: subtitleHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sidePad),
                  child: Align(
                    alignment: Alignment.center,
                    child: _OneLineRow(
                      textColor: Colors.white,
                      children: _withSpacing(subtitleWidgets ?? const [], itemsSpacing),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double spacing) {
    if (items.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) out.add(SizedBox(width: spacing));
    }
    return out;
  }
}

/// Uma linha única que NUNCA faz wrap nem scroll:
class _OneLineRow extends StatelessWidget {
  final List<Widget> children;
  final Color? textColor;

  const _OneLineRow({required this.children, this.textColor});

  @override
  Widget build(BuildContext context) {
    final row = DefaultTextStyle.merge(
      style: TextStyle(color: textColor),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
    return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center, child: row);
  }
}

/// Remove padding/constraints 48x48 padrão dos IconButtons
class _Tight extends StatelessWidget {
  final Widget child;
  const _Tight({required this.child});

  @override
  Widget build(BuildContext context) {
    if (child is IconButton) {
      final b = child as IconButton;
      return IconButton(
        onPressed: b.onPressed,
        icon: b.icon,
        color: b.color,
        iconSize: b.iconSize,
        tooltip: b.tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(), // remove 48x48 padrão
      );
    }
    return child;
  }
}

/// ======================= TOAST HELPERS =======================
void showStackedToast(BuildContext context, Registro registro, int index) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => StackedToastNotification(
      registro: registro,
      index: index,
      tipoAlteracao: getTipoAlteracao(
        createdAt: registro.original?.createdAt,
        updatedAt: registro.original?.updatedAt,
      ),
    ),
  );
  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 4)).then((_) => overlayEntry.remove());
}

String getTipoAlteracao({DateTime? createdAt, DateTime? updatedAt}) {
  if (updatedAt != null && createdAt != null && updatedAt.isAfter(createdAt)) {
    return 'Atualização';
  }
  return 'Criação';
}
