import 'package:flutter/material.dart';

class PagedColum<T> {
  final String title;
  final String Function(T item)? getter;
  final Widget Function(T item)? cellBuilder;
  final Widget Function(BuildContext context)? headerBuilder;
  final TextAlign textAlign;

  /// Largura real da coluna.
  final double? width;

  /// Limite opcional do conteúdo interno.
  final double? maxWidth;

  /// Define se a célula daquela linha ainda está carregando.
  ///
  /// Exemplo:
  /// loadingWhen: (contract) => !dfdByContractId.containsKey(contract.id)
  final bool Function(T item)? loadingWhen;

  /// Widget customizado para exibir enquanto a célula está carregando.
  ///
  /// Se não informar, usa o skeleton padrão da tabela.
  final Widget Function(BuildContext context, T item)? loadingBuilder;

  const PagedColum({
    required this.title,
    this.getter,
    this.cellBuilder,
    this.headerBuilder,
    this.textAlign = TextAlign.left,
    this.width,
    this.maxWidth,
    this.loadingWhen,
    this.loadingBuilder,
  });
}