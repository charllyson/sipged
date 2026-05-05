import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';

import 'excel_table_widget.dart';
import 'excel_utils.dart';
import 'progress_import_dialog.dart';
import 'tipo_dado_enum.dart';

class ExcelPreviewDialog extends StatefulWidget {
  const ExcelPreviewDialog({
    super.key,
    required this.jsonData,
    required this.path,
    this.onFinished,
  });

  final List<Map<String, dynamic>> jsonData;
  final String path;
  final void Function()? onFinished;

  @override
  State<ExcelPreviewDialog> createState() => _ExcelPreviewDialogState();
}

class _ExcelPreviewDialogState extends State<ExcelPreviewDialog> {
  late Map<int, bool> _linhasSelecionadas;
  late Map<String, bool> _colunasSelecionadas;
  late Map<String, TipoDado> _tiposPorCampo;
  late List<String> _colunas;

  int _paginaAtual = 0;
  final int _linhasPorPagina = 100;

  final ScrollController _vOriginal = ScrollController();
  final ScrollController _hOriginal = ScrollController();
  final ScrollController _vConvertido = ScrollController();
  final ScrollController _hConvertido = ScrollController();

  bool _importDialogLoopStarted = false;

  @override
  void initState() {
    super.initState();

    _colunas = widget.jsonData.first.keys.toList();

    _linhasSelecionadas = <int, bool>{
      for (int i = 0; i < widget.jsonData.length; i++) i: true,
    };

    _colunasSelecionadas = <String, bool>{
      for (final col in _colunas) col: true,
    };

    _tiposPorCampo = <String, TipoDado>{
      for (final col in _colunas) col: detectarTipo(widget.jsonData, col),
    };
  }

  @override
  void dispose() {
    _vOriginal.dispose();
    _hOriginal.dispose();
    _vConvertido.dispose();
    _hConvertido.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final totalPaginas = (widget.jsonData.length / _linhasPorPagina).ceil();
    final size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: WindowDialog(
        title: 'Pré-visualização da Importação',
        width: size.width * 0.85,
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: size.height * 0.70,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    tabs: [
                      Tab(text: '📄 Original'),
                      Tab(text: '🧪 Convertido'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTabelaOriginal(),
                        _buildTabelaConvertida(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _paginaAtual > 0
                      ? () => setState(() => _paginaAtual--)
                      : null,
                  child: const Text('Anterior'),
                ),
                const SizedBox(width: 8),
                Text('Página ${_paginaAtual + 1} de $totalPaginas'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed:
                  (_paginaAtual + 1) * _linhasPorPagina < widget.jsonData.length
                      ? () => setState(() => _paginaAtual++)
                      : null,
                  child: const Text('Próxima'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _confirmarImportacao,
                  child: const Text('Confirmar e Importar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaOriginal() {
    final inicio = _paginaAtual * _linhasPorPagina;
    final fim = (_paginaAtual + 1) * _linhasPorPagina;

    final previewLinhas = widget.jsonData.sublist(
      inicio,
      fim > widget.jsonData.length ? widget.jsonData.length : fim,
    );

    return Scrollbar(
      controller: _vOriginal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vOriginal,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _hOriginal,
          notificationPredicate: (_) => false,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _hOriginal,
            scrollDirection: Axis.horizontal,
            child: ExcelTableWidget(
              previewLinhas: previewLinhas,
              colunas: _colunas,
              colunasSelecionadas: _colunasSelecionadas,
              tiposPorCampo: _tiposPorCampo,
              linhasSelecionadas: _linhasSelecionadas,
              onSelectLinha: (indexGlobal, selected) {
                setState(() {
                  _linhasSelecionadas[indexGlobal] = selected ?? false;
                });
              },
              onToggleColuna: (coluna, selected) {
                setState(() {
                  _colunasSelecionadas[coluna] = selected ?? false;
                });
              },
              onChangeTipo: (coluna, tipo) {
                setState(() {
                  _tiposPorCampo[coluna] = tipo;
                });
              },
              paginaAtual: _paginaAtual,
              linhasPorPagina: _linhasPorPagina,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabelaConvertida() {
    final inicio = _paginaAtual * _linhasPorPagina;
    final fim = (_paginaAtual + 1) * _linhasPorPagina;

    final linhasPreview = widget.jsonData.sublist(
      inicio,
      fim > widget.jsonData.length ? widget.jsonData.length : fim,
    );

    final linhasConvertidas = linhasPreview.mapIndexed((i, linha) {
      final Map<String, dynamic> linhaConvertida = <String, dynamic>{};

      for (final col in _colunasSelecionadas.keys) {
        if (_colunasSelecionadas[col] != true) continue;

        final valor = linha[col];
        final tipo = _tiposPorCampo[col] ?? TipoDado.string;
        final convertido = converterValorPorTipo(valor, tipo);

        linhaConvertida[col] =
        convertido is DateTime ? convertido.toIso8601String() : convertido;
      }

      return linhaConvertida;
    }).toList();

    return Scrollbar(
      controller: _vConvertido,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vConvertido,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _hConvertido,
          notificationPredicate: (_) => false,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _hConvertido,
            scrollDirection: Axis.horizontal,
            child: ExcelTableWidget(
              previewLinhas: linhasConvertidas,
              colunas: _colunas,
              colunasSelecionadas: _colunasSelecionadas,
              tiposPorCampo: _tiposPorCampo,
              linhasSelecionadas: _linhasSelecionadas,
              onSelectLinha: (indexGlobal, selected) {
                setState(() {
                  _linhasSelecionadas[indexGlobal] = selected ?? false;
                });
              },
              onToggleColuna: (coluna, selected) {
                setState(() {
                  _colunasSelecionadas[coluna] = selected ?? false;
                });
              },
              onChangeTipo: (coluna, tipo) {
                setState(() {
                  _tiposPorCampo[coluna] = tipo;
                });
              },
              paginaAtual: _paginaAtual,
              linhasPorPagina: _linhasPorPagina,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarImportacao() async {
    final ref = FirebaseFirestore.instance
        .collection('trafficInfractions')
        .doc('lJSc788Ot4B64uVTK8c1')
        .collection(widget.path);

    final total = _linhasSelecionadas.entries.where((e) => e.value).length;

    final progress = ValueNotifier<int>(0);
    _importDialogLoopStarted = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        if (!_importDialogLoopStarted) {
          _importDialogLoopStarted = true;

          Future(() async {
            int count = 0;

            try {
              for (int i = 0; i < widget.jsonData.length; i++) {
                if (!(_linhasSelecionadas[i] ?? false)) continue;

                final linha = widget.jsonData[i];
                final Map<String, dynamic> dadosFiltrados = <String, dynamic>{};

                for (final campo in _colunasSelecionadas.keys) {
                  if (_colunasSelecionadas[campo] != true) continue;

                  final valor = linha[campo];
                  final tipo = _tiposPorCampo[campo] ?? TipoDado.string;
                  final convertido = converterValorPorTipo(valor, tipo);

                  dadosFiltrados[campo] = convertido;
                }

                await ref.add(dadosFiltrados);

                count++;
                progress.value = count;
              }

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }

              if (mounted) {
                Navigator.of(context).pop();
              }

              widget.onFinished?.call();
            } catch (e) {
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }

              if (mounted) {
                Navigator.of(context).pop();
              }

            }
          });
        }

        return ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, current, _) {
            return ProgressImportDialog(
              total: total,
              current: current,
            );
          },
        );
      },
    );

    progress.dispose();
  }
}