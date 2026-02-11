import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class FirebaseMigrationToolkitPage extends StatefulWidget {
  final String? initialPath;
  final String? title;

  const FirebaseMigrationToolkitPage({
    super.key,
    this.initialPath,
    this.title,
  });

  @override
  State<FirebaseMigrationToolkitPage> createState() =>
      _FirebaseMigrationToolkitPageState();
}

class _FirebaseMigrationToolkitPageState
    extends State<FirebaseMigrationToolkitPage> {
  late final TextEditingController _pathCtrl;
  late final TextEditingController _targetPathCtrl;

  bool _isLoading = false;
  bool _isCopying = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  /// Snapshot completo dos documentos
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  /// Lista simples de IDs (para facilitar em alguns pontos da UI)
  List<String> _docIds = [];

  /// IDs selecionados (via checkbox do documento)
  Set<String> _selectedIds = {};

  /// Campos selecionados por documento: docId -> { fieldName1, fieldName2, ... }
  final Map<String, Set<String>> _selectedFieldsByDocId = {};

  bool get _isAllSelected =>
      _docIds.isNotEmpty && _selectedIds.length == _docIds.length;

  @override
  void initState() {
    super.initState();
    _pathCtrl = TextEditingController(text: widget.initialPath ?? '');
    _targetPathCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _targetPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    final path = _pathCtrl.text.trim();

    if (path.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o caminho da coleção de origem.';
        _docs = [];
        _docIds = [];
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoaded = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _docs = [];
      _docIds = [];
      _selectedIds.clear();
      _selectedFieldsByDocId.clear();
      _hasLoaded = false;
    });

    try {
      final snap = await FirebaseFirestore.instance.collection(path).get();
      final docs = snap.docs;
      final ids = docs.map((d) => d.id).toList();

      if (!mounted) return;
      setState(() {
        _docs = docs;
        _docIds = ids;
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoaded = true;
      });

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Coleção carregada'),
          subtitle: Text('Encontrados ${ids.length} documentos em "$path".'),
          type: AppNotificationType.success,
          leadingLabel: const Text('Firebase'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar coleção: $e';
        _docs = [];
        _docIds = [];
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoaded = true;
      });

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao carregar coleção'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Firebase'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectAllDocs() {
    setState(() {
      if (_isAllSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds = _docIds.toSet();
      }
    });
  }

  /// Selecionar / desmarcar todos os campos de um documento
  void _toggleSelectAllFieldsForDoc(String docId, Map<String, dynamic> data) {
    final keys = data.keys.toList();
    setState(() {
      final current = _selectedFieldsByDocId[docId] ?? <String>{};
      final allSelected = keys.isNotEmpty && current.length == keys.length;
      if (allSelected) {
        _selectedFieldsByDocId[docId] = <String>{};
      } else {
        _selectedFieldsByDocId[docId] = keys.toSet();
      }
    });
  }

  /// Campo individual de um documento
  void _toggleFieldSelection(String docId, String fieldName, bool selected) {
    setState(() {
      final set = _selectedFieldsByDocId.putIfAbsent(docId, () => <String>{});
      if (selected) {
        set.add(fieldName);
      } else {
        set.remove(fieldName);
      }
    });
  }

  /// Verifica se um campo está selecionado em todos os documentos que possuem esse campo.
  bool _isFieldSelectedInAllDocs(String fieldName) {
    int docsWithField = 0;
    int docsWithFieldSelected = 0;

    for (final doc in _docs) {
      final data = doc.data();
      if (data.containsKey(fieldName)) {
        docsWithField++;
        final selectedFields = _selectedFieldsByDocId[doc.id] ?? <String>{};
        if (selectedFields.contains(fieldName)) {
          docsWithFieldSelected++;
        }
      }
    }

    return docsWithField > 0 && docsWithField == docsWithFieldSelected;
  }

  /// Define seleção (true/false) de um campo para todos os documentos que possuem esse campo.
  void _setFieldSelectionForAllDocs(String fieldName, bool selected) {
    setState(() {
      for (final doc in _docs) {
        final data = doc.data();
        if (!data.containsKey(fieldName)) continue;

        final docId = doc.id;
        final set = _selectedFieldsByDocId.putIfAbsent(docId, () => <String>{});

        if (selected) {
          set.add(fieldName);
        } else {
          set.remove(fieldName);
        }
      }
    });
  }

  /// Alterna o estado do campo em todos os documentos.
  void _toggleFieldInAllDocs(String fieldName) {
    final isSelectedEverywhere = _isFieldSelectedInAllDocs(fieldName);
    _setFieldSelectionForAllDocs(fieldName, !isSelectedEverywhere);
  }

  String _stringifyFieldValue(dynamic value) {
    if (value == null) return 'null';
    var s = value.toString();
    if (s.length > 200) {
      s = '${s.substring(0, 197)}...';
    }
    return s;
  }

  /// Copia campos selecionados para a coleção destino.
  ///
  /// Regra:
  /// - Para cada doc selecionado:
  ///   - Se houver campos selecionados para o doc: copia apenas esses campos.
  ///   - Caso contrário: copia todos os campos do doc.
  Future<void> _copySelectedToTarget() async {
    final sourcePath = _pathCtrl.text.trim();
    final targetPath = _targetPathCtrl.text.trim();

    if (sourcePath.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Origem não informada'),
          subtitle: Text('Informe o caminho da coleção de origem.'),
          type: AppNotificationType.error,
          leadingLabel: Text('Firebase'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (targetPath.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Destino não informado'),
          subtitle: Text('Informe o caminho da coleção destino.'),
          type: AppNotificationType.error,
          leadingLabel: Text('Firebase'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_selectedIds.isEmpty) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Nenhum documento selecionado'),
          subtitle: Text('Selecione ao menos um documento para copiar.'),
          type: AppNotificationType.info,
          leadingLabel: Text('Firebase'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isCopying = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      int ops = 0;

      for (final doc in _docs) {
        final docId = doc.id;
        if (!_selectedIds.contains(docId)) continue;

        final data = doc.data();
        final selectedFields = _selectedFieldsByDocId[docId];

        Map<String, dynamic> toCopy;

        if (selectedFields != null && selectedFields.isNotEmpty) {
          toCopy = {
            for (final key in selectedFields)
              if (data.containsKey(key)) key: data[key],
          };
        } else {
          // Nenhum campo específico selecionado -> copia todos do doc
          toCopy = Map<String, dynamic>.from(data);
        }

        if (toCopy.isEmpty) continue;

        final targetRef =
        FirebaseFirestore.instance.collection(targetPath).doc(docId);

        batch.set(targetRef, toCopy, SetOptions(merge: true));
        ops++;
      }

      if (ops == 0) {
        NotificationCenter.instance.show(
          AppNotification(
            title: Text('Nada para copiar'),
            subtitle: Text(
                'Nenhum campo selecionado ou dados vazios nos documentos escolhidos.'),
            type: AppNotificationType.info,
            leadingLabel: Text('Firebase'),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        await batch.commit();

        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('Cópia concluída'),
            subtitle: Text(
                'Campos copiados para "$targetPath" em $ops documento(s).'),
            type: AppNotificationType.success,
            leadingLabel: const Text('Firebase'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao copiar campos'),
          subtitle: Text('$e'),
          type: AppNotificationType.error,
          leadingLabel: const Text('Firebase'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCopying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0;
    final topPadding = topSafe + barHeight + 12;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          bottom: false,
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),

          ),
        ),
        toolbarHeight: barHeight,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) {
            maxW = 1000;
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 4, 6),
                    child: Text(
                      'Explorador de coleção',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  const Text(
                    'Informe o caminho da coleção de origem para listar os IDs '
                        'dos documentos e visualizar seus campos.\n\n'
                        'Exemplos de origem:\n'
                        ' - accidents\n'
                        ' - operation/abc123/accidents\n'
                        ' - contracts/xyz789/measurements',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Campo origem + botão "Carregar"
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _pathCtrl,
                          labelText: 'Coleção de origem',
                          onSubmitted: (_) => _loadCollection(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadCollection,
                          icon: _isLoading
                              ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Carregar'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Novo campo: coleção destino
                  CustomTextField(
                    controller: _targetPathCtrl,
                    labelText: 'Coleção destino (para cópia)',
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_hasLoaded && _docIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Nenhum documento encontrado para esta coleção.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    )
                  else if (_docIds.isNotEmpty) ...[
                      // Selecionar todos os documentos
                      Row(
                        children: [
                          Checkbox(
                            value: _isAllSelected,
                            onChanged: (_) => _toggleSelectAllDocs(),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Selecionar todos os documentos',
                            style: TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            'Selecionados: ${_selectedIds.length}/${_docIds.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _docs.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                          itemBuilder: (context, index) {
                            final doc = _docs[index];
                            final id = doc.id;
                            final data = doc.data();
                            final fieldKeys = data.keys.toList()..sort();
                            final selectedFieldSet =
                                _selectedFieldsByDocId[id] ?? <String>{};
                            final allFieldsSelected =
                                fieldKeys.isNotEmpty &&
                                    selectedFieldSet.length == fieldKeys.length;
                            final isDocSelected = _selectedIds.contains(id);

                            return ExpansionTile(
                              tilePadding:
                              const EdgeInsets.symmetric(horizontal: 8.0),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                8,
                              ),
                              leading: Checkbox(
                                value: isDocSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedIds.add(id);
                                    } else {
                                      _selectedIds.remove(id);
                                    }
                                  });
                                },
                              ),
                              title: Text(
                                id,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              visualDensity: VisualDensity.compact,
                              children: [
                                const SizedBox(height: 4),

                                // Linha: selecionar todos os campos desse doc
                                Row(
                                  children: [
                                    Checkbox(
                                      value: allFieldsSelected,
                                      onChanged: (_) => _toggleSelectAllFieldsForDoc(
                                        id,
                                        data,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Selecionar todos os campos deste documento',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Campos: ${selectedFieldSet.length}/${fieldKeys.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                if (fieldKeys.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'Documento sem campos (vazio).',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: fieldKeys.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                    itemBuilder: (context, fieldIndex) {
                                      final fieldName = fieldKeys[fieldIndex];
                                      final fieldValue = data[fieldName];
                                      final isFieldSelected =
                                      selectedFieldSet.contains(fieldName);

                                      final isFieldSelectedEverywhere =
                                      _isFieldSelectedInAllDocs(fieldName);

                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: Checkbox(
                                          value: isFieldSelected,
                                          onChanged: (value) {
                                            _toggleFieldSelection(
                                              id,
                                              fieldName,
                                              value == true,
                                            );
                                          },
                                        ),
                                        title: Text(
                                          fieldName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _stringifyFieldValue(fieldValue),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          tooltip: isFieldSelectedEverywhere
                                              ? 'Desmarcar este campo em todos os documentos'
                                              : 'Marcar este campo em todos os documentos',
                                          icon: Icon(
                                            isFieldSelectedEverywhere
                                                ? Icons.select_all
                                                : Icons.all_inclusive,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _toggleFieldInAllDocs(fieldName);
                                          },
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: (_isCopying || _selectedIds.isEmpty)
                              ? null
                              : _copySelectedToTarget,
                          icon: _isCopying
                              ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.copy_all_outlined, size: 18),
                          label: const Text('Copiar campos selecionados'),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
