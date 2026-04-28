import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({
    super.key,
    required this.firstCollection,
    this.onFinished,
    this.onSave,
  });

  final String firstCollection;
  final void Function()? onFinished;
  final Future<void> Function(Map<String, dynamic> dados)? onSave;

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  bool _importando = false;

  List<Map<String, dynamic>> _jsonData = <Map<String, dynamic>>[];

  final Map<String, String> _tiposPorCampo = <String, String>{};

  void _notify(
      String title, {
        NotificationType type = NotificationType.info,
        String? subtitle,
      }) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Importação',
        type: type,
        extra: {
          'module': 'excel_import',
          'firstCollection': widget.firstCollection,
        },
      ),
      saveInFirebase: false,
    );
  }

  Future<void> _importarExcel() async {
    try {
      setState(() {
        _importando = true;
        _jsonData = <Map<String, dynamic>>[];
      });

      final result = await FilePicker.platform.pickFiles();

      if (result == null) {
        _notify(
          'Importação cancelada',
          type: NotificationType.warning,
        );
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        _notify(
          'Planilha não encontrada',
          type: NotificationType.error,
        );
        return;
      }

      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null || sheet.rows.isEmpty) {
        _notify(
          'Planilha não encontrada',
          type: NotificationType.error,
        );
        return;
      }

      final headers = sheet.rows.first
          .map((cell) {
        final raw = cell?.value.toString().trim().replaceAll('\u00A0', '');
        return raw;
      })
          .toList();

      _jsonData = sheet.rows.skip(1).map((row) {
        final Map<String, dynamic> json = <String, dynamic>{};

        for (int i = 0; i < headers.length; i++) {
          final key = headers[i];

          if (key == null || key.trim().isEmpty) continue;

          final cell = row.length > i ? row[i] : null;
          json[key] = _converterValor(cell?.value);
        }

        return json;
      }).toList();

      if (_jsonData.isEmpty) {
        _notify(
          'Planilha vazia!',
          type: NotificationType.warning,
        );
        return;
      }

      _mostrarPreviewComSelecao();
    } catch (e) {
      _notify(
        'Erro ao importar',
        type: NotificationType.error,
        subtitle: '$e',
      );
    } finally {
      if (mounted) {
        setState(() => _importando = false);
      }
    }
  }

  dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;

    if (valor is String) {
      final str = valor.trim();

      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
        final partes = str.split('/');

        try {
          return DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
        } catch (_) {
          return str;
        }
      }

      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(str)) {
        return DateTime.tryParse(str);
      }

      final strConvertido = str.replaceAll('.', '').replaceAll(',', '.');
      final parsedDouble = double.tryParse(strConvertido);

      if (parsedDouble != null) return parsedDouble;

      return str;
    }

    return valor;
  }

  void _mostrarPreviewComSelecao() {
    final colunas = _jsonData.isNotEmpty
        ? _jsonData.first.keys.toList()
        : <String>[];

    final Map<int, bool> linhasSelecionadas = <int, bool>{
      for (int i = 0; i < _jsonData.length; i++) i: true,
    };

    final Map<String, bool> colunasSelecionadas = <String, bool>{
      for (final col in colunas) col: true,
    };

    for (final col in colunas) {
      _tiposPorCampo[col] = _detectarTipo(_jsonData, col);
    }

    showWindowDialog<void>(
      context: context,
      title: 'Pré-visualização (${_jsonData.length} registros)',
      width: 960,
      barrierDismissible: true,
      child: StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 600,
              maxWidth: 1100,
              maxHeight: 640,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: colunas.map((coluna) {
                        return DataColumn(
                          label: SizedBox(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: colunasSelecionadas[coluna],
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          colunasSelecionadas[coluna] =
                                              val ?? false;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 90,
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value:
                                        _tiposPorCampo[coluna] ?? 'String',
                                        underline: const SizedBox(),
                                        items: const <String>[
                                          'String',
                                          'int',
                                          'double',
                                          'bool',
                                          'DateTime',
                                        ].map((tipo) {
                                          return DropdownMenuItem<String>(
                                            value: tipo,
                                            child: Text(
                                              tipo,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setStateDialog(() {
                                            if (val != null) {
                                              _tiposPorCampo[coluna] = val;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        coluna,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      rows: List.generate(_jsonData.length, (index) {
                        final linha = _jsonData[index];

                        return DataRow(
                          selected: linhasSelecionadas[index] ?? false,
                          onSelectChanged: (val) {
                            setStateDialog(() {
                              linhasSelecionadas[index] = val ?? false;
                            });
                          },
                          cells: colunas.map((coluna) {
                            final valor = linha[coluna];
                            final isSelectedCol =
                                colunasSelecionadas[coluna] == true;

                            return DataCell(
                              isSelectedCol
                                  ? Text(
                                valor?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              )
                                  : const Text(
                                '-',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        _salvarLinhasSelecionadas(
                          linhasSelecionadas,
                          colunasSelecionadas,
                          _tiposPorCampo,
                        );
                      },
                      child: const Text('Confirmar e Importar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _salvarLinhasSelecionadas(
      Map<int, bool> linhasSelecionadas,
      Map<String, bool> colunasSelecionadas,
      Map<String, String> tiposSelecionados,
      ) async {
    int count = 0;

    try {
      for (int i = 0; i < _jsonData.length; i++) {
        if (!(linhasSelecionadas[i] ?? false)) continue;

        final linha = _jsonData[i];
        final dadosFiltrados = <String, dynamic>{};

        for (final campo in colunasSelecionadas.keys) {
          if (colunasSelecionadas[campo] != true) continue;

          final valor = linha[campo];
          final tipo = tiposSelecionados[campo] ?? 'String';

          dynamic valorConvertido;

          try {
            switch (tipo) {
              case 'int':
                valorConvertido = int.tryParse(valor.toString());
                break;

              case 'double':
                if (valor is num) {
                  valorConvertido = valor.toDouble();
                } else {
                  final texto =
                  valor.toString().replaceAll('.', '').replaceAll(',', '.');
                  valorConvertido = double.tryParse(texto);
                }
                break;

              case 'bool':
                final v = valor.toString().toLowerCase().trim();
                valorConvertido = v == 'true' || v == '1' || v == 'sim';
                break;

              case 'DateTime':
                if (valor is DateTime) {
                  valorConvertido = valor;
                } else {
                  valorConvertido = DateTime.tryParse(valor.toString());
                }
                break;

              case 'null':
                valorConvertido = null;
                break;

              case 'String':
              default:
                valorConvertido = valor?.toString();
            }
          } catch (_) {
            valorConvertido = valor;
          }

          dadosFiltrados[campo] = valorConvertido;
        }

        dadosFiltrados['contractId'] = widget.firstCollection;

        if (widget.onSave != null) {
          await widget.onSave!(dadosFiltrados);
        }

        count++;
      }

      _notify(
        'Importação concluída',
        type: NotificationType.success,
        subtitle: '$count registros importados.',
      );

      widget.onFinished?.call();
    } catch (e) {
      _notify(
        'Erro ao salvar importação',
        type: NotificationType.error,
        subtitle: '$e',
      );
    }
  }

  String _detectarTipo(List<Map<String, dynamic>> dados, String campo) {
    for (final linha in dados) {
      final valor = linha[campo];

      if (valor == null) continue;
      if (valor is int) return 'int';
      if (valor is double) return 'double';
      if (valor is bool) return 'bool';
      if (valor is DateTime) return 'DateTime';

      if (valor is String && (valor.contains('/') || valor.contains('-'))) {
        final data = _converterParaDateTime(valor);
        if (data != null) return 'DateTime';
      }

      return 'String';
    }

    return 'String';
  }

  DateTime? _converterParaDateTime(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;

    if (valor is String) {
      final str = valor.trim();

      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(str)) {
        final partes = str.split('/');

        try {
          return DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
        } catch (_) {
          return null;
        }
      }

      return DateTime.tryParse(str);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Importar dados da planilha',
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              child: IconButton(
                icon: const Icon(Icons.file_upload, size: 20),
                color: isDark ? Colors.white : Colors.black87,
                onPressed: _importando ? null : _importarExcel,
              ),
            ),
            if (_importando)
              const LoadingTreeDots(
                size: 40,
                strokeWidth: 2,
                color: Colors.blue,
                centered: false,
              ),
          ],
        ),
      ),
    );
  }
}