import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'firestore_export_stub.dart';

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
  final TextEditingController _collectionCtrl =
  TextEditingController(text: 'operation');
  final TextEditingController _newCollectionCtrl = TextEditingController();

  final List<FieldMapping> _fieldMappings = <FieldMapping>[];
  final List<Map<String, TextEditingController>> _subcollections =
  <Map<String, TextEditingController>>[];

  Map<String, dynamic>? firestoreData;

  bool isLoading = false;
  bool _somentePrimeiroDoc = true;
  bool _somentePrimeiroDocSub = true;

  String? _ultimaSubcolecaoBuscada;

  static const List<String> _typeOptions = <String>[
    'string',
    'number',
    'boolean',
    'timestamp',
    'list',
    'map',
  ];

  void _showMessage(
      String message, {
        Color? backgroundColor,
        Duration duration = const Duration(seconds: 4),
      }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: backgroundColor,
        ),
      );
  }

  @override
  void dispose() {
    _collectionCtrl.dispose();
    _newCollectionCtrl.dispose();

    _disposeFieldMappings();

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
                  _buildMainPanel(),
                  ..._subcollections.map(_buildSubcollectionPanel),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _adicionarSubcolecao,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar subcoleção'),
                    ),
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
                    _multiDocTable(firestoreData!),
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

  Widget _buildMainPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: CustomTextField(
              enabled: true,
              controller: _collectionCtrl,
              labelText: 'Nome da coleção principal',
            ),
          ),
          SizedBox(
            width: 280,
            child: CustomTextField(
              controller: _newCollectionCtrl,
              labelText: 'Nome da nova coleção',
            ),
          ),
          SizedBox(
            width: 260,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Apenas 1º documento',
                style: TextStyle(fontSize: 13),
              ),
              value: _somentePrimeiroDoc,
              onChanged: (value) {
                setState(() {
                  _somentePrimeiroDoc = value;
                });
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.search),
            label: const Text('Buscar coleção'),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _confirmarCopiarColecao,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy),
            label: const Text('Duplicar coleção'),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _confirmarTransformarArrays,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Arrays → subcoleções'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcollectionPanel(Map<String, TextEditingController> pair) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: CustomTextField(
                controller: pair['old']!,
                labelText: 'Subcoleção original',
                valueColor: Colors.black,
              ),
            ),
            SizedBox(
              width: 260,
              child: CustomTextField(
                controller: pair['new']!,
                labelText: 'Nova subcoleção',
                valueColor: Colors.black,
              ),
            ),
            SizedBox(
              width: 280,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Apenas 1º doc. da subcoleção',
                  style: TextStyle(fontSize: 13),
                ),
                value: _somentePrimeiroDocSub,
                onChanged: (value) {
                  setState(() {
                    _somentePrimeiroDocSub = value;
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _buscarSubcolecao(
                pair['old']!.text.trim(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.search),
              label: const Text('Buscar subcoleção'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _confirmarReplicarSubcolecao(
                pair['old']!.text.trim(),
                pair['new']!.text.trim(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.copy),
              label: const Text('Renomear subcoleção'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarCopiarColecao() async {
    final confirmar = await confirmDialog(
      context,
      'Deseja realmente duplicar esta coleção?\n\n'
          'A coleção original não será apagada.',
    );

    if (confirmar == true) {
      await _copiarColecao();
    }
  }

  Future<void> _confirmarTransformarArrays() async {
    final confirmar = await confirmDialog(
      context,
      'Deseja realmente transformar os arrays em subcoleções?\n\n'
          'Os campos do tipo array não serão copiados como campos simples no documento de destino.',
    );

    if (confirmar == true) {
      await _replicarECriarColecoesDeArrays();
    }
  }

  Future<void> _confirmarReplicarSubcolecao(
      String nomeOriginal,
      String nomeNovo,
      ) async {
    final confirmar = await confirmDialog(
      context,
      'Deseja realmente renomear esta subcoleção?\n\n'
          'Origem: $nomeOriginal\n'
          'Destino: $nomeNovo\n\n'
          'A subcoleção original será apagada após a cópia.',
    );

    if (confirmar == true) {
      await _replicarSubcolecao(nomeOriginal, nomeNovo);
    }
  }

  void _adicionarSubcolecao() {
    setState(() {
      _subcollections.add({
        'old': TextEditingController(),
        'new': TextEditingController(),
      });
    });
  }

  Future<void> _buscarSubcolecao(String nomeOriginal) async {
    if (nomeOriginal.isEmpty) {
      _showMessage(
        'Informe a subcoleção original para buscar.',
        backgroundColor: Colors.orange.shade700,
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
        _showMessage(
          'Informe o nome da coleção principal.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      final parentSnapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      if (parentSnapshot.docs.isEmpty) {
        _showMessage(
          'Nenhum documento na coleção "$colName".',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      final parentDocs =
      _somentePrimeiroDocSub ? [parentSnapshot.docs.first] : parentSnapshot.docs;

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

      if (!mounted) return;

      setState(() {
        firestoreData = result;
        _ultimaSubcolecaoBuscada = nomeOriginal;
        _preencherCamposAutomaticamente();
      });

      _showMessage(
        'Subcoleção "$nomeOriginal" carregada.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showMessage(
        'Erro ao buscar subcoleção: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _replicarSubcolecao(
      String nomeOriginal,
      String nomeNovo,
      ) async {
    if (nomeOriginal.isEmpty || nomeNovo.isEmpty) {
      _showMessage(
        'Informe os nomes da subcoleção original e nova.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final colName = _collectionCtrl.text.trim();

      if (colName.isEmpty) {
        _showMessage(
          'Informe o nome da coleção principal.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      final parentSnapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      if (parentSnapshot.docs.isEmpty) {
        _showMessage(
          'Nenhum documento na coleção "$colName".',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      int copied = 0;
      int deleted = 0;

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

            if (newField.isEmpty) continue;

            novosDados[newField] = _converterTipo(entry.value, tipo);
          }

          await parentDoc.reference
              .collection(nomeNovo)
              .doc(doc.id)
              .set(novosDados, SetOptions(merge: true));

          copied++;
        }

        for (final doc in subSnapshot.docs) {
          await doc.reference.delete();
          deleted++;
        }
      }

      _showMessage(
        'Subcoleção renomeada. Copiados: $copied • Apagados: $deleted',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showMessage(
        'Erro ao renomear subcoleção: $e',
        backgroundColor: Colors.red.shade700,
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
      _disposeFieldMappings();
    });

    try {
      final colName = _collectionCtrl.text.trim();

      if (colName.isEmpty) {
        _showMessage(
          'Informe o nome da coleção principal.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      final snapshot =
      await FirebaseFirestore.instance.collection(colName).get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          firestoreData = <String, dynamic>{};
        });

        _showMessage(
          'Nenhum documento na coleção "$colName".',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      final result = <String, dynamic>{};
      final docsToProcess =
      _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;

      for (final doc in docsToProcess) {
        result[doc.id] = Map<String, dynamic>.from(doc.data());
      }

      if (!mounted) return;

      setState(() {
        firestoreData = result;
        _ultimaSubcolecaoBuscada = null;
        _preencherCamposAutomaticamente();
      });

      _showMessage(
        'Coleção "$colName" carregada.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showMessage(
        'Erro ao carregar coleção: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    final found = _fieldMappings.where(
          (mapping) => mapping.oldFieldCtrl.text.trim() == oldField,
    );

    if (found.isNotEmpty) {
      return found.first;
    }

    final mapping = FieldMapping(
      oldFieldCtrl: TextEditingController(text: oldField),
      newFieldCtrl: TextEditingController(text: _formatarNome(oldField)),
      selectedType: 'string',
    );

    _fieldMappings.add(mapping);

    return mapping;
  }

  String _detectarTipo(dynamic valor) {
    if (valor is String) return 'string';
    if (valor is num) return 'number';
    if (valor is bool) return 'boolean';
    if (valor is Timestamp || valor is DateTime) return 'timestamp';
    if (valor is List) return 'list';
    if (valor is Map) return 'map';

    return 'string';
  }

  Future<void> _copiarColecao() async {
    final origem = _collectionCtrl.text.trim();
    final destino = _newCollectionCtrl.text.trim();

    if (origem.isEmpty || destino.isEmpty) {
      _showMessage(
        'Informe a coleção de origem e a nova coleção.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final origemCol = FirebaseFirestore.instance.collection(origem);
      final destinoCol = FirebaseFirestore.instance.collection(destino);
      final snapshot = await origemCol.get();

      if (snapshot.docs.isEmpty) {
        _showMessage(
          'A coleção "$origem" está vazia.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      int count = 0;

      for (final doc in snapshot.docs) {
        final novoData = <String, dynamic>{};

        doc.data().forEach((key, value) {
          novoData[_formatarNome(key)] = value;
        });

        await destinoCol.doc(doc.id).set(novoData, SetOptions(merge: true));
        count++;
      }

      _showMessage(
        'Coleção copiada: "$origem" → "$destino" • $count documentos',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showMessage(
        'Erro ao copiar coleção: $e',
        backgroundColor: Colors.red.shade700,
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
      _showMessage(
        'Informe a coleção de origem.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final origemCol = FirebaseFirestore.instance.collection(origem);
      final destinoCol = FirebaseFirestore.instance.collection(destino);
      final snapshot = await origemCol.get();

      if (snapshot.docs.isEmpty) {
        _showMessage(
          'A coleção "$origem" está vazia.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      int docs = 0;
      int subDocs = 0;

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final novoData = <String, dynamic>{};

        data.forEach((key, value) {
          if (value is! List) {
            novoData[_formatarNome(key)] = value;
          }
        });

        await destinoCol.doc(doc.id).set(novoData, SetOptions(merge: true));
        docs++;

        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is! List) continue;

          final subcollectionName = _formatarNome(key);
          if (subcollectionName.isEmpty) continue;

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

            subDocs++;
          }
        }
      }

      _showMessage(
        'Arrays convertidos. Docs: $docs • Subdocs: $subDocs',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showMessage(
        'Erro na conversão de arrays: $e',
        backgroundColor: Colors.red.shade700,
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
      _showMessage(
        'Informe a coleção principal e a subcoleção.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();

    if (snapshot.docs.isEmpty) {
      _showMessage(
        'Nenhum documento na coleção "$colName".',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final parentDocs =
    _somentePrimeiroDocSub ? [snapshot.docs.first] : snapshot.docs;

    int updated = 0;

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

          if (newField.isEmpty) continue;

          novosDados[newField] = _converterTipo(entry.value, tipo);

          if (newField != oldField) {
            deletarCampos[oldField] = FieldValue.delete();
          }
        }

        if (novosDados.isNotEmpty) {
          await doc.reference.update(novosDados);
        }

        if (deletarCampos.isNotEmpty) {
          await doc.reference.update(deletarCampos);
        }

        updated++;
      }
    }

    _showMessage(
      'Campos renomeados em "$nomeSubcolecao". $updated documentos atualizados.',
      backgroundColor: Colors.green.shade700,
    );
  }

  Future<void> _renomearCampos() async {
    final colName = _collectionCtrl.text.trim();

    if (colName.isEmpty) {
      _showMessage(
        'Informe o nome da coleção principal.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final col = FirebaseFirestore.instance.collection(colName);
    final snapshot = await col.get();

    if (snapshot.docs.isEmpty) {
      _showMessage(
        'Nenhum documento na coleção "$colName".',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final docsToProcess =
    _somentePrimeiroDoc ? [snapshot.docs.first] : snapshot.docs;

    int updated = 0;

    for (final doc in docsToProcess) {
      final data = doc.data();
      final novosDados = <String, dynamic>{};
      final deletarCampos = <String, dynamic>{};

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

        novosDados[newField] = converted;

        if (newField != oldField) {
          deletarCampos[oldField] = FieldValue.delete();
        }
      }

      if (novosDados.isNotEmpty) {
        await doc.reference.update(novosDados);
      }

      if (deletarCampos.isNotEmpty) {
        await doc.reference.update(deletarCampos);
      }

      updated++;
    }

    _showMessage(
      'Campos renomeados. $updated documentos atualizados.',
      backgroundColor: Colors.green.shade700,
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
        if (valor == null) return <dynamic>[];

        return <dynamic>[valor];

      case 'map':
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
          'Renomear campos do Firestore:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: List.generate(_fieldMappings.length, (i) {
            return SizedBox(
              width: 560,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: CustomTextField(
                      controller: _fieldMappings[i].oldFieldCtrl,
                      labelText: 'Campo original',
                      enabled: false,
                      valueColor: Colors.black,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: CustomTextField(
                      controller: _fieldMappings[i].newFieldCtrl,
                      labelText: 'Novo nome',
                      valueColor: Colors.black,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _normalizeType(_fieldMappings[i].selectedType),
                      items: _typeOptions.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(_labelType(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _fieldMappings[i].selectedType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading ? null : _confirmarRenomearCampos,
            icon: const Icon(Icons.drive_file_rename_outline),
            label: const Text('Renomear campos e converter tipos'),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('ID')),
              ...allKeys.map((k) => DataColumn(label: Text(k))),
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

  Future<void> _confirmarRenomearCampos() async {
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
        await _renomearCamposNaSubcolecao(_ultimaSubcolecaoBuscada!);
      } else {
        await _renomearCampos();
      }
    } catch (e) {
      _showMessage(
        'Erro ao renomear campos: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _normalizeType(String type) {
    if (type == 'network') return 'map';
    if (_typeOptions.contains(type)) return type;

    return 'string';
  }

  String _labelType(String type) {
    switch (type) {
      case 'string':
        return 'String';
      case 'number':
        return 'Number';
      case 'boolean':
        return 'Boolean';
      case 'timestamp':
        return 'Timestamp';
      case 'list':
        return 'List';
      case 'map':
        return 'Map';
      default:
        return type;
    }
  }

  void _exportarComoJson() {
    if (firestoreData == null) {
      _showMessage(
        'Nenhum dado para exportar.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      _prepareForJson(firestoreData),
    );

    downloadJson('firestore_dump.json', jsonStr);

    _showMessage(
      'JSON exportado.',
      backgroundColor: Colors.green.shade700,
    );
  }

  void _exportarComoCSV() {
    if (firestoreData == null) {
      _showMessage(
        'Nenhum dado para exportar.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final buffer = StringBuffer();
    final keys = _fieldMappings.map((e) => e.oldFieldCtrl.text).toList();

    buffer.writeln('ID,${keys.map(_escapeCsv).join(",")}');

    firestoreData!.forEach((id, data) {
      final map = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      final values = keys.map((k) {
        final prepared = _prepareForJson(map[k] ?? '');
        return _escapeCsv(prepared.toString());
      }).join(',');

      buffer.writeln('${_escapeCsv(id)},$values');
    });

    downloadCsv('firestore_dump.csv', buffer.toString());

    _showMessage(
      'CSV exportado.',
      backgroundColor: Colors.green.shade700,
    );
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
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
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .trim();
  }

  String _removerAcentos(String str) {
    const com =
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const sem =
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    var result = str;

    for (int i = 0; i < com.length; i++) {
      result = result.replaceAll(com[i], sem[i]);
    }

    return result;
  }
}