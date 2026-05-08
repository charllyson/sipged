// lib/admPanel/firebase/firebase_toolkit.dart

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
    this.title,
  });

  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAdminCubit(),
      child: _FirebaseToolkitView(
        title: title,
      ),
    );
  }
}

class _FirebaseToolkitView extends StatefulWidget {
  const _FirebaseToolkitView({
    this.title,
  });

  final String? title;

  @override
  State<_FirebaseToolkitView> createState() => _FirebaseToolkitViewState();
}

class _FirebaseToolkitViewState extends State<_FirebaseToolkitView> {
  late final TextEditingController _tenantIdCtrl;
  late final TextEditingController _collectionGroupCtrl;
  late final TextEditingController _previewPathCtrl;
  late final TextEditingController _previewLimitCtrl;

  bool _isPreviewLoading = false;
  bool _hasLoadedPreview = false;

  String? _errorMessage;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  static const List<String> _allowedCollections = <String>[
    'orders',
    'reportsMeasurement',
    'adjustmentsMeasurement',
    'revisionsMeasurement',
  ];

  @override
  void initState() {
    super.initState();

    _tenantIdCtrl = TextEditingController(
      text: FirebaseAdminTenantPaths.fixedMigrationTenantId,
    );

    _collectionGroupCtrl = TextEditingController(text: 'orders');

    _previewPathCtrl = TextEditingController(
      text:
      'tenants/${FirebaseAdminTenantPaths.fixedMigrationTenantId}/contracts',
    );

    _previewLimitCtrl = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    _tenantIdCtrl.dispose();
    _collectionGroupCtrl.dispose();
    _previewPathCtrl.dispose();
    _previewLimitCtrl.dispose();

    super.dispose();
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

  String _selectedCollectionId() {
    final raw = _collectionGroupCtrl.text.trim();

    if (raw.isEmpty) return 'orders';

    return raw;
  }

  String _labelForCollection(String collectionId) {
    switch (collectionId) {
      case 'orders':
        return 'vigências / ordens';

      case 'reportsMeasurement':
        return 'medições executadas';

      case 'adjustmentsMeasurement':
        return 'reajustes de medições';

      case 'revisionsMeasurement':
        return 'revisões de medições';

      default:
        return collectionId;
    }
  }

  String _titleForCollection(String collectionId) {
    switch (collectionId) {
      case 'orders':
        return 'Migrar vigências / ordens';

      case 'reportsMeasurement':
        return 'Migrar medições executadas';

      case 'adjustmentsMeasurement':
        return 'Migrar reajustes de medições';

      case 'revisionsMeasurement':
        return 'Migrar revisões de medições';

      default:
        return 'Migrar collectionGroup($collectionId)';
    }
  }

  Future<void> _loadPreview() async {
    final path = _previewPathCtrl.text.trim();

    if (path.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o caminho da coleção para prévia.';
        _docs = [];
        _hasLoadedPreview = false;
      });
      return;
    }

    if (!_isValidCollectionPath(path)) {
      setState(() {
        _errorMessage =
        'Caminho inválido. Informe um caminho de coleção, não de documento.';
        _docs = [];
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
      _hasLoadedPreview = false;
    });

    try {
      final docs = await context.read<FirebaseAdminCubit>().previewCollection(
        path: path,
        limit: previewLimit,
      );

      if (!mounted) return;

      setState(() {
        _docs = docs;
        _hasLoadedPreview = true;
      });

      _showMessage(
        'Prévia carregada: ${docs.length} documento(s).',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar prévia: $e';
        _docs = [];
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

  Future<bool> _confirmMigration({
    required String title,
    required String content,
    required String buttonLabel,
    IconData icon = Icons.account_tree_outlined,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: Icon(icon, size: 18),
              label: Text(buttonLabel),
            ),
          ],
        );
      },
    );

    return mounted && confirmed == true;
  }

  Future<void> _migrateSelectedCollectionToFixedTenant() async {
    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;
    final collectionId = _selectedCollectionId();

    if (!_allowedCollections.contains(collectionId)) {
      _showMessage(
        'CollectionGroup não permitida nesta tela: "$collectionId".',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final targetRootPath = FirebaseAdminTenantPaths.contractsRootPath(tenantId);
    final label = _labelForCollection(collectionId);

    final confirmed = await _confirmMigration(
      title: _titleForCollection(collectionId),
      buttonLabel: 'Migrar',
      icon: Icons.account_tree_outlined,
      content: 'Origem:\n\n'
          'collectionGroup("$collectionId")\n\n'
          'Destino final:\n\n'
          'tenants/$tenantId/contracts/{contractId}/$collectionId/{docId}\n\n'
          'Raiz usada na operação:\n\n'
          '$targetRootPath\n\n'
          'Regras aplicadas:\n\n'
          '- Busca documentos em qualquer profundidade pelo collectionGroup("$collectionId")\n'
          '- Ignora documentos que já estão dentro de tenants/\n'
          '- Preserva o ID original do documento\n'
          '- Identifica o contractId pelo campo ou pelo caminho legado\n'
          '- Grava tenantId e companyId como $tenantId\n'
          '- Usa merge\n'
          '- Ignora documentos já existentes\n'
          '- Adiciona metadados de migração\n'
          '- Atualiza recordPath/sourcePath/path quando existirem\n\n'
          'Essa operação apenas copia. Ela não apaga dados da origem.\n\n'
          'Deseja continuar a migração de $label?',
    );

    if (!confirmed) return;

    try {
      await context.read<FirebaseAdminCubit>().copyCollectionGroupToFixedTenantContracts(
        collectionId: collectionId,
        successLabel: label,
        successTitle: 'Migração collectionGroup($collectionId)',
      );
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  Future<void> _migrateAllMeasurementsToFixedTenant() async {
    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    final confirmed = await _confirmMigration(
      title: 'Migrar todas as coleções de medições',
      buttonLabel: 'Migrar medições',
      icon: Icons.stacked_bar_chart_outlined,
      content: 'Serão copiadas as seguintes collectionGroups:\n\n'
          '- reportsMeasurement\n'
          '- adjustmentsMeasurement\n'
          '- revisionsMeasurement\n\n'
          'Destino:\n\n'
          'tenants/$tenantId/contracts/{contractId}/{collectionId}/{docId}\n\n'
          'Regras aplicadas:\n\n'
          '- Ignora documentos já existentes\n'
          '- Ignora documentos dentro de tenants/\n'
          '- Preserva o ID original\n'
          '- Grava tenantId e companyId como $tenantId\n'
          '- Usa merge\n'
          '- Não apaga dados legados\n\n'
          'Deseja continuar?',
    );

    if (!confirmed) return;

    try {
      await context
          .read<FirebaseAdminCubit>()
          .migrateAllMeasurementCollectionsToFixedTenant();
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  Future<void> _migrateAllOperationalToFixedTenant() async {
    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    final confirmed = await _confirmMigration(
      title: 'Migrar coleções operacionais do contrato',
      buttonLabel: 'Migrar tudo',
      icon: Icons.hub_outlined,
      content: 'Serão copiadas as seguintes collectionGroups:\n\n'
          '- orders\n'
          '- reportsMeasurement\n'
          '- adjustmentsMeasurement\n'
          '- revisionsMeasurement\n\n'
          'Destino:\n\n'
          'tenants/$tenantId/contracts/{contractId}/{collectionId}/{docId}\n\n'
          'Regras aplicadas:\n\n'
          '- Ignora documentos já existentes\n'
          '- Ignora documentos dentro de tenants/\n'
          '- Preserva o ID original\n'
          '- Grava tenantId e companyId como $tenantId\n'
          '- Usa merge\n'
          '- Não apaga dados legados\n\n'
          'Deseja continuar?',
    );

    if (!confirmed) return;

    try {
      await context
          .read<FirebaseAdminCubit>()
          .migrateAllContractOperationalCollectionsToFixedTenant();
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMigrationInfoBox() {
    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueGrey.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        'Migração ativa: collectionGroup("{collectionId}") → '
            'tenants/$tenantId/contracts/{contractId}/{collectionId}/{docId}. '
            'Os documentos já existentes no destino são ignorados. '
            'Documentos dentro de tenants/ também são ignorados para evitar duplicação.',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildCollectionSelector({
    required bool isLoading,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _allowedCollections.contains(_collectionGroupCtrl.text.trim())
          ? _collectionGroupCtrl.text.trim()
          : 'orders',
      decoration: const InputDecoration(
        labelText: 'CollectionGroup para copiar',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _allowedCollections.map((collectionId) {
        return DropdownMenuItem<String>(
          value: collectionId,
          child: Text(
            '$collectionId — ${_labelForCollection(collectionId)}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: isLoading
          ? null
          : (value) {
        if (value == null) return;

        setState(() {
          _collectionGroupCtrl.text = value;
          _previewPathCtrl.text =
          'tenants/${FirebaseAdminTenantPaths.fixedMigrationTenantId}/contracts';
        });
      },
    );
  }

  Widget _buildQuickPathButtons() {
    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _previewPathCtrl.text = 'tenants/$tenantId/contracts';
            });
          },
          icon: const Icon(Icons.folder_outlined, size: 16),
          label: const Text('contracts'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            final collectionId = _selectedCollectionId();

            setState(() {
              _previewPathCtrl.text =
              'tenants/$tenantId/contracts/{contractId}/$collectionId';
            });

            _showMessage(
              'Substitua {contractId} pelo ID real do contrato antes de carregar a prévia.',
              backgroundColor: Colors.orange.shade700,
            );
          },
          icon: const Icon(Icons.account_tree_outlined, size: 16),
          label: const Text('subcoleção do contrato'),
        ),
      ],
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
                    '${state.progressCurrent}/${state.progressTotal} — $percent%',
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

  Widget _buildPreviewList() {
    if (_isPreviewLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: LoadingTreeDots(size: 90),
        ),
      );
    }

    if (_hasLoadedPreview && _docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'Nenhum documento encontrado.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      );
    }

    if (_docs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
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
          final data = doc.data();
          final keys = data.keys.toList()..sort();

          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              doc.id,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              doc.reference.path,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            children: [
              if (keys.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Documento sem campos.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                )
              else
                ...keys.map(
                      (key) {
                    final value = data[key];

                    var text = value?.toString() ?? 'null';

                    if (text.length > 180) {
                      text = '${text.substring(0, 177)}...';
                    }

                    return ListTile(
                      dense: true,
                      title: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
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
        final isLoading = state.isLoading;

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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                            child: Text(
                              widget.title ?? 'Migração Firebase',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const Text(
                            'Use esta tela para copiar documentos legados para a estrutura multi-tenant dos contratos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                          _buildMigrationInfoBox(),
                          _sectionTitle('Destino fixo da cópia'),
                          CustomTextField(
                            controller: _tenantIdCtrl,
                            enabled: false,
                            labelText: 'Tenant ID fixo',
                          ),
                          const SizedBox(height: 16),
                          _sectionTitle('Cópia por collectionGroup'),
                          _buildCollectionSelector(isLoading: isLoading),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _migrateSelectedCollectionToFixedTenant,
                                icon: const Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Copiar collectionGroup selecionada',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _migrateAllMeasurementsToFixedTenant,
                                icon: const Icon(
                                  Icons.stacked_bar_chart_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Copiar medições, reajustes e revisões',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _migrateAllOperationalToFixedTenant,
                                icon: const Icon(
                                  Icons.hub_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Copiar ordens + medições',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle('Prévia de coleção'),
                          CustomTextField(
                            controller: _previewPathCtrl,
                            labelText: 'Coleção para prévia',
                            onSubmitted: (_) => _loadPreview(),
                          ),
                          const SizedBox(height: 8),
                          _buildQuickPathButtons(),
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
                                  labelText: 'Limite da prévia',
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: (_isPreviewLoading || isLoading)
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
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          _buildPreviewList(),
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