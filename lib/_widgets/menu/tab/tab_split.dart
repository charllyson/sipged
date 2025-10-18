import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// Helper opcional: layout "form no topo + tabela embaixo" dentro do Scaffold.
/// Uso:
/// ContractSplitTopAndTable(
///   topChild: SeuFormWidget(),
///   bottomChild: SuaTabelaWidget(),
///   maxTopHeight: 430,
/// )
/// ----------------------------------------------------------------------------
class TabSplit extends StatelessWidget {
  const TabSplit({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.maxTopHeight = 430.0,
    this.scrollPhysics = const ClampingScrollPhysics(),
    this.gap = const SizedBox(height: 8),
    this.topPadding = const EdgeInsets.all(12),
    this.bottomPadding = const EdgeInsets.only(bottom: 8.0),
    this.constrainTop = true,
    this.wrapTopInScrollView = true,
  });

  /// Conteúdo da parte superior (normalmente um formulário)
  final Widget topChild;

  /// Conteúdo inferior (tabela/lista principal)
  final Widget bottomChild;

  /// Altura máxima do topo; se [constrainTop]=false, ignora este limite.
  final double maxTopHeight;

  /// Física do scroll do container inteiro
  final ScrollPhysics scrollPhysics;

  /// Espaço entre topo e bottom
  final Widget gap;

  /// Padding aplicado ao topo
  final EdgeInsetsGeometry topPadding;

  /// Padding aplicado ao bottom
  final EdgeInsetsGeometry bottomPadding;

  /// Se true, limita a altura máxima do topo
  final bool constrainTop;

  /// Se true, envolve o topo em SingleChildScrollView (útil p/ forms longos)
  final bool wrapTopInScrollView;

  @override
  Widget build(BuildContext context) {
    final Widget topWrapped = Padding(
      padding: topPadding,
      child: wrapTopInScrollView ? SingleChildScrollView(child: topChild) : topChild,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          physics: scrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: constrainTop
                    ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxTopHeight),
                  child: topWrapped,
                )
                    : topWrapped,
              ),
            ),
            SliverToBoxAdapter(child: gap),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Padding(
                padding: bottomPadding,
                child: bottomChild,
              ),
            ),
          ],
        );
      },
    );
  }
}
