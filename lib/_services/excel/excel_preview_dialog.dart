import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

// seus helpers
import 'excel_table_widget.dart';
import 'tipo_dado_enum.dart';
import 'excel_utils.dart';
import 'progress_import_dialog.dart';

// ✅ notificações ricas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ExcelPreviewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> jsonData;
  final String path;
  final void Function()? onFinished;

  const ExcelPreviewDialog({
    super.key,
    required this.jsonData,
    required this.path,
    this.onFinished,
  });

  @override
  State<ExcelPreviewDialog> createState() => _ExcelPreviewDialogState();
}

class _ExcelPreviewDialogState extends State<ExcelPreviewDialog> {
  // seleção
  late Map<int, bool> _linhasSelecionadas;
  late Map<String, bool> _colunasSelecionadas;
  late Map<String, TipoDado> _tiposPorCampo;
  late List<String> _colunas;

  // paginação
  int _paginaAtual = 0;
  final int _linhasPorPagina = 100;

  // scrollbars corrigidos
  final ScrollController _vOriginal = ScrollController();
  final ScrollController _hOriginal = ScrollController();
  final ScrollController _vConvertido = ScrollController();
  final ScrollController _hConvertido = ScrollController();

  // estado
  bool _importDialogLoopStarted = false; // garante único disparo

  @override
  void initState() {
    super.initState();

    _colunas = widget.jsonData.first.keys.toList();

    _linhasSelecionadas = {
      for (int i = 0; i < widget.jsonData.length; i++) i: true
    };

    _colunasSelecionadas = {
      for (var col in _colunas) col: true
    };

    _tiposPorCampo = {
      for (var col in _colunas) col: detectarTipo(widget.jsonData, col),
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

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Pré-visualização da Importação',
          style: TextStyle(color: Colors.black),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.70,
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
        actions: [
          TextButton(
            onPressed: _paginaAtual > 0
                ? () => setState(() => _paginaAtual--)
                : null,
            child: const Text('Anterior'),
          ),
          Text('Página ${_paginaAtual + 1} de $totalPaginas'),
          TextButton(
            onPressed: (_paginaAtual + 1) * _linhasPorPagina < widget.jsonData.length
                ? () => setState(() => _paginaAtual++)
                : null,
            child: const Text('Próxima'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _confirmarImportacao,
            child: const Text('Confirmar e Importar'),
          ),
        ],
      ),
    );
  }

  // ---------- Tabelas ----------

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
          notificationPredicate: (_) => false, // evita 2 barras verticais
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
                setState(() => _linhasSelecionadas[indexGlobal] = selected ?? false);
              },
              onToggleColuna: (coluna, selected) {
                setState(() => _colunasSelecionadas[coluna] = selected ?? false);
              },
              onChangeTipo: (coluna, tipo) {
                setState(() => _tiposPorCampo[coluna] = tipo);
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
      final Map<String, dynamic> linhaConvertida = {};
      for (final col in _colunasSelecionadas.keys) {
        if (_colunasSelecionadas[col] != true) continue;

        final valor = linha[col];
        final tipo = _tiposPorCampo[col] ?? TipoDado.string;
        final convertido = converterValorPorTipo(valor, tipo);

        linhaConvertida[col] = convertido is DateTime
            ? convertido.toIso8601String()
            : convertido;
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
                setState(() => _linhasSelecionadas[indexGlobal] = selected ?? false);
              },
              onToggleColuna: (coluna, selected) {
                setState(() => _colunasSelecionadas[coluna] = selected ?? false);
              },
              onChangeTipo: (coluna, tipo) {
                setState(() => _tiposPorCampo[coluna] = tipo);
              },
              paginaAtual: _paginaAtual,
              linhasPorPagina: _linhasPorPagina,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Importação (com correção do loop) ----------

  Future<void> _confirmarImportacao() async {
    final ref = FirebaseFirestore.instance
        .collection('trafficInfractions')
        .doc('lJSc788Ot4B64uVTK8c1')
        .collection(widget.path);

    final total = _linhasSelecionadas.entries.where((e) => e.value).length;
    if (total == 0) {
      // ❗️ aviso via NotificationCenter
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nada a importar'),
          subtitle: const Text('Nenhuma linha selecionada.'),
          type: AppNotificationType.warning,
          leadingLabel: const Text('Importação'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // controla o progresso mostrado
    final progress = ValueNotifier<int>(0);
    _importDialogLoopStarted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // dispara o processamento apenas 1x
        if (!_importDialogLoopStarted) {
          _importDialogLoopStarted = true;

          Future(() async {
            int count = 0;

            try {
              for (int i = 0; i < widget.jsonData.length; i++) {
                if (!(_linhasSelecionadas[i] ?? false)) continue;

                final linha = widget.jsonData[i];
                final Map<String, dynamic> dadosFiltrados = {};

                for (final campo in _colunasSelecionadas.keys) {
                  if (_colunasSelecionadas[campo] != true) continue;

                  final valor = linha[campo];
                  final tipo = _tiposPorCampo[campo] ?? TipoDado.string;
                  final convertido = converterValorPorTipo(valor, tipo);

                  dadosFiltrados[campo] = convertido;
                }

                // salve como preferir (add / set com docId único)
                await ref.add(dadosFiltrados);

                count++;
                progress.value = count;
              }

              if (ctx.mounted) Navigator.of(ctx).pop(); // fecha progress
              if (mounted) Navigator.of(context).pop();  // fecha preview

              if (mounted) {
                // ✅ sucesso via NotificationCenter
                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Importação concluída'),
                    subtitle: Text('Registros importados: $count de $total.'),
                    type: AppNotificationType.success,
                    leadingLabel: const Text('Importação'),
                    duration: const Duration(seconds: 6),
                  ),
                );
                widget.onFinished?.call();
              }
            } catch (e) {
              if (ctx.mounted) Navigator.of(ctx).pop(); // fecha progress
              if (mounted) Navigator.of(context).pop();  // fecha preview

              // ❌ erro via NotificationCenter
              NotificationCenter.instance.show(
                AppNotification(
                  title: const Text('Falha na importação'),
                  subtitle: Text('$e'),
                  type: AppNotificationType.error,
                  leadingLabel: const Text('Importação'),
                  duration: const Duration(seconds: 8),
                ),
              );
            }
          });
        }

        return ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, current, __) {
            return ProgressImportDialog(total: total, current: current);
          },
        );
      },
    );
  }
}
