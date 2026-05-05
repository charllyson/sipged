import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScheduleCivilBoard extends StatelessWidget {
  const ScheduleCivilBoard({
    super.key,
    this.boardRadius = 0,             // agora é usado de fato
    this.boardMarginV = 28,
    this.innerPad = 2,                // margem externa do card
    this.contentPadding = 0,          // padding interno do card
    this.widthFrac = 0.86,
    this.maxBoardWidth = 1400,
    this.showBoard = true,

    // 🆕 personalização
    this.boardColor = Colors.white,
    this.contentColor = const Color(0xFFFAFAFA),
    this.showShadow = true,
    this.customShadows,

    // 🆕 dimensionamento pelo conteúdo (ex.: tamanho do DXF renderizado)
    this.contentSize,
    this.lockToContentSize = true,

    // 🆕 controle de clipping
    this.clipBehavior = Clip.hardEdge,

    required this.onInsetsReady,
    required this.childBuilder,
  });

  /// Raio dos cantos do “card”
  final double boardRadius;

  /// Margem vertical superior e inferior do card
  final double boardMarginV;

  /// Margem entre as bordas do card e o viewport (fora do card)
  final double innerPad;

  /// Padding interno entre a “borda branca” e o conteúdo
  final double contentPadding;

  /// Fator de largura do card em relação ao viewport (fallback)
  final double widthFrac;

  /// Largura máxima do card
  final double maxBoardWidth;

  /// Se `false`, não desenha o card; o conteúdo ocupa a tela inteira
  final bool showBoard;

  /// 🆕 Cor do card
  final Color boardColor;

  /// 🆕 Cor do fundo onde o conteúdo é desenhado
  final Color contentColor;

  /// 🆕 Exibir sombras no card
  final bool showShadow;

  /// 🆕 Lista de sombras customizadas (se não nula, substitui as padrões)
  final List<BoxShadow>? customShadows;

  /// 🆕 Tamanho “intrínseco” do conteúdo (ex.: `Size(renderResult.w, renderResult.h)`)
  /// Se informado, o board tenta casar com esse tamanho (respeitando limites).
  final Size? contentSize;

  /// 🆕 Quando `true` e `contentSize` informado, tenta travar o card ao tamanho do conteúdo
  /// (limitado pelo viewport). Quando `false`, usa `widthFrac` e ajusta a altura pelo aspecto.
  final bool lockToContentSize;

  /// 🆕 Controle de clipping do container do conteúdo
  final Clip clipBehavior;

  /// Callback com os insets totais do conteúdo (para ajudar nas transforms)
  final void Function(EdgeInsets totalInset, Size viewport) onInsetsReady;

  /// Constrói o filho usando os insets e o viewport calculados
  final Widget Function(BuildContext context, EdgeInsets totalInset, Size viewport) childBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final viewport = Size(cons.maxWidth, cons.maxHeight);

        // Sem board: usa a área toda
        if (!showBoard) {
          final totalInset = EdgeInsets.zero;
          WidgetsBinding.instance.addPostFrameCallback((_) => onInsetsReady(totalInset, viewport));
          return Padding(
            padding: EdgeInsets.all(contentPadding),
            child: childBuilder(context, totalInset, viewport),
          );
        }

        // =========================
        // Cálculo do retângulo do card
        // =========================
        double boardLeft, boardRight, boardTop, boardBottom;

        if (contentSize != null) {
          // Temos tamanho do conteúdo → dimensiona o card para “bater” com o conteúdo,
          // respeitando margens verticais e limites do viewport.
          final maxW = viewport.width;
          final maxH = viewport.height;

          // Espaço útil vertical descontando a margem do card
          final usableH = (maxH - 2 * boardMarginV).clamp(0.0, maxH);
          final usableW = maxW;

          // Escala para caber o conteúdo dentro da área útil
          final s = _fitScale(
            content: contentSize!,
            bounds: Size(usableW, usableH),
          );

          // Tamanho desejado do card
          double cardW = contentSize!.width * s + innerPad * 2;
          double cardH = contentSize!.height * s + innerPad * 2;

          // Limites finais por viewport
          cardW = cardW.clamp(0.0, maxW);
          cardH = cardH.clamp(0.0, maxH - 2 * boardMarginV);

          if (!lockToContentSize) {
            // fallback: usa widthFrac para a LARGURA, preservando aspecto do conteúdo para ALTURA
            final wFrac = math.min(viewport.width * widthFrac, maxBoardWidth);
            final gutter = (((viewport.width - wFrac) / 2).clamp(0.0, double.infinity)).toDouble();
            boardLeft = gutter;
            boardRight = gutter;
            boardTop = boardMarginV;
            boardBottom = boardMarginV;

            // altura ajustada pelo aspect do conteúdo (limitada ao espaço)
            final innerW = wFrac - innerPad * 2;
            final aspect = contentSize!.width / contentSize!.height;
            double innerH = innerW / (aspect == 0 ? 1 : aspect);
            final maxInnerH = (viewport.height - 2 * boardMarginV - innerPad * 2).clamp(0.0, viewport.height);
            innerH = innerH.clamp(0.0, maxInnerH);

            // A altura externa (inclui innerPad*2)
            final outerH = innerH + innerPad * 2;
            final centerY = viewport.height / 2;
            boardTop = (centerY - outerH / 2).clamp(boardMarginV, viewport.height - boardMarginV - outerH);
            boardBottom = viewport.height - boardTop - outerH;
          } else {
            // Centraliza o card travado ao conteúdo (limitado)
            final outerW = cardW;
            final outerH = cardH;

            final gutterX = ((viewport.width - outerW) / 2).clamp(0.0, double.infinity);
            final gutterY = ((viewport.height - outerH) / 2).clamp(boardMarginV, double.infinity);

            boardLeft = gutterX;
            boardRight = gutterX;
            boardTop = gutterY;
            boardBottom = (viewport.height - outerH - gutterY).clamp(boardMarginV, double.infinity);
          }
        } else {
          // Sem contentSize → comportamento antigo por largura fracionada
          final boardWidth = math.min(viewport.width * widthFrac, maxBoardWidth);
          final gutter = (((viewport.width - boardWidth) / 2).clamp(0.0, double.infinity)).toDouble();

          boardLeft = gutter;
          boardRight = gutter;
          boardTop = boardMarginV;
          boardBottom = boardMarginV;
        }

        final totalInset = EdgeInsets.fromLTRB(
          boardLeft + innerPad,
          boardTop + innerPad,
          boardRight + innerPad,
          boardBottom + innerPad,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) => onInsetsReady(totalInset, viewport));

        final shadows = showShadow
            ? (customShadows ??
            const [
              BoxShadow(color: Color(0x33000000), blurRadius: 18, spreadRadius: 2, offset: Offset(0, 10)),
              BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
            ])
            : const <BoxShadow>[];

        return Stack(
          children: [
            // Card (prancheta)
            Positioned(
              left: boardLeft,
              right: boardRight,
              top: boardTop,
              bottom: boardBottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: boardColor,
                  borderRadius: BorderRadius.circular(boardRadius),
                  boxShadow: shadows,
                ),
              ),
            ),

            // Conteúdo clipado ao card
            Padding(
              padding: totalInset,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(boardRadius > 0 ? math.max(0, boardRadius - innerPad) : 0),
                clipBehavior: clipBehavior,
                child: ColoredBox(
                  color: contentColor,
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: childBuilder(context, totalInset, viewport),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Escala que faz `content` caber dentro de `bounds` preservando proporção.
  static double _fitScale({required Size content, required Size bounds}) {
    if (content.width <= 0 || content.height <= 0) return 1.0;
    final sx = bounds.width / content.width;
    final sy = bounds.height / content.height;
    return math.max(0.0, math.min(sx, sy));
  }
}
