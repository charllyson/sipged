import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/admPanel/firestore/firestore_export_stub.dart';

class FieldMapping {
  final TextEditingController oldFieldCtrl;
  final TextEditingController newFieldCtrl;
  String selectedType;

  FieldMapping({
    required this.oldFieldCtrl,
    required this.newFieldCtrl,
    this.selectedType = 'string',
  });
}

class FirestoreExplorerPage extends StatefulWidget {
  const FirestoreExplorerPage({super.key});

  @override
  State<FirestoreExplorerPage> createState() => _FirestoreExplorerPageState();
}

class _FirestoreExplorerPageState extends State<FirestoreExplorerPage> {
  final _collectionCtrl = TextEditingController(text: 'documents');
  final _newCollectionCtrl = TextEditingController();
  final List<FieldMapping> _fieldMappings = [];
  final List<Map<String, TextEditingController>> _subcollections = [];
  Map<String, dynamic>? firestoreData;
  bool isLoading = false;
  bool _somentePrimeiroDoc = true;
  bool _somentePrimeiroDocSub = true;
  String? _ultimaSubcolecaoBuscada;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Firestore Explorer'),
            actions: [
              if (firestoreData != null && !isLoading) ...[
                TextButton.icon(
                  onPressed: _exportarComoJson,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar JSON'),
                ),
                TextButton.icon(
                  onPressed: _exportarComoCSV,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Exportar CSV'),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.white,
          body: AbsorbPointer(
            absorbing: isLoading,
            child: Opacity(
              opacity: isLoading ? 0.5 : 1.0,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              enabled: true,
                              controller: _collectionCtrl,
                              labelText: 'Nome da coleção principal',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _newCollectionCtrl,
                              labelText: 'Nome da nova coleção',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Text('Apenas na 1º coleção', style: TextStyle(color: Colors.grey)),
                                  Switch(
                                    value: _somentePrimeiroDoc,
                                    onChanged: (value) => setState(() => _somentePrimeiroDoc = value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadData,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Buscar dados nesta coleção', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmar = await _confirmarAcao(
                                    'Deseja realmente renomear esta coleção? Essa ação não pode ser desfeita.',
                                  );
                                  if (confirmar) _copiarColecao();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                icon: const Icon(Icons.copy, color: Colors.white),
                                label: const Text('Duplicar coleção com o novo nome', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmar = await _confirmarAcao(
                                    'Deseja realmente transformar os arrays em subcoleções e remover os arrays originais?',
                                  );
                                  if (confirmar) await _replicarECriarColecoesDeArrays();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                                label: const Text('Tansformar arrays em subcoleções', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._subcollections.map((pair) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: pair['old']!,
                                  labelText: 'Subcoleção original',
                                  valueColor: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomTextField(
                                  controller: pair['new']!,
                                  labelText: 'Nova subcoleção',
                                  valueColor: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text('Apenas no 1º doc. da subcoleção', style: TextStyle(color: Colors.grey)),
                                      Switch(
                                        value: _somentePrimeiroDocSub,
                                        onChanged: (value) => setState(() => _somentePrimeiroDocSub = value),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _buscarSubcolecao(pair['old']!.text.trim(), pair['new']!.text.trim()),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Buscar dados nesta subcoleção', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmar = await _confirmarAcao(
                                        'Deseja realmente renomear esta subcoleção? A subcoleção original será apagada.',
                                      );
                                      if (confirmar) _replicarSubcolecao(pair['old']!.text.trim(), pair['new']!.text.trim());
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    label: const Text('Renomear subcoleção', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _adicionarSubcolecao,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar subcoleção'),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (firestoreData == null)
                    const Center(child: Text('Nenhum dado carregado.'))
                  else
                    SingleChildScrollView(child: _multiDocTable(firestoreData!)),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  void _adicionarSubcolecao() {
    setState(() {
      _subcollections.add({'old': TextEditingController(), 'new': TextEditingController()});
    });
  }

  Future<void> _buscarSubcolecao(String nomeOriginal, String nomeNovo) async {
    if (nomeOriginal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o nome da subcoleção original para buscar.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      firestoreData = null;
      _fieldMappings.clear();
    });

    try {
      final colName = _collectionCtrl.text.trim();
      final parentSnapshot = await FirebaseFirestore.instance.collection(colName).get();

      if (parentSnapshot.docs.isEmpty) {
        setState(() => isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum documento encontrado na coleção "$colName".')),
        );
        return;
      }

      final parentDocs = _somentePrimeiroDocSub ? [parentSnapshot.docs.first] : parentSnapshot.docs;
      final result = <String, dynamic>{};

      for (final parentDoc in parentDocs) {
        final subSnapshot = await parentDoc.reference.collection(nomeOriginal).get();
        for (final doc in subSnapshot.docs) {
          result['${parentDoc.id}/${doc.id}'] = Map<String, dynamic>.from(doc.data());
          if (_somentePrimeiroDoc) break;
        }
      }

      setState(() {
        firestoreData = result;
        isLoading = false;
        _ultimaSubcolecaoBuscada = nomeOriginal;
        _preencherCamposAutomaticamente();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documentos carregados da subcoleção "$nomeOriginal".')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar subcoleção: $e')),
      );
    }
  }

  Future<void> _replicarSubcolecao(String nomeOriginal, String nomeNovo) async {
    if (nomeOriginal.isEmpty || nomeNovo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe os nomes da subcoleção original e nova.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final colName = _collectionCtrl.text.trim();
      final parentSnapshot = await FirebaseFirestore.instance.collection(colName).get();

      for (final parentDoc in parentSnapshot.docs) {
        final subRefOriginal = parentDoc.reference.collection(nomeOriginal);
        final subSnapshot = await subRefOriginal.get();

        for (final doc in subSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          final novosDados = <String, dynamic>{};

          for (final entry in data.entries) {
            final oldField = entry.key;
            final mapping = _fieldMappings.firstWhere(
                  (m) => m.oldFieldCtrl.text.trim() == oldField,
              orElse: () => FieldMapping(
                oldFieldCtrl: TextEditingController(text: oldField),
                newFieldCtrl: TextEditingController(text: _formatarNome(oldField)),
              ),
            );

            final newField = _formatarNome(mapping.newFieldCtrl.text.trim());
            final tipo = mapping.selectedType;
            novosDados[newField] = _converterTipo(entry.value, tipo);
          }

          await parentDoc.reference.collection(nomeNovo).doc(doc.id).set(novosDados);
        }

        for (final doc in subSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subcoleção "$nomeOriginal" replicada e original removida com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final colName = _collectionCtrl.text.trim();
    final snapshot = await FirebaseFirestore.instance.collection(colName).get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        firestoreData = {};
        isLoading = false;
        _fieldMappings.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nenhum documento encontrado na coleção "$colName".')),
      );
      return;
    }

    final result = <String, dynamic>{};
    final docsToProcess = _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;
    for (final doc in docsToProcess) {
      result[doc.id] = Map<String, dynamic>.from(doc.data());
    }

    setState(() {
      firestoreData = result;
      isLoading = false;
      _preencherCamposAutomaticamente();
    });
  }

  void _preencherCamposAutomaticamente() {
    if (firestoreData != null && firestoreData!.isNotEmpty) {
      final firstDoc = firestoreData!.values.first;
      if (firstDoc is Map<String, dynamic>) {
        _fieldMappings.clear();
        firstDoc.forEach((key, value) {
          final nomeFormatado = _formatarNome(key);
          final tipoDetectado = _detectarTipo(value);
          _fieldMappings.add(
            FieldMapping(
              oldFieldCtrl: TextEditingController(text: key),
              newFieldCtrl: TextEditingController(text: nomeFormatado),
              selectedType: tipoDetectado,
            ),
          );
        });
      }
    }
  }

  String _detectarTipo(dynamic valor) {
    if (valor is String) return 'string';
    if (valor is int || valor is double || valor is num) return 'number';
    if (valor is bool) return 'boolean';
    if (valor is Timestamp || valor is DateTime) return 'timestamp';
    if (valor is List) return 'list';
    if (valor is Map) return 'network';
    return 'string';
  }

  Future<void> _copiarColecao() async {
    final origem = _collectionCtrl.text.trim();
    final destino = _newCollectionCtrl.text.trim();
    if (origem.isEmpty || destino.isEmpty) return;

    final origemCol = FirebaseFirestore.instance.collection(origem);
    final destinoCol = FirebaseFirestore.instance.collection(destino);
    final snapshot = await origemCol.get();

    for (final doc in snapshot.docs) {
      final novoData = <String, dynamic>{};
      doc.data().forEach((key, value) {
        novoData[_formatarNome(key)] = value;
      });
      await destinoCol.doc(doc.id).set(novoData);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coleção "$origem" copiada para "$destino"')),
    );
  }

  Future<void> _replicarECriarColecoesDeArrays() async {
    final origem = _collectionCtrl.text.trim();
    final destino = _newCollectionCtrl.text.trim().isEmpty ? origem : _newCollectionCtrl.text.trim();
    if (origem.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final origemCol = FirebaseFirestore.instance.collection(origem);
      final destinoCol = FirebaseFirestore.instance.collection(destino);
      final snapshot = await origemCol.get();

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final novoData = <String, dynamic>{};

        data.forEach((key, value) {
          if (value is! List) {
            novoData[_formatarNome(key)] = value;
          }
        });

        await destinoCol.doc(doc.id).set(novoData);

        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is List) {
            final subcollectionName = _formatarNome(key);
            final subcollectionRef = destinoCol.doc(doc.id).collection(subcollectionName);

            for (final item in value) {
              if (item is Map) {
                final novoMap = <String, dynamic>{};
                item.forEach((k, v) => novoMap[_formatarNome(k)] = v);
                await subcollectionRef.add(novoMap);
              } else {
                await subcollectionRef.add({'valor': item});
              }
            }
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coleção replicada e arrays convertidos com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _renomearCamposNaSubcolecao(String nomeSubcolecao) async {
    final colName = _collectionCtrl.text.trim();
    if (colName.isEmpty || nomeSubcolecao.isEmpty) return;

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();
    final parentDocs = _somentePrimeiroDocSub ? [snapshot.docs.first] : snapshot.docs;

    for (final parentDoc in parentDocs) {
      final subSnapshot = await parentDoc.reference.collection(nomeSubcolecao).get();

      for (final doc in subSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final novosDados = <String, dynamic>{};
        final deletarCampos = <String, dynamic>{};

        for (final entry in data.entries) {
          final oldField = entry.key;
          final mapping = _fieldMappings.firstWhere(
                (m) => m.oldFieldCtrl.text.trim() == oldField,
            orElse: () => FieldMapping(
              oldFieldCtrl: TextEditingController(text: oldField),
              newFieldCtrl: TextEditingController(text: _formatarNome(oldField)),
            ),
          );

          final newField = _formatarNome(mapping.newFieldCtrl.text.trim());
          final tipo = mapping.selectedType;
          novosDados[newField] = _converterTipo(entry.value, tipo);

          if (newField != oldField) {
            deletarCampos[oldField] = FieldValue.delete();
          }
        }

        await doc.reference.update(novosDados);
        if (deletarCampos.isNotEmpty) {
          await doc.reference.update(deletarCampos);
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Campos renomeados em subcoleção "$nomeSubcolecao".')),
    );
  }

  Future<void> _renomearCampos() async {
    final colName = _collectionCtrl.text.trim();
    if (colName.isEmpty) return;

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();

    final docsToProcess = _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;

    for (final doc in docsToProcess) {
      final data = doc.data();

      for (final map in _fieldMappings) {
        final oldField = map.oldFieldCtrl.text.trim();
        final newField = _formatarNome(map.newFieldCtrl.text.trim());

        if (oldField.isEmpty || newField.isEmpty || !data.containsKey(oldField)) continue;

        final converted = _converterTipo(data[oldField], map.selectedType);

        if (newField != oldField) {
          await doc.reference.update({newField: converted});
          await doc.reference.update({oldField: FieldValue.delete()});
        } else {
          await doc.reference.update({newField: converted});
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campos renomeados com sucesso!')),
    );

    _loadData();
  }

  dynamic _converterTipo(dynamic valor, String tipo) {
    switch (tipo) {
      case 'string':
        return valor.toString();
      case 'number':
        final clean = valor.toString()
            .replaceAll(RegExp(r'[^\d,.-]'), '')
            .replaceAll('.', '')
            .replaceAll(',', '.');
        return num.tryParse(clean) ?? 0;
      case 'boolean':
        return valor.toString().toLowerCase() == 'true';
      case 'timestamp':
        if (valor is Timestamp) return valor;
        if (valor is String) {
          try {
            return Timestamp.fromDate(DateTime.parse(valor));
          } catch (_) {
            return Timestamp.now();
          }
        }
        return Timestamp.now();
      case 'list':
        return valor is List ? valor.map((e) => e.toString()).toList() : [valor];
      case 'network':
        return valor is Map ? valor.map((k, v) => MapEntry(k.toString(), v.toString())) : {};
      default:
        return valor;
    }
  }

  Widget _multiDocTable(Map<String, dynamic> data) {
    final docIds = data.keys.toList();
    final allKeys = _fieldMappings.map((e) => e.oldFieldCtrl.text).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Renomear campos do firestore:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(_fieldMappings.length, (i) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _fieldMappings[i].oldFieldCtrl,
                  labelText: 'Campo original',
                  enabled: false,
                  valueColor: Colors.black,
                ),
                const SizedBox(width: 12),
                CustomTextField(
                  controller: _fieldMappings[i].newFieldCtrl,
                  labelText: 'Novo nome',
                  valueColor: Colors.black,
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _fieldMappings[i].selectedType,
                  items: const [
                    DropdownMenuItem(value: 'string', child: Text('String')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                    DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                    DropdownMenuItem(value: 'timestamp', child: Text('Timestamp')),
                    DropdownMenuItem(value: 'list', child: Text('List')),
                    DropdownMenuItem(value: 'network', child: Text('Map')),
                  ],
                  onChanged: (value) => setState(() => _fieldMappings[i].selectedType = value!),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final confirmar = await _confirmarAcao(
              _ultimaSubcolecaoBuscada != null
                  ? 'Deseja renomear os campos da subcoleção "${_ultimaSubcolecaoBuscada!}"?'
                  : 'Tem certeza que deseja renomear os campos da coleção principal?',
            );
            if (!confirmar) return;

            setState(() => isLoading = true);
            try {
              if (_ultimaSubcolecaoBuscada != null) {
                await _renomearCamposNaSubcolecao(_ultimaSubcolecaoBuscada!);
              } else {
                await _renomearCampos();
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao renomear campos: $e')),
              );
            } finally {
              setState(() => isLoading = false);
            }
          },
          child: const Text('Renomear campos e converter tipos', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [const DataColumn(label: Text('ID'))] + allKeys.map((k) => DataColumn(label: Text(k))).toList(),
            rows: docIds.map((id) {
              final doc = data[id] as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(Text(id)),
                  ...allKeys.map((k) {
                    final v = doc[k];
                    final val = _prepareForJson(v);
                    return DataCell(Text(val.toString(), overflow: TextOverflow.ellipsis));
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _exportarComoJson() {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(_prepareForJson(firestoreData));
    downloadJson('firestore_dump.json', jsonStr); // <- bridge
  }

  void _exportarComoCSV() {
    final buffer = StringBuffer();
    final keys = _fieldMappings.map((e) => e.oldFieldCtrl.text).toList();
    buffer.writeln('ID,${keys.join(",")}');
    firestoreData!.forEach((id, data) {
      final values = keys.map((k) => '"${_prepareForJson(data[k] ?? "")}"').join(',');
      buffer.writeln('$id,$values');
    });
    downloadCsv('firestore_dump.csv', buffer.toString()); // <- bridge
  }

  dynamic _prepareForJson(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is GeoPoint) return {'latitude': value.latitude, 'longitude': value.longitude};
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _prepareForJson(v)));
    if (value is List) return value.map(_prepareForJson).toList();
    return value;
  }

  String _formatarNome(String original) {
    final semAcentos = _removerAcentos(original);
    return semAcentos.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '').replaceAll(RegExp(r'_+'), '_').trim();
  }

  String _removerAcentos(String str) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const sem = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    for (int i = 0; i < com.length; i++) {
      str = str.replaceAll(com[i], sem[i]);
    }
    return str;
  }

  Future<bool> _confirmarAcao(String mensagem) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: Text(mensagem),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    ) ??
        false;
  }
}
