import 'package:flutter/material.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:siged/_widgets/menu/upBar/tight.dart';

class UpBar extends StatelessWidget implements PreferredSizeWidget {
  // Alturas das linhas
  final double titleHeight;
  final double subtitleHeight;

  // Conteúdos
  final List<Widget>? titleWidgets;     // linha 1 (sem wrap)
  final List<Widget>? subtitleWidgets;  // linha 2 (sem wrap)

  // Layout/itens fixos
  final Widget? leading;
  final List<Widget> actions;
  final bool showPhotoMenu;
  final Widget? photoMenu;

  // Espaçamentos
  final double itemsSpacing;
  final double sideGap;

  // Estilo de fundo
  final BoxDecoration? decoration;
  final List<Color> backgroundBar;

  // Linha branca inferior
  final bool showBottomBorder;
  final Color bottomBorderColor;
  final double bottomBorderWidth;

  // Safe area
  final bool includeSafeTop;
  final double safeTopFallback;

  const UpBar({
    super.key,
    this.titleHeight = 56,
    this.subtitleHeight = 30,
    this.titleWidgets,
    this.subtitleWidgets = const [],
    this.leading,
    this.actions = const [],
    this.showPhotoMenu = true,
    this.photoMenu,
    this.itemsSpacing = 12,
    this.sideGap = 8,
    this.decoration,
    this.backgroundBar = const [Color(0xFF1B2031), Color(0xFF1B2039)],
    this.showBottomBorder = true,
    this.bottomBorderColor = Colors.white,
    this.bottomBorderWidth = 1.0,
    this.includeSafeTop = true,
    this.safeTopFallback = 0,
  });

  double totalHeight(BuildContext context) {
    final safeTop = includeSafeTop ? MediaQuery.of(context).padding.top : 0.0;
    final sub = (subtitleWidgets?.isNotEmpty ?? false) ? subtitleHeight : 0.0;
    return safeTop + titleHeight + sub;
  }

  @override
  Size get preferredSize {
    final sub = (subtitleWidgets?.isNotEmpty ?? false) ? subtitleHeight : 0.0;
    return Size.fromHeight(safeTopFallback + titleHeight + sub);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = includeSafeTop ? MediaQuery.of(context).padding.top : 0.0;

    // Tamanhos “reservados” para os lados
    const double kIconSlot = 40.0; // largura “bruta” de um ícone
    const double kGapAfterLeading = 34.0;

    final double leadingW =
    leading != null ? kIconSlot + kGapAfterLeading : sideGap;

    final double avatarW = showPhotoMenu ? kIconSlot + 8.0 : 0.0;
    final double actionsW =
    actions.isNotEmpty ? actions.length * (kIconSlot + 12.0) : 0.0;

    final double rightW = avatarW + actionsW + sideGap;

    // 👉 AGORA: padding assimétrico
    final double leftPad = leadingW;
    final double rightPad = rightW;

    final bg = decoration ??
        BoxDecoration(
          border: showBottomBorder
              ? Border(
            bottom: BorderSide(
              color: bottomBorderColor,
              width: bottomBorderWidth,
            ),
          )
              : null,
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
                  // Centro — título (usa todo o espaço restante, com scroll horizontal se precisar)
                  Padding(
                    padding:
                    EdgeInsets.only(left: leftPad, right: rightPad),
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _withSpacing(
                                  titleWidgets ?? const [],
                                  itemsSpacing,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Esquerda — leading
                  if (leading != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tight(child: leading!),
                    ),

                  // Direita — actions + foto
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
                        if (showPhotoMenu)
                          Tight(child: photoMenu ?? const PopUpPhotoMenu()),
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
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 2,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    // 🔥 NÃO usa mais OneLineRow aqui para não dar FittedBox/shrink
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _withSpacing(
                          subtitleWidgets ?? const [],
                          itemsSpacing,
                        ),
                      ),
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
