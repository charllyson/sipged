import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_services/firestore/explorer/firestore_export_stub.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class FieldMapping {
  final TextEditingController oldFieldCtrl;
  final TextEditingController newFieldCtrl;
  String selectedType;

  FieldMapping({
    required this.oldFieldCtrl,
    required this.newFieldCtrl,
    this.selectedType = 'string',
  });

  void dispose() {
    oldFieldCtrl.dispose();
    newFieldCtrl.dispose();
  }
}

class FirestoreExplorerPage extends StatefulWidget {
  const FirestoreExplorerPage({super.key});

  @override
  State<FirestoreExplorerPage> createState() => _FirestoreExplorerPageState();
}

class _FirestoreExplorerPageState extends State<FirestoreExplorerPage> {
  final _collectionCtrl = TextEditingController(text: 'operation');
  final _newCollectionCtrl = TextEditingController();

  final List<FieldMapping> _fieldMappings = [];
  final List<Map<String, TextEditingController>> _subcollections = [];

  Map<String, dynamic>? firestoreData;

  bool isLoading = false;
  bool _somentePrimeiroDoc = true;
  bool _somentePrimeiroDocSub = true;

  String? _ultimaSubcolecaoBuscada;

  void _notify(
      String title, {
        NotificationType type = NotificationType.info,
        String? subtitle,
        Duration duration = const Duration(seconds: 5),
      }) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Firestore',
        type: type,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'firestore_explorer',
        },
      ),
      saveInFirebase: false,
    );
  }

  @override
  void dispose() {
    _collectionCtrl.dispose();
    _newCollectionCtrl.dispose();

    for (final mapping in _fieldMappings) {
      mapping.dispose();
    }

    for (final pair in _subcollections) {
      pair['old']?.dispose();
      pair['new']?.dispose();
    }

    super.dispose();
  }

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
                                  const Text(
                                    'Apenas na 1º coleção',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Switch(
                                    value: _somentePrimeiroDoc,
                                    onChanged: (value) {
                                      setState(() {
                                        _somentePrimeiroDoc = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  'Buscar dados nesta coleção',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmar = await confirmDialog(
                                    context,
                                    'Deseja realmente renomear esta coleção? Essa ação não pode ser desfeita.',
                                  );

                                  if (confirmar == true) {
                                    await _copiarColecao();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Duplicar coleção com o novo nome',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmar = await confirmDialog(
                                    context,
                                    'Deseja realmente transformar os arrays em subcoleções e remover os arrays originais?',
                                  );

                                  if (confirmar == true) {
                                    await _replicarECriarColecoesDeArrays();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                icon: const Icon(
                                  Icons.auto_fix_high,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Transformar arrays em subcoleções',
                                  style: TextStyle(color: Colors.white),
                                ),
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
                          color: Colors.white,
                        ),
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
                                      const Text(
                                        'Apenas no 1º doc. da subcoleção',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Switch(
                                        value: _somentePrimeiroDocSub,
                                        onChanged: (value) {
                                          setState(() {
                                            _somentePrimeiroDocSub = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _buscarSubcolecao(
                                      pair['old']!.text.trim(),
                                      pair['new']!.text.trim(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      'Buscar dados nesta subcoleção',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmar = await confirmDialog(
                                        context,
                                        'Deseja realmente renomear esta subcoleção? A subcoleção original será apagada.',
                                      );

                                      if (confirmar == true) {
                                        await _replicarSubcolecao(
                                          pair['old']!.text.trim(),
                                          pair['new']!.text.trim(),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    icon: const Icon(
                                      Icons.copy,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Renomear subcoleção',
                                      style: TextStyle(color: Colors.white),
                                    ),
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
                    const LoadingTreeDots(
                      size: 32,
                      strokeWidth: 3,
                    )
                  else if (firestoreData == null)
                    const Center(
                      child: Text('Nenhum dado carregado.'),
                    )
                  else
                    SingleChildScrollView(
                      child: _multiDocTable(firestoreData!),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const LoadingTreeDots(
              size: 36,
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  void _adicionarSubcolecao() {
    setState(() {
      _subcollections.add({
        'old': TextEditingController(),
        'new': TextEditingController(),
      });
    });
  }

  Future<void> _buscarSubcolecao(
      String nomeOriginal,
      String nomeNovo,
      ) async {
    if (nomeOriginal.isEmpty) {
      _notify(
        'Informe a subcoleção original para buscar.',
        type: NotificationType.warning,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() {
      isLoading = true;
      firestoreData = null;
      _disposeFieldMappings();
    });

    try {
      final colName = _collectionCtrl.text.trim();

      if (colName.isEmpty) {
        _notify(
          'Informe o nome da coleção principal.',
          type: NotificationType.warning,
        );
        return;
      }

      final parentSnapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      if (parentSnapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
        });

        _notify(
          'Nenhum documento na coleção "$colName".',
          type: NotificationType.warning,
        );
        return;
      }

      final parentDocs = _somentePrimeiroDocSub
          ? [parentSnapshot.docs.first]
          : parentSnapshot.docs;

      final result = <String, dynamic>{};

      for (final parentDoc in parentDocs) {
        final subSnapshot =
        await parentDoc.reference.collection(nomeOriginal).get();

        for (final doc in subSnapshot.docs) {
          result['${parentDoc.id}/${doc.id}'] =
          Map<String, dynamic>.from(doc.data());

          if (_somentePrimeiroDoc) break;
        }
      }

      setState(() {
        firestoreData = result;
        isLoading = false;
        _ultimaSubcolecaoBuscada = nomeOriginal;
        _preencherCamposAutomaticamente();
      });

      _notify(
        'Subcoleção "$nomeOriginal" carregada.',
        type: NotificationType.success,
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }

      _notify(
        'Erro ao buscar subcoleção',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _replicarSubcolecao(
      String nomeOriginal,
      String nomeNovo,
      ) async {
    if (nomeOriginal.isEmpty || nomeNovo.isEmpty) {
      _notify(
        'Informe os nomes da subcoleção original e nova.',
        type: NotificationType.warning,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final colName = _collectionCtrl.text.trim();

      if (colName.isEmpty) {
        _notify(
          'Informe o nome da coleção principal.',
          type: NotificationType.warning,
        );
        return;
      }

      final parentSnapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      for (final parentDoc in parentSnapshot.docs) {
        final subRefOriginal = parentDoc.reference.collection(nomeOriginal);
        final subSnapshot = await subRefOriginal.get();

        for (final doc in subSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          final novosDados = <String, dynamic>{};

          for (final entry in data.entries) {
            final oldField = entry.key;

            final mapping = _mappingForField(oldField);

            final newField = _formatarNome(mapping.newFieldCtrl.text.trim());
            final tipo = mapping.selectedType;

            novosDados[newField] = _converterTipo(entry.value, tipo);
          }

          await parentDoc.reference
              .collection(nomeNovo)
              .doc(doc.id)
              .set(novosDados);
        }

        for (final doc in subSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      _notify(
        'Subcoleção "$nomeOriginal" renomeada e original removida.',
        type: NotificationType.success,
      );
    } catch (e) {
      _notify(
        'Erro ao renomear subcoleção',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      firestoreData = null;
      _ultimaSubcolecaoBuscada = null;
    });

    try {
      final colName = _collectionCtrl.text.trim();

      if (colName.isEmpty) {
        _notify(
          'Informe o nome da coleção principal.',
          type: NotificationType.warning,
        );
        return;
      }

      final snapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          firestoreData = {};
          isLoading = false;
          _disposeFieldMappings();
        });

        _notify(
          'Nenhum documento na coleção "$colName".',
          type: NotificationType.warning,
        );
        return;
      }

      final result = <String, dynamic>{};

      final docsToProcess =
      _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;

      for (final doc in docsToProcess) {
        result[doc.id] = Map<String, dynamic>.from(doc.data());
      }

      setState(() {
        firestoreData = result;
        isLoading = false;
        _ultimaSubcolecaoBuscada = null;
        _preencherCamposAutomaticamente();
      });

      _notify(
        'Coleção "$colName" carregada.',
        type: NotificationType.success,
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }

      _notify(
        'Erro ao carregar coleção',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  void _preencherCamposAutomaticamente() {
    if (firestoreData == null || firestoreData!.isEmpty) return;

    final firstDoc = firestoreData!.values.first;

    if (firstDoc is! Map<String, dynamic>) return;

    _disposeFieldMappings();

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

  void _disposeFieldMappings() {
    for (final mapping in _fieldMappings) {
      mapping.dispose();
    }

    _fieldMappings.clear();
  }

  FieldMapping _mappingForField(String oldField) {
    for (final mapping in _fieldMappings) {
      if (mapping.oldFieldCtrl.text.trim() == oldField) {
        return mapping;
      }
    }

    return FieldMapping(
      oldFieldCtrl: TextEditingController(text: oldField),
      newFieldCtrl: TextEditingController(text: _formatarNome(oldField)),
      selectedType: 'string',
    );
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

    if (origem.isEmpty || destino.isEmpty) {
      _notify(
        'Informe a coleção de origem e a nova coleção.',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final origemCol = FirebaseFirestore.instance.collection(origem);
      final destinoCol = FirebaseFirestore.instance.collection(destino);
      final snapshot = await origemCol.get();

      if (snapshot.docs.isEmpty) {
        _notify(
          'A coleção "$origem" está vazia.',
          type: NotificationType.warning,
        );
        return;
      }

      for (final doc in snapshot.docs) {
        final novoData = <String, dynamic>{};

        doc.data().forEach((key, value) {
          novoData[_formatarNome(key)] = value;
        });

        await destinoCol.doc(doc.id).set(novoData);
      }

      _notify(
        'Coleção "$origem" copiada para "$destino".',
        type: NotificationType.success,
      );
    } catch (e) {
      _notify(
        'Erro ao copiar coleção',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _replicarECriarColecoesDeArrays() async {
    final origem = _collectionCtrl.text.trim();
    final destino = _newCollectionCtrl.text.trim().isEmpty
        ? origem
        : _newCollectionCtrl.text.trim();

    if (origem.isEmpty) {
      _notify(
        'Informe a coleção de origem.',
        type: NotificationType.warning,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final origemCol = FirebaseFirestore.instance.collection(origem);
      final destinoCol = FirebaseFirestore.instance.collection(destino);
      final snapshot = await origemCol.get();

      if (snapshot.docs.isEmpty) {
        _notify(
          'A coleção "$origem" está vazia.',
          type: NotificationType.warning,
        );
        return;
      }

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
            final subcollectionRef =
            destinoCol.doc(doc.id).collection(subcollectionName);

            for (final item in value) {
              if (item is Map) {
                final novoMap = <String, dynamic>{};

                item.forEach((k, v) {
                  novoMap[_formatarNome(k.toString())] = v;
                });

                await subcollectionRef.add(novoMap);
              } else {
                await subcollectionRef.add({'valor': item});
              }
            }
          }
        }
      }

      _notify(
        'Coleção replicada e arrays convertidos para subcoleções.',
        type: NotificationType.success,
      );
    } catch (e) {
      _notify(
        'Erro na conversão de arrays',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _renomearCamposNaSubcolecao(String nomeSubcolecao) async {
    final colName = _collectionCtrl.text.trim();

    if (colName.isEmpty || nomeSubcolecao.isEmpty) {
      _notify(
        'Informe a coleção principal e a subcoleção.',
        type: NotificationType.warning,
      );
      return;
    }

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();

    if (snapshot.docs.isEmpty) {
      _notify(
        'Nenhum documento na coleção "$colName".',
        type: NotificationType.warning,
      );
      return;
    }

    final parentDocs =
    _somentePrimeiroDocSub ? [snapshot.docs.first] : snapshot.docs;

    for (final parentDoc in parentDocs) {
      final subSnapshot =
      await parentDoc.reference.collection(nomeSubcolecao).get();

      for (final doc in subSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final novosDados = <String, dynamic>{};
        final deletarCampos = <String, dynamic>{};

        for (final entry in data.entries) {
          final oldField = entry.key;
          final mapping = _mappingForField(oldField);

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

    _notify(
      'Campos renomeados em "$nomeSubcolecao".',
      type: NotificationType.success,
    );
  }

  Future<void> _renomearCampos() async {
    final colName = _collectionCtrl.text.trim();

    if (colName.isEmpty) {
      _notify(
        'Informe o nome da coleção principal.',
        type: NotificationType.warning,
      );
      return;
    }

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();

    if (snapshot.docs.isEmpty) {
      _notify(
        'Nenhum documento na coleção "$colName".',
        type: NotificationType.warning,
      );
      return;
    }

    final docsToProcess =
    _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;

    for (final doc in docsToProcess) {
      final data = doc.data();

      for (final map in _fieldMappings) {
        final oldField = map.oldFieldCtrl.text.trim();
        final newField = _formatarNome(map.newFieldCtrl.text.trim());

        if (oldField.isEmpty ||
            newField.isEmpty ||
            !data.containsKey(oldField)) {
          continue;
        }

        final converted = _converterTipo(
          data[oldField],
          map.selectedType,
        );

        if (newField != oldField) {
          await doc.reference.update({newField: converted});
          await doc.reference.update({oldField: FieldValue.delete()});
        } else {
          await doc.reference.update({newField: converted});
        }
      }
    }

    _notify(
      'Campos renomeados com sucesso!',
      type: NotificationType.success,
    );

    await _loadData();
  }

  dynamic _converterTipo(dynamic valor, String tipo) {
    switch (tipo) {
      case 'string':
        return valor?.toString();

      case 'number':
        if (valor is num) return valor;

        final clean = valor
            .toString()
            .replaceAll(RegExp(r'[^\d,.-]'), '')
            .replaceAll('.', '')
            .replaceAll(',', '.');

        return num.tryParse(clean) ?? 0;

      case 'boolean':
        final v = valor.toString().trim().toLowerCase();

        return v == 'true' ||
            v == '1' ||
            v == 'sim' ||
            v == 's' ||
            v == 'yes';

      case 'timestamp':
        if (valor is Timestamp) return valor;
        if (valor is DateTime) return Timestamp.fromDate(valor);

        if (valor is String) {
          final parsed = DateTime.tryParse(valor);

          if (parsed != null) {
            return Timestamp.fromDate(parsed);
          }
        }

        return Timestamp.now();

      case 'list':
        if (valor is List) return valor;

        return [valor];

      case 'network':
        if (valor is Map) {
          return valor.map(
                (k, v) => MapEntry(k.toString(), v),
          );
        }

        return <String, dynamic>{};

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
        const Text(
          'Renomear campos do firestore:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(_fieldMappings.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: CustomTextField(
                    controller: _fieldMappings[i].oldFieldCtrl,
                    labelText: 'Campo original',
                    enabled: false,
                    valueColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  child: CustomTextField(
                    controller: _fieldMappings[i].newFieldCtrl,
                    labelText: 'Novo nome',
                    valueColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _fieldMappings[i].selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'string',
                      child: Text('String'),
                    ),
                    DropdownMenuItem(
                      value: 'number',
                      child: Text('Number'),
                    ),
                    DropdownMenuItem(
                      value: 'boolean',
                      child: Text('Boolean'),
                    ),
                    DropdownMenuItem(
                      value: 'timestamp',
                      child: Text('Timestamp'),
                    ),
                    DropdownMenuItem(
                      value: 'list',
                      child: Text('List'),
                    ),
                    DropdownMenuItem(
                      value: 'network',
                      child: Text('Map'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _fieldMappings[i].selectedType = value;
                    });
                  },
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () async {
            final confirmar = await confirmDialog(
              context,
              _ultimaSubcolecaoBuscada != null
                  ? 'Deseja renomear os campos da subcoleção "${_ultimaSubcolecaoBuscada!}"?'
                  : 'Tem certeza que deseja renomear os campos da coleção principal?',
            );

            if (confirmar != true) return;

            setState(() => isLoading = true);

            try {
              if (_ultimaSubcolecaoBuscada != null) {
                await _renomearCamposNaSubcolecao(
                  _ultimaSubcolecaoBuscada!,
                );
              } else {
                await _renomearCampos();
              }
            } catch (e) {
              _notify(
                'Erro ao renomear campos',
                subtitle: '$e',
                type: NotificationType.error,
                duration: const Duration(seconds: 6),
              );
            } finally {
              if (mounted) {
                setState(() => isLoading = false);
              }
            }
          },
          child: const Text(
            'Renomear campos e converter tipos',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('ID')),
              ...allKeys.map((k) {
                return DataColumn(label: Text(k));
              }),
            ],
            rows: docIds.map((id) {
              final rawDoc = data[id];

              final doc = rawDoc is Map<String, dynamic>
                  ? rawDoc
                  : Map<String, dynamic>.from(rawDoc as Map);

              return DataRow(
                cells: [
                  DataCell(Text(id)),
                  ...allKeys.map((k) {
                    final v = doc[k];
                    final val = _prepareForJson(v);

                    return DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          val.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
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
    if (firestoreData == null) {
      _notify(
        'Nenhum dado para exportar.',
        type: NotificationType.warning,
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      _prepareForJson(firestoreData),
    );

    downloadJson('firestore_dump.json', jsonStr);
  }

  void _exportarComoCSV() {
    if (firestoreData == null) {
      _notify(
        'Nenhum dado para exportar.',
        type: NotificationType.warning,
      );
      return;
    }

    final buffer = StringBuffer();
    final keys = _fieldMappings.map((e) => e.oldFieldCtrl.text).toList();

    buffer.writeln('ID,${keys.join(",")}');

    firestoreData!.forEach((id, data) {
      final map = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      final values = keys.map((k) {
        final prepared = _prepareForJson(map[k] ?? '');
        final escaped = prepared.toString().replaceAll('"', '""');

        return '"$escaped"';
      }).join(',');

      buffer.writeln('$id,$values');
    });

    downloadCsv('firestore_dump.csv', buffer.toString());
  }

  dynamic _prepareForJson(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is GeoPoint) {
      return {
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is Map) {
      return value.map(
            (k, v) => MapEntry(k.toString(), _prepareForJson(v)),
      );
    }

    if (value is List) {
      return value.map(_prepareForJson).toList();
    }

    return value;
  }

  String _formatarNome(String original) {
    final semAcentos = _removerAcentos(original);

    return semAcentos
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  String _removerAcentos(String str) {
    const com =
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const sem =
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    for (int i = 0; i < com.length; i++) {
      str = str.replaceAll(com[i], sem[i]);
    }

    return str;
  }
}