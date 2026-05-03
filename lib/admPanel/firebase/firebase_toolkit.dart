import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/adm/firebase_admin_cubit.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

class FirebaseToolkit extends StatelessWidget {
  const FirebaseToolkit({
    super.key,
    this.initialPath,
    this.initialTargetPath,
    this.title,
  });

  final String? initialPath;
  final String? initialTargetPath;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAdminCubit(),
      child: _FirebaseToolkitView(
        initialPath: initialPath,
        initialTargetPath: initialTargetPath,
        title: title,
      ),
    );
  }
}

class _FirebaseToolkitView extends StatefulWidget {
  const _FirebaseToolkitView({
    this.initialPath,
    this.initialTargetPath,
    this.title,
  });

  final String? initialPath;
  final String? initialTargetPath;
  final String? title;

  @override
  State<_FirebaseToolkitView> createState() => _FirebaseToolkitViewState();
}

class _FirebaseToolkitViewState extends State<_FirebaseToolkitView> {
  late final TextEditingController _tenantIdCtrl;
  late final TextEditingController _pathCtrl;
  late final TextEditingController _targetPathCtrl;
  late final TextEditingController _subcollectionsCtrl;
  late final TextEditingController _previewLimitCtrl;
  late final TextEditingController _pageSizeCtrl;
  late final TextEditingController _batchSizeCtrl;

  bool _isPreviewLoading = false;
  bool _hasLoadedPreview = false;

  bool _copyAllDocuments = true;
  bool _skipExisting = true;
  bool _merge = true;
  bool _addMigrationMetadata = true;
  bool _copySubcollectionsWhenParentExists = true;
  bool _rewriteDocumentPathFields = true;

  String? _errorMessage;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  List<String> _docIds = [];
  Set<String> _selectedIds = {};

  final Map<String, Set<String>> _selectedFieldsByDocId = {};

  bool get _isAllSelected {
    return _docIds.isNotEmpty && _selectedIds.length == _docIds.length;
  }

  @override
  void initState() {
    super.initState();

    _tenantIdCtrl = TextEditingController();
    _pathCtrl = TextEditingController(text: widget.initialPath ?? 'empenhos');
    _targetPathCtrl = TextEditingController(
      text: widget.initialTargetPath ?? '',
    );
    _subcollectionsCtrl = TextEditingController();

    _previewLimitCtrl = TextEditingController(text: '50');
    _pageSizeCtrl = TextEditingController(text: '50');
    _batchSizeCtrl = TextEditingController(text: '25');

    _tenantIdCtrl.addListener(_refreshTargetPresetIfNeeded);
  }

  @override
  void dispose() {
    _tenantIdCtrl.removeListener(_refreshTargetPresetIfNeeded);

    _tenantIdCtrl.dispose();
    _pathCtrl.dispose();
    _targetPathCtrl.dispose();
    _subcollectionsCtrl.dispose();
    _previewLimitCtrl.dispose();
    _pageSizeCtrl.dispose();
    _batchSizeCtrl.dispose();

    super.dispose();
  }

  Future<void> _migrateLegacyCompanyToTenant() async {
    final tenantId = _tenantIdCtrl.text.trim();

    if (tenantId.isEmpty) {
      _showMessage(
        'Informe o Tenant ID antes de migrar o system/company.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final targetDocPath = FirebaseAdminSetupTenantPaths.tenantDocPath(tenantId);
    final rules = FirebaseAdminSetupTenantPaths.migrationRules(tenantId);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Migrar company para tenant'),
          content: SingleChildScrollView(
            child: Text(
              'Documento principal:\n\n'
                  '${FirebaseAdminSetupTenantPaths.legacyCompanyDocPath}\n'
                  '→ $targetDocPath\n\n'
                  'Subcoleções remapeadas:\n\n'
                  '${rules.map((rule) {
                return 'system/company/${rule.sourceSubcollection}\n'
                    '→ ${rule.targetCollectionPath}';
              }).join('\n\n')}\n\n'
                  'Isso copiará o documento principal da empresa e redistribuirá '
                  'as antigas subcoleções para a nova estrutura multi-tenant.\n\n'
                  'Deseja continuar?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('Migrar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await context.read<FirebaseAdminCubit>().migrateLegacyCompanyToTenant(
        tenantId: tenantId,
        merge: true,
        skipExisting: false,
        addMigrationMetadata: true,
        rewriteDocumentPathFields: true,
        copySubcollectionsWhenTargetExists: true,
      );
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  void _refreshTargetPresetIfNeeded() {
    final currentTarget = _targetPathCtrl.text.trim();

    if (!currentTarget.startsWith('tenants/')) return;

    final parts = currentTarget
        .split('/')
        .where((item) => item.trim().isNotEmpty)
        .toList();

    if (parts.length < 3) return;
    if (parts[0] != 'tenants') return;

    final relativePath = parts.skip(2).join('/');

    if (relativePath.isEmpty) return;

    final newTarget = _tenantCollectionTargetPath(relativePath);

    if (newTarget == currentTarget) return;

    _targetPathCtrl.text = newTarget;
  }

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
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  bool _isValidCollectionPath(String path) {
    final parts = path
        .trim()
        .split('/')
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return parts.isNotEmpty && parts.length.isOdd;
  }

  int _intFromController(
      TextEditingController controller, {
        required int fallback,
        required int min,
        required int max,
      }) {
    final raw = controller.text.trim();
    final parsed = int.tryParse(raw);

    if (parsed == null) return fallback;

    return parsed.clamp(min, max);
  }

  List<String> _subcollectionsFromController() {
    return _subcollectionsCtrl.text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  String _tenantCollectionTargetPath(String relativePath) {
    final tenantId = _tenantIdCtrl.text.trim();

    final cleanPath = relativePath
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join('/');

    if (tenantId.isEmpty) {
      return 'tenants/{tenantId}/$cleanPath';
    }

    return 'tenants/$tenantId/$cleanPath';
  }

  void _applyMigrationPreset({
    required String sourcePath,
    required String targetRelativePath,
    List<String> subcollectionsToCopy = const <String>[],
  }) {
    setState(() {
      _pathCtrl.text = sourcePath;
      _targetPathCtrl.text = _tenantCollectionTargetPath(targetRelativePath);
      _subcollectionsCtrl.text = subcollectionsToCopy.join(', ');

      _docs = [];
      _docIds = [];
      _selectedIds.clear();
      _selectedFieldsByDocId.clear();

      _hasLoadedPreview = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    final path = _pathCtrl.text.trim();

    if (path.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o caminho da coleção de origem.';
        _docs = [];
        _docIds = [];
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoadedPreview = false;
      });
      return;
    }

    if (!_isValidCollectionPath(path)) {
      setState(() {
        _errorMessage =
        'Caminho de origem inválido. Informe um caminho de coleção, não de documento.';
        _docs = [];
        _docIds = [];
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoadedPreview = false;
      });
      return;
    }

    final previewLimit = _intFromController(
      _previewLimitCtrl,
      fallback: 50,
      min: 1,
      max: 200,
    );

    setState(() {
      _isPreviewLoading = true;
      _errorMessage = null;
      _docs = [];
      _docIds = [];
      _selectedIds.clear();
      _selectedFieldsByDocId.clear();
      _hasLoadedPreview = false;
    });

    try {
      final docs = await context.read<FirebaseAdminCubit>().previewCollection(
        path: path,
        limit: previewLimit,
      );

      final ids = docs.map((doc) => doc.id).toList();

      if (!mounted) return;

      setState(() {
        _docs = docs;
        _docIds = ids;
        _selectedIds = ids.toSet();
        _selectedFieldsByDocId.clear();
        _hasLoadedPreview = true;
      });

      _showMessage(
        'Prévia carregada: ${ids.length} documento(s) exibido(s) em "$path".',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar prévia: $e';
        _docs = [];
        _docIds = [];
        _selectedIds.clear();
        _selectedFieldsByDocId.clear();
        _hasLoadedPreview = true;
      });

      _showMessage(
        'Erro ao carregar prévia: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewLoading = false;
        });
      }
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

  void _setFieldSelectionForAllDocs(String fieldName, bool selected) {
    setState(() {
      for (final doc in _docs) {
        final data = doc.data();

        if (!data.containsKey(fieldName)) continue;

        final set = _selectedFieldsByDocId.putIfAbsent(
          doc.id,
              () => <String>{},
        );

        if (selected) {
          set.add(fieldName);
        } else {
          set.remove(fieldName);
        }
      }
    });
  }

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

  Future<bool> _confirmCopy({
    required String sourcePath,
    required String targetPath,
    required int selectedPreviewCount,
    required bool copyAllDocuments,
  }) async {
    final pageSize = _intFromController(
      _pageSizeCtrl,
      fallback: 50,
      min: 1,
      max: 200,
    );

    final batchSize = _intFromController(
      _batchSizeCtrl,
      fallback: 25,
      min: 1,
      max: 100,
    );

    final subcollections = _subcollectionsFromController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Confirmar cópia'),
          content: Text(
            'Origem:\n$sourcePath\n\n'
                'Destino:\n$targetPath\n\n'
                'Escopo: ${copyAllDocuments ? "copiar coleção inteira" : "copiar documentos selecionados na prévia"}\n'
                'Selecionados na prévia: $selectedPreviewCount\n\n'
                'Subcoleções: ${subcollections.isEmpty ? "(nenhuma)" : subcollections.join(", ")}\n'
                'Copiar subcoleções mesmo se o pai já existir: ${_copySubcollectionsWhenParentExists ? "sim" : "não"}\n'
                'Atualizar recordPath/sourcePath: ${_rewriteDocumentPathFields ? "sim" : "não"}\n\n'
                'Page size: $pageSize\n'
                'Batch size: $batchSize\n\n'
                'Ignorar já existentes: ${_skipExisting ? "sim" : "não"}\n'
                'Modo: ${_merge ? "merge / preserva campos existentes" : "sobrescrever documento"}\n'
                'Metadados: ${_addMigrationMetadata ? "sim" : "não"}\n\n'
                'Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Copiar'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _copySelectedToTarget() async {
    final sourcePath = _pathCtrl.text.trim();
    final targetPath = _targetPathCtrl.text.trim();

    if (sourcePath.isEmpty) {
      _showMessage(
        'Informe o caminho da coleção de origem.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (!_isValidCollectionPath(sourcePath)) {
      _showMessage(
        'Caminho de origem inválido. Informe um caminho de coleção.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (targetPath.isEmpty || targetPath.contains('{tenantId}')) {
      _showMessage(
        'Informe o Tenant ID para montar o caminho destino corretamente.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (!_isValidCollectionPath(targetPath)) {
      _showMessage(
        'Caminho de destino inválido. Informe um caminho de coleção.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (!_copyAllDocuments && _selectedIds.isEmpty) {
      _showMessage(
        'Selecione ao menos um documento na prévia ou marque "Copiar coleção inteira".',
        backgroundColor: Colors.blueGrey.shade700,
      );
      return;
    }

    final confirmed = await _confirmCopy(
      sourcePath: sourcePath,
      targetPath: targetPath,
      selectedPreviewCount: _selectedIds.length,
      copyAllDocuments: _copyAllDocuments,
    );

    if (!mounted || !confirmed) return;

    try {
      final params = FirebaseCopyCollectionParams(
        sourcePath: sourcePath,
        targetPath: targetPath,
        docIds: _copyAllDocuments ? const <String>[] : _selectedIds.toList(),
        selectedFieldsByDocId: Map<String, Set<String>>.from(
          _selectedFieldsByDocId,
        ),
        copyAllDocuments: _copyAllDocuments,
        skipExisting: _skipExisting,
        merge: _merge,
        addMigrationMetadata: _addMigrationMetadata,
        pageSize: _intFromController(
          _pageSizeCtrl,
          fallback: 50,
          min: 1,
          max: 200,
        ),
        batchSize: _intFromController(
          _batchSizeCtrl,
          fallback: 25,
          min: 1,
          max: 100,
        ),
        subcollectionsToCopy: _subcollectionsFromController(),
        copySubcollectionsWhenParentExists:
        _copySubcollectionsWhenParentExists,
        rewriteDocumentPathFields: _rewriteDocumentPathFields,
      );

      await context.read<FirebaseAdminCubit>().copyCollectionDocuments(params);
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  Widget _buildPresetButton({
    required String label,
    required String sourcePath,
    required String targetRelativePath,
    List<String> subcollectionsToCopy = const <String>[],
    IconData icon = Icons.account_tree_outlined,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        _applyMigrationPreset(
          sourcePath: sourcePath,
          targetRelativePath: targetRelativePath,
          subcollectionsToCopy: subcollectionsToCopy,
        );
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _buildSummaryCard() {
    final sourcePath = _pathCtrl.text.trim();
    final targetPath = _targetPathCtrl.text.trim();
    final subcollections = _subcollectionsFromController();

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.24),
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prévia da operação',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text('Origem: ${sourcePath.isEmpty ? "(não informado)" : sourcePath}'),
            Text('Destino: ${targetPath.isEmpty ? "(não informado)" : targetPath}'),
            Text('Subcoleções: ${subcollections.isEmpty ? "(nenhuma)" : subcollections.join(", ")}'),
            Text('Documentos carregados na prévia: ${_docIds.length}'),
            Text('Documentos selecionados na prévia: ${_selectedIds.length}'),
            Text(
              'Escopo da cópia: ${_copyAllDocuments ? "coleção inteira" : "somente selecionados na prévia"}',
            ),
            Text('Page size: ${_pageSizeCtrl.text.trim()}'),
            Text('Batch size: ${_batchSizeCtrl.text.trim()}'),
            Text('Modo de gravação: ${_merge ? "merge" : "sobrescrever"}'),
            Text('Ignorar documentos já existentes: ${_skipExisting ? "sim" : "não"}'),
            Text('Metadados de migração: ${_addMigrationMetadata ? "sim" : "não"}'),
            Text(
              'Copiar subcoleções se pai já existir: ${_copySubcollectionsWhenParentExists ? "sim" : "não"}',
            ),
            Text(
              'Atualizar recordPath/sourcePath: ${_rewriteDocumentPathFields ? "sim" : "não"}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(FirebaseAdminState state) {
    if (!state.isLoading) {
      return const SizedBox.shrink();
    }

    final hasProgress = state.hasProgress;

    final percent = hasProgress
        ? (state.progressValue * 100).clamp(0, 100).toStringAsFixed(1)
        : null;

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingTreeDots(size: 76),
                const SizedBox(height: 12),
                Text(
                  state.progressLabel ?? 'Processando operação...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (state.progressDetail != null &&
                    state.progressDetail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.progressDetail!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (hasProgress)
                  LinearProgressIndicator(value: state.progressValue)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                if (hasProgress)
                  Text(
                    '${state.progressCurrent}/${state.progressTotal} documento(s) — $percent%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  )
                else
                  const Text(
                    'Preparando...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Não feche esta tela até a operação terminar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewList({
    required bool isCopying,
  }) {
    if (_isPreviewLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: LoadingTreeDots(size: 90),
        ),
      );
    }

    if (_hasLoadedPreview && _docIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'Nenhum documento encontrado para esta coleção.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      );
    }

    if (_docIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _isAllSelected,
              onChanged: isCopying ? null : (_) => _toggleSelectAllDocs(),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Selecionar todos os documentos exibidos na prévia',
                style: TextStyle(fontSize: 13),
              ),
            ),
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

              final allFieldsSelected = fieldKeys.isNotEmpty &&
                  selectedFieldSet.length == fieldKeys.length;

              final isDocSelected = _selectedIds.contains(id);

              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                leading: Checkbox(
                  value: isDocSelected,
                  onChanged: isCopying
                      ? null
                      : (value) {
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
                  Row(
                    children: [
                      Checkbox(
                        value: allFieldsSelected,
                        onChanged: isCopying
                            ? null
                            : (_) => _toggleSelectAllFieldsForDoc(
                          id,
                          data,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Selecionar todos os campos deste documento',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
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
                        'Documento sem campos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                            onChanged: isCopying
                                ? null
                                : (value) {
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
                                ? 'Desmarcar este campo em todos os documentos exibidos'
                                : 'Marcar este campo em todos os documentos exibidos',
                            icon: Icon(
                              isFieldSelectedEverywhere
                                  ? Icons.select_all
                                  : Icons.all_inclusive,
                              size: 18,
                            ),
                            onPressed: isCopying
                                ? null
                                : () {
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
      ],
    );
  }

  Widget _buildBooleanOptions({
    required bool isCopying,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _copyAllDocuments,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _copyAllDocuments = value ?? true;
                });
              },
            ),
            const Text(
              'Copiar coleção inteira',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _skipExisting,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _skipExisting = value ?? true;
                });
              },
            ),
            const Text(
              'Ignorar já existentes',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _merge,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _merge = value ?? true;
                });
              },
            ),
            const Text(
              'Usar merge',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _addMigrationMetadata,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _addMigrationMetadata = value ?? true;
                });
              },
            ),
            const Text(
              'Adicionar metadados',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _copySubcollectionsWhenParentExists,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _copySubcollectionsWhenParentExists = value ?? true;
                });
              },
            ),
            const Text(
              'Copiar subcoleções se pai já existir',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _rewriteDocumentPathFields,
              onChanged: isCopying
                  ? null
                  : (value) {
                setState(() {
                  _rewriteDocumentPathFields = value ?? true;
                });
              },
            ),
            const Text(
              'Atualizar recordPath/sourcePath',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0;
    final topPadding = topSafe + barHeight + 12;

    return BlocConsumer<FirebaseAdminCubit, FirebaseAdminState>(
      listenWhen: (previous, current) {
        return previous.message != current.message && current.message != null;
      },
      listener: (context, state) {
        final isError = state.status == FirebaseAdminStatus.failure;

        _showMessage(
          state.message!,
          backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
          duration:
          isError ? const Duration(seconds: 6) : const Duration(seconds: 4),
        );
      },
      builder: (context, state) {
        final isCopying = state.isLoading;

        return Stack(
          children: [
            Scaffold(
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
                      child: CircleButtonChange(),
                    ),
                  ),
                ),
                toolbarHeight: barHeight,
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  double maxW = constraints.maxWidth;

                  if (constraints.maxWidth >= 1600) {
                    maxW = 1100;
                  }

                  if (constraints.maxWidth >= 1200 &&
                      constraints.maxWidth < 1600) {
                    maxW = 1000;
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                        children: [

                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Setup / Empresa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isCopying ? null : _migrateLegacyCompanyToTenant,
                                icon: const Icon(Icons.business_outlined, size: 16),
                                label: const Text('system/company → tenants/{tenantId}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                            child: Text(
                              widget.title ??
                                  'Migrar dados financeiros para tenant',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Text(
                            'Use esta tela para copiar coleções legadas para a estrutura multi-tenant. '
                                'Para empenhos, a origem padrão é "empenhos" e o destino é '
                                '"tenants/{tenantId}/financial/empenhos/items".',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _tenantIdCtrl,
                            labelText: 'Tenant ID / ID da empresa',
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Financeiro',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetButton(
                                label: 'Empenhos → financial/empenhos/items',
                                sourcePath: 'empenhos',
                                targetRelativePath:
                                FirebaseAdminTenantPaths
                                    .financialEmpenhosRelativePath,
                                icon: Icons.assignment_turned_in_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _pathCtrl,
                            labelText: 'Coleção de origem',
                            onSubmitted: (_) => _loadPreview(),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _targetPathCtrl,
                            labelText: 'Coleção destino',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _subcollectionsCtrl,
                            labelText:
                            'Subcoleções para copiar. Ex: records',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 180,
                                child: CustomTextField(
                                  controller: _previewLimitCtrl,
                                  labelText: 'Prévia',
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: CustomTextField(
                                  controller: _pageSizeCtrl,
                                  labelText: 'Page size',
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: CustomTextField(
                                  controller: _batchSizeCtrl,
                                  labelText: 'Batch size',
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: (_isPreviewLoading || isCopying)
                                      ? null
                                      : _loadPreview,
                                  icon: _isPreviewLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: LoadingTreeDots(
                                      size: 20,
                                      centered: false,
                                    ),
                                  )
                                      : const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Carregar prévia'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildBooleanOptions(isCopying: isCopying),
                          _buildSummaryCard(),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildPreviewList(isCopying: isCopying),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed:
                              isCopying ? null : _copySelectedToTarget,
                              icon: const Icon(
                                Icons.copy_all_outlined,
                                size: 18,
                              ),
                              label: const Text('Iniciar cópia'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildProgressOverlay(state),
          ],
        );
      },
    );
  }
}