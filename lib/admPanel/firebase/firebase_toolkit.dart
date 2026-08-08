// lib/screens/common/adm/firebase_toolkit.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/admPanel/bloc/firebase_admin_cubit.dart';
import 'package:sipged/admPanel/bloc/firebase_admin_data.dart';
import 'package:sipged/admPanel/bloc/firebase_admin_state.dart';

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
  late final TextEditingController _sourcePathCtrl;
  late final TextEditingController _targetPathCtrl;
  late final TextEditingController _previewPathCtrl;
  late final TextEditingController _previewLimitCtrl;

  bool _isPreviewLoading = false;
  bool _hasLoadedPreview = false;

  String? _errorMessage;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];

  @override
  void initState() {
    super.initState();

    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    _tenantIdCtrl = TextEditingController(
      text: tenantId,
    );

    _sourcePathCtrl = TextEditingController(
      text: FirebaseAdminTenantPaths.legacyContractsRootPath,
    );

    _targetPathCtrl = TextEditingController(
      text:
      'tenants/$tenantId/contracts/{contractId}/hiring/main/{publicacao|arquivamento}/main',
    );

    _previewPathCtrl = TextEditingController(
      text: 'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao',
    );

    _previewLimitCtrl = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    _tenantIdCtrl.dispose();
    _sourcePathCtrl.dispose();
    _targetPathCtrl.dispose();
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

  bool _containsTemplateValue(String path) {
    return path.contains('{') || path.contains('}');
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

  Future<void> _loadPreview() async {
    final adminCubit = context.read<FirebaseAdminCubit>();

    final path = _previewPathCtrl.text.trim();

    if (path.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o caminho da coleção para prévia.';
        _docs = [];
        _hasLoadedPreview = false;
      });
      return;
    }

    if (_containsTemplateValue(path)) {
      setState(() {
        _errorMessage =
        'Substitua os valores entre chaves, como {contractId}, por IDs reais antes de carregar a prévia.';
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
      final docs = await adminCubit.previewCollection(
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

  Future<void> _migratePublicationAndArchiveToFixedTenant() async {
    final adminCubit = context.read<FirebaseAdminCubit>();

    final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

    const sourceRootPath = FirebaseAdminTenantPaths.legacyContractsRootPath;

    final targetRootPath =
        'tenants/$tenantId/contracts/{contractId}/hiring/main';

    final confirmed = await _confirmMigration(
      title: 'Migrar Publicação e Arquivamento',
      buttonLabel: 'Migrar Publicação/Arquivamento',
      icon: Icons.account_tree_outlined,
      content: 'Origem:\n\n'
          '$sourceRootPath/{contractId}/publicacao/{docId}/...\n'
          '$sourceRootPath/{contractId}/arquivamento/{docId}/...\n\n'
          'Destino:\n\n'
          '$targetRootPath/publicacao/main/...\n'
          '$targetRootPath/arquivamento/main/...\n\n'
          'Estrutura final esperada:\n\n'
          '$targetRootPath/publicacao/main/metadados/main\n'
          '$targetRootPath/publicacao/main/partes/main\n'
          '$targetRootPath/publicacao/main/veiculo/main\n'
          '$targetRootPath/publicacao/main/status/main\n'
          '$targetRootPath/publicacao/main/responsavel/main\n\n'
          '$targetRootPath/arquivamento/main/metadados/main\n'
          '$targetRootPath/arquivamento/main/motivo/main\n'
          '$targetRootPath/arquivamento/main/fundamentacao/main\n'
          '$targetRootPath/arquivamento/main/pecas/main\n'
          '$targetRootPath/arquivamento/main/decisao/main\n'
          '$targetRootPath/arquivamento/main/reabertura/main\n\n'
          'Tenant usado:\n\n'
          '$tenantId\n\n'
          'Regras aplicadas:\n\n'
          '- Copia Publicação do Extrato e Termo de Arquivamento\n'
          '- Copia o documento principal para o doc main\n'
          '- Copia as seções oficiais para docs main\n'
          '- Usa merge no destino\n'
          '- Ignora documentos já existentes no destino\n'
          '- Grava tenantId e companyId como $tenantId\n'
          '- Grava contractId, uidContract e uidcontract\n'
          '- Adiciona metadados de migração\n'
          '- Atualiza recordPath/sourcePath/path quando existirem\n\n'
          'Essa operação apenas copia. Ela não apaga dados da origem.\n\n'
          'Depois de validar a cópia no novo caminho, os dados antigos poderão ser removidos com mais segurança.\n\n'
          'Deseja continuar?',
    );

    if (!mounted || !confirmed) return;

    try {
      await adminCubit.migrateLegacyPublicationAndArchiveToFixedTenant();
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
        'Migração ativa: contracts/{contractId}/{publicacao|arquivamento}/* → '
            'tenants/$tenantId/contracts/{contractId}/hiring/main/{publicacao|arquivamento}/main/*. '
            'Os documentos já existentes no destino são ignorados. '
            'A operação copia Publicação do Extrato, Termo de Arquivamento e suas seções conhecidas, sem apagar a origem.',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }

  void _setPreviewPathWithContractWarning(String path) {
    setState(() {
      _previewPathCtrl.text = path;
    });

    _showMessage(
      'Substitua {contractId} pelo ID real do contrato antes de carregar a prévia.',
      backgroundColor: Colors.orange.shade700,
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
              _previewPathCtrl.text = 'contracts';
            });
          },
          icon: const Icon(Icons.folder_outlined, size: 16),
          label: const Text('contracts legado'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'contracts/{contractId}/publicacao',
            );
          },
          icon: const Icon(Icons.article_outlined, size: 16),
          label: const Text('Publicação legado'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'contracts/{contractId}/publicacao/{pubId}/veiculo',
            );
          },
          icon: const Icon(Icons.article_outlined, size: 16),
          label: const Text('Publicação seção legado'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'contracts/{contractId}/arquivamento',
            );
          },
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: const Text('Arquivamento legado'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'contracts/{contractId}/arquivamento/{taId}/pecas',
            );
          },
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: const Text('Arquivamento seção legado'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _previewPathCtrl.text = 'tenants/$tenantId/contracts';
            });
          },
          icon: const Icon(Icons.business_outlined, size: 16),
          label: const Text('contracts tenant'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring',
            );
          },
          icon: const Icon(Icons.work_outline, size: 16),
          label: const Text('hiring'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main',
            );
          },
          icon: const Icon(Icons.work_outline, size: 16),
          label: const Text('hiring/main'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação hiring'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao/main/metadados',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação metadados'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao/main/partes',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação partes'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao/main/veiculo',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação veículo'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao/main/status',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação status'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/publicacao/main/responsavel',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Publicação responsável'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento hiring'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/metadados',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento metadados'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/motivo',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento motivo'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/fundamentacao',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento fundamentação'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/pecas',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento peças'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/decisao',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento decisão'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _setPreviewPathWithContractWarning(
              'tenants/$tenantId/contracts/{contractId}/hiring/main/arquivamento/main/reabertura',
            );
          },
          icon: const Icon(Icons.folder_copy_outlined, size: 16),
          label: const Text('Arquivamento reabertura'),
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

  Widget _buildResultBox(FirebaseAdminState state) {
    final result = state.result;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final entries = result.details.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total principal: ${result.total}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map(
                (entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),
        ],
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
          backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
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
                            'Use esta tela para copiar Publicação do Extrato e Termo de Arquivamento legados para a estrutura hiring/main dentro do contrato multi-tenant.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                          _buildMigrationInfoBox(),
                          _sectionTitle('Destino fixo da migração'),
                          CustomTextField(
                            controller: _tenantIdCtrl,
                            enabled: false,
                            labelText: 'Tenant ID fixo',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _sourcePathCtrl,
                            enabled: false,
                            labelText: 'Origem dos contratos legados',
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _targetPathCtrl,
                            enabled: false,
                            labelText:
                            'Destino da Publicação e do Arquivamento',
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Migração da contratação'),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _migratePublicationAndArchiveToFixedTenant,
                                icon: const Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Migrar Publicação e Arquivamento',
                                ),
                              ),
                            ],
                          ),
                          _buildResultBox(state),
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