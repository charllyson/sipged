import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GenericImportExcelPage extends StatefulWidget {
  final String? path;
  const GenericImportExcelPage({super.key, this.path});

  @override
  State<GenericImportExcelPage> createState() => _GenericImportExcelPageState();
}

class _GenericImportExcelPageState extends State<GenericImportExcelPage> {
  final TextEditingController _pathController = TextEditingController();
  List<Map<String, dynamic>> _jsonData = [];
  List<String> _camposDoExcel = [];
  List<String> _camposExistentesNoBanco = [];
  List<String> _camposSelecionados = [];
  final Map<String, String> _tiposPorCampo = {};
  final List<String> tiposPossiveis = ['String', 'int', 'double', 'DateTime', 'bool', 'Ignorar'];

  bool _loading = false;
  bool? _colecaoExiste;
  bool _carregandoCampos = false;
  int _atualizados = 0;
  int _totalParaAtualizar = 0;
  bool _atualizando = false;

  @override
  void initState() {
    super.initState();
    if (widget.path != null) {
      _pathController.text = widget.path!;
    }
  }

  Future<void> _verificarColecao() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    setState(() => _loading = true);
    try {
      final collection = FirebaseFirestore.instance.collection(path);
      final snapshot = await collection.limit(1).get();
      setState(() {
        _colecaoExiste = snapshot.docs.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _colecaoExiste = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Caminho inválido.')),
      );
    }
  }

  Future<void> _pickAndPreviewExcel() async {
    setState(() {
      _loading = true;
      _jsonData = [];
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = result.files.first;
        final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first];

        if (sheet != null) {
          final headers = sheet.rows.first.map((c) => c?.value.toString().trim()).toList();
          _jsonData = sheet.rows.skip(1).map((row) {
            final Map<String, dynamic> json = {};
            for (int i = 0; i < headers.length; i++) {
              final key = headers[i];
              final cell = row[i];
              if (key != null) json[key] = _converterValor(cell?.value);
            }
            return json;
          }).toList();

          if (_jsonData.isNotEmpty) _listarCamposExistentes();
        }
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  dynamic _converterValor(dynamic valor) {
    if (valor == null) return null;
    if (valor is String) {
      final str = valor.trim();
      if (RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(str)) {
        try {
          return DateFormat('dd/MM/yyyy').parse(str);
        } catch (_) {}
      }
      if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(str)) {
        return DateTime.tryParse(str);
      }
      return str;
    }
    return valor;
  }

  Future<void> _listarCamposExistentes() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    setState(() {
      _carregandoCampos = true;
      _camposSelecionados = [];
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection(path).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _camposExistentesNoBanco = snapshot.docs.first.data().keys.toList();
      }
      if (_jsonData.isNotEmpty) {
        _camposDoExcel = _jsonData.first.keys.toList();
        _camposSelecionados = List.from(_camposDoExcel);
      }
      setState(() => _carregandoCampos = false);
      _mostrarSelecaoDeCampos();
    } catch (_) {}
  }

  void _mostrarSelecaoDeCampos() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar campos para atualizar'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _camposDoExcel.map((campo) {
                final existe = _camposExistentesNoBanco.contains(campo);
                return Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(campo, style: TextStyle(color: existe ? Colors.black : Colors.red)),
                        subtitle: existe ? null : const Text('Campo novo', style: TextStyle(fontSize: 12)),
                        value: _camposSelecionados.contains(campo),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _camposSelecionados.add(campo);
                            } else {
                              _camposSelecionados.remove(campo);
                            }
                          });
                        },
                      ),
                    ),
                    DropdownButton<String>(
                      value: _tiposPorCampo[campo] ?? 'String',
                      items: tiposPossiveis.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _tiposPorCampo[campo] = val!;
                          if (val == 'Ignorar') {
                            _camposSelecionados.remove(campo);
                          } else {
                            _camposSelecionados.add(campo);
                          }
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarPreview();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarPreview() {
    final preview = _jsonData.first;
    final previewFiltrado = Map.fromEntries(
      preview.entries.where((e) => _camposSelecionados.contains(e.key)),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pré-visualização do primeiro registro'),
          content: Text(
            previewFiltrado.entries
                .map((e) => '${e.key}: ${e.value} (${e.value.runtimeType})')
                .join('\n'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _salvarAtualizacoes();
              },
              child: const Text('Confirmar e Atualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _salvarAtualizacoes() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    setState(() {
      _loading = true;
      _atualizando = true;
      _atualizados = 0;
      _totalParaAtualizar = _jsonData.length;
    });
    final collection = FirebaseFirestore.instance.collection(path);
    final parentId = _getParentIdFromPath(path);

    for (final rowOriginal in _jsonData) {
      final row = Map<String, dynamic>.from(rowOriginal);
      final dadosFiltrados = <String, dynamic>{};

      for (final entry in row.entries) {
        final key = entry.key;
        if (!_camposSelecionados.contains(key)) continue;
        final tipo = _tiposPorCampo[key] ?? 'String';
        final valorOriginal = entry.value;
        dynamic valor;

        try {
          switch (tipo) {
            case 'int': valor = int.tryParse(valorOriginal.toString()); break;
            case 'double': valor = double.tryParse(valorOriginal.toString()); break;
            case 'bool': valor = valorOriginal.toString().toLowerCase() == 'true' || valorOriginal.toString() == '1'; break;
            case 'DateTime': valor = valorOriginal is DateTime ? valorOriginal : DateTime.tryParse(valorOriginal.toString()); break;
            case 'String': default: valor = valorOriginal.toString();
          }
        } catch (_) {
          valor = valorOriginal;
        }
        dadosFiltrados[key] = valor;
      }

      if (parentId != null) {
        dadosFiltrados['contractId'] = parentId;
      }

      final order = row['order'];
      if (order == null) continue;

      final snapshot = await collection.where('order', isEqualTo: order).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        await collection.doc(snapshot.docs.first.id).update(dadosFiltrados);
      } else {
        await collection.add(dadosFiltrados);
      }

      setState(() => _atualizados++);
    }

    setState(() {
      _loading = false;
      _atualizando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importação concluída!')),
    );
  }

  String? _getParentIdFromPath(String path) {
    final parts = path.split('/');
    return parts.length >= 2 ? parts[parts.length - 2] : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Importar para: ${_pathController.text.isEmpty ? '(nenhum)' : _pathController.text}')),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Caminho da coleção ou subcoleção no Firestore',
                hintText: 'Ex: documents/abc123/accidents',
              ),
            ),
            const SizedBox(height: 16),
            if (_atualizando) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _atualizados / _totalParaAtualizar, minHeight: 16),
              const SizedBox(height: 8),
              Text('$_atualizados de $_totalParaAtualizar atualizados'),
            ],
            ElevatedButton.icon(
              onPressed: _verificarColecao,
              icon: const Icon(Icons.search),
              label: const Text('Verificar coleção'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _colecaoExiste != false ? _pickAndPreviewExcel : null,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar Excel'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _jsonData.isNotEmpty ? _listarCamposExistentes : null,
              icon: const Icon(Icons.list),
              label: const Text('Selecionar campos'),
            ),
            if (_loading || _carregandoCampos)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}