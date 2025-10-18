import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ImportExcelPage extends StatefulWidget {
  final String firstCollection;
  final void Function()? onFinished;
  final Future<void> Function(Map<String, dynamic> dados)? onSave;

  const ImportExcelPage({
    super.key,
    required this.firstCollection,
    this.onFinished,
    this.onSave,
  });

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  bool _importando = false;
  List<Map<String, dynamic>> _jsonData = [];
  final Map<String, String> _tiposPorCampo = {};

  // 🔔 helper
  void _notify(String title,
      {AppNotificationType type = AppNotificationType.info, String? subtitle}) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        type: type,
      ),
    );
  }

  Future<void> _importarExcel() async {
    try {
      setState(() {
        _importando = true;
        _jsonData = [];
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) {
        _notify('Importação cancelada', type: AppNotificationType.warning);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        _notify('Planilha não encontrada', type: AppNotificationType.error);
        return;
      }

      final headers = sheet.rows.first
          .map((cell) => cell?.value.toString().trim().replaceAll('\u00A0', ''))
          .toList();

      _jsonData = sheet.rows.skip(1).map((row) {
        final Map<String, dynamic> json = {};
        for (int i = 0; i < headers.length; i++) {
          final key = headers[i];
          final cell = row[i];
          if (key != null) {
            json[key] = _converterValor(cell?.value);
          }
        }
        return json;
      }).toList();

      if (_jsonData.isEmpty) {
        _notify('Planilha vazia!', type: AppNotificationType.warning);
        return;
      }

      _mostrarPreviewComSelecao();
    } catch (e) {
      debugPrint('Erro ao importar Excel: $e');
      _notify('Erro ao importar', type: AppNotificationType.error, subtitle: '$e');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;

    if (valor is String) {
      final str = valor.trim();

      // Data dd/MM/yyyy
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

      // Data ISO
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(str)) {
        return DateTime.tryParse(str);
      }

      // Double com vírgula
      final strConvertido = str.replaceAll('.', '').replaceAll(',', '.');
      final parsedDouble = double.tryParse(strConvertido);
      if (parsedDouble != null) return parsedDouble;

      return str;
    }

    return valor;
  }

  void _mostrarPreviewComSelecao() {
    final colunas = _jsonData.isNotEmpty ? _jsonData.first.keys.toList() : [];
    final Map<int, bool> linhasSelecionadas = {
      for (int i = 0; i < _jsonData.length; i++) i: true
    };
    final Map<String, bool> colunasSelecionadas = {
      for (var col in colunas) col: true
    };
    for (var col in colunas) {
      _tiposPorCampo[col] = _detectarTipo(_jsonData, col);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Pré-visualização (${_jsonData.length} registros)'),
              content: SingleChildScrollView(
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
                                      colunasSelecionadas[coluna] = val ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _tiposPorCampo[coluna] ?? 'String',
                                    underline: const SizedBox(),
                                    items: ['String', 'int', 'double', 'bool', 'DateTime']
                                        .map((tipo) => DropdownMenuItem(
                                      value: tipo,
                                      child: Text(tipo, style: const TextStyle(fontSize: 12)),
                                    ))
                                        .toList(),
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        if (val != null) _tiposPorCampo[coluna] = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  coluna,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
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
                        return DataCell(
                          colunasSelecionadas[coluna] == true
                              ? Text(valor?.toString() ?? '')
                              : const Text('-', style: TextStyle(color: Colors.grey)),
                        );
                      }).toList(),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _salvarLinhasSelecionadas(
                      linhasSelecionadas,
                      colunasSelecionadas,
                      _tiposPorCampo,
                    );
                  },
                  child: const Text('Confirmar e Importar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarLinhasSelecionadas(
      Map<int, bool> linhasSelecionadas,
      Map<String, bool> colunasSelecionadas,
      Map<String, String> tiposSelecionados,
      ) async {
    int count = 0;

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
                final texto = valor.toString().replaceAll('.', '').replaceAll(',', '.');
                valorConvertido = double.tryParse(texto);
              }
              break;
            case 'bool':
              final v = valor.toString().toLowerCase();
              valorConvertido = v == 'true' || v == '1';
              break;
            case 'DateTime':
              valorConvertido = DateTime.tryParse(valor.toString());
              break;
            case 'null':
              valorConvertido = null;
              break;
            default:
              valorConvertido = valor.toString();
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

    _notify('Importação concluída', type: AppNotificationType.success,
        subtitle: '$count registros importados.');

    if (widget.onFinished != null) {
      widget.onFinished!(); // notifica a tela principal
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
      return DateTime.tryParse(str); // tenta padrão ISO
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
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}
