// lib/screens/modules/contracts/budget/budget_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_budget.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';
import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;

class BudgetPage extends StatefulWidget {
  const BudgetPage({
    super.key,
    required this.contractData,
  });

  final ContractData contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late String _activeTenantId;
  late DfdRepository _dfdRepository;

  bool _saving = false;
  DfdData? _dfdData;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractSummary {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    if (_contractId.isNotEmpty) return 'Contrato $_contractId';

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    _activeTenantId = _resolveRequiredTenantId(
      context.read<PermissionCubit>().state,
    );

    _dfdRepository = DfdRepository(
      tenantId: _activeTenantId,
    );

    _loadDfdDisplayData();
  }

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para BudgetPage.');
    }

    return tenantId;
  }

  void _handlePermissionStateChanged(PermissionState permissionState) {
    final nextTenantId = _resolveRequiredTenantId(permissionState);

    if (nextTenantId == _activeTenantId) return;

    setState(() {
      _activeTenantId = nextTenantId;
      _dfdRepository = DfdRepository(
        tenantId: _activeTenantId,
      );
      _dfdData = null;
    });

    _loadDfdDisplayData();
  }

  Future<void> _loadDfdDisplayData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    try {
      final dfd = await _dfdRepository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = widget.contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final fullName = (meta['fullName'] ??
            meta['displayName'] ??
            meta['nameComplete'] ??
            meta['nomeCompleto'] ??
            meta['nome'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? meta['nome'] ?? '').toString().trim();

        final surname =
        (meta['surname'] ?? meta['sobrenome'] ?? '').toString().trim();

        final composed = <String>[
          name,
          surname,
        ].where((item) => item.trim().isNotEmpty).join(' ').trim();

        if (composed.isNotEmpty) return composed;

        final email = (meta['email'] ?? '').toString().trim();
        if (email.isNotEmpty) return email;
      }
    }

    final displayName = currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = currentUser?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _showNotification({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Iterable<String> targetUserIds = const <String>[],
    bool includeCurrentUser = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    final cleanTitle = title.trim();
    final cleanSubtitle = subtitle?.trim();
    final cleanDetails = details?.trim();

    await NotificationBudget.show(
      context: context,
      contract: widget.contractData,
      title: cleanTitle.isEmpty ? 'Orçamento' : cleanTitle,
      subtitle: cleanSubtitle?.isNotEmpty == true ? cleanSubtitle : null,
      details:
      cleanDetails?.isNotEmpty == true ? cleanDetails : _contractSummary,
      leadingLabel: 'Orçamento',
      module: 'contracts_budget',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      targetUserIds: targetUserIds,
      includeCurrentUser: includeCurrentUser,
      delivery: NotificationDelivery.localBellAndPush,
      extra: <String, dynamic>{
        'tenantId': _activeTenantId,
        'companyId': _activeTenantId,
        'module': 'contracts_budget',
        'route': 'contracts_budget',
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'processNumber': _contractNumber,
        'processoAdministrativo': _dfdData?.processoAdministrativo,
        'contractSummary': _contractSummary,
        'contractTitle': _contractSummary,
        'descricaoObjeto': _dfdData?.descricaoObjeto,
        'actorId': currentUserId,
        'actorName': actorName,
        'sendPush': sendPush,
        'source': 'budget_notification',
        'sourceKey': 'budget_general',
        'subSource': 'budget_general',
        'notificationSource': 'budget_general',
        ...extra,
      },
    );
  }

  Future<void> _load(
      BudgetCubit cubit,
      bc.MagicTableController ctrl,
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );

      await _showNotification(
        title: 'Contrato inválido',
        subtitle: 'Não foi possível carregar o orçamento.',
        details: 'O identificador do contrato está vazio.',
        type: NotificationStatus.warning,
        saveInBell: false,
        sendPush: false,
      );

      return;
    }

    await cubit.ensureFor(cleanContractId);

    final data = cubit.state.dataFor(cleanContractId);

    if (data == null || data.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    BudgetCubit.loadControllerFromDomain(
      controller: ctrl,
      data: data,
    );
  }

  Future<void> _saveNow(
      BudgetCubit cubit,
      bc.MagicTableController controller,
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      await _showNotification(
        title: 'Contrato inválido',
        subtitle: 'Não foi possível identificar o contrato.',
        type: NotificationStatus.error,
        saveInBell: false,
        sendPush: false,
      );
      return;
    }

    if (_saving) return;

    setState(() => _saving = true);

    try {
      final domain = BudgetCubit.buildDomainFromController(
        controller: controller,
      );

      await cubit.saveDomain(
        contractId: cleanContractId,
        data: domain,
      );

      if (!mounted) return;

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

      await _showNotification(
        title: 'Orçamento atualizado',
        subtitle: 'Alterações salvas por $actorName.',
        details: _contractSummary,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        includeCurrentUser: true,
        extra: <String, dynamic>{
          'tenantId': _activeTenantId,
          'companyId': _activeTenantId,
          'action': 'budget_updated',
          'contractId': cleanContractId,
          'route': 'contracts_budget',
          'source': 'budget_notification',
          'sourceKey': 'budget_general',
          'subSource': 'budget_general',
          'notificationSource': 'budget_general',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _showNotification(
        title: 'Falha ao salvar orçamento',
        subtitle: e.toString(),
        details: _contractSummary,
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        saveInBell: false,
        sendPush: false,
        extra: <String, dynamic>{
          'tenantId': _activeTenantId,
          'companyId': _activeTenantId,
          'action': 'budget_update_error',
          'contractId': cleanContractId,
          'route': 'contracts_budget',
          'source': 'budget_notification',
          'sourceKey': 'budget_general',
          'subSource': 'budget_general',
          'notificationSource': 'budget_general',
          'error': e.toString(),
        },
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handlePaste(
      bc.MagicTableController controller,
      ) async {
    await controller.pasteFromClipboard();
  }

  Future<void> _handleSave(
      BudgetCubit cubit,
      bc.MagicTableController controller,
      String contractId,
      ) async {
    if (!controller.hasData) {
      await _showNotification(
        title: 'Nada para salvar',
        subtitle: 'Cole dados do Excel antes de salvar.',
        type: NotificationStatus.info,
        saveInBell: false,
        sendPush: false,
      );
      return;
    }

    await _saveNow(
      cubit,
      controller,
      contractId,
    );
  }

  List<Widget> _buildFloatingActions({
    required BuildContext context,
    required bc.MagicTableController controller,
    required BudgetCubit cubit,
    required String contractId,
    required bool isBusy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return <Widget>[
      _BudgetFloatingActionButton(
        icon: Icons.content_paste_go_rounded,
        title: 'Colar Excel',
        subtitle: 'Ctrl + V',
        enabled: !isBusy,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        borderColor: colorScheme.outlineVariant,
        onTap: () => _handlePaste(controller),
      ),
      const SizedBox(height: 10),
      _BudgetFloatingActionButton(
        icon: Icons.save_rounded,
        title: _saving ? 'Salvando...' : 'Salvar',
        subtitle: 'Firestore',
        enabled: !isBusy,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        borderColor: colorScheme.primary,
        onTap: () => _handleSave(
          cubit,
          controller,
          contractId,
        ),
      ),
    ];
  }

  Widget _buildLoadingOverlay({
    required BuildContext context,
    required bool isSaving,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: <Widget>[
        const ModalBarrier(
          dismissible: false,
          color: Colors.black38,
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  blurRadius: 18,
                  spreadRadius: 1,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const LoadingTreeDots(
                  size: 28,
                  centered: false,
                ),
                const SizedBox(width: 12),
                Text(
                  isSaving
                      ? 'Salvando orçamento...'
                      : 'Carregando orçamento...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractId = _contractId;

    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        _handlePermissionStateChanged(permissionState);
      },
      child: BlocProvider<BudgetCubit>(
        key: ValueKey<String>(
          'budget_cubit_${_activeTenantId}_$contractId',
        ),
        create: (_) => BudgetCubit(
          tenantId: _activeTenantId,
        ),
        child: ChangeNotifierProvider<bc.MagicTableController>(
          create: (_) => bc.MagicTableController(
            cellPadHorizontal: const EdgeInsets.symmetric(
              horizontal: 12,
            ).horizontal,
          ),
          builder: (context, _) {
            final ctrl = context.watch<bc.MagicTableController>();
            final cubit = context.read<BudgetCubit>();

            final isLoading = context.select<BudgetCubit, bool>(
                  (c) => c.state.loadingFor(contractId),
            );

            final isBusy = isLoading || _saving;

            return Scaffold(
              appBar: UpBar(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: CircleButtonChange(),
                ),
              ),
              body: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: BackgroundChange(),
                  ),
                  Positioned.fill(
                    child: MagicTableChanged(
                      selectAllOnEdit: false,
                      controller: ctrl,
                      onInit: (c) => _load(
                        cubit,
                        c,
                        contractId,
                      ),
                      allowAddColumn: false,
                      allowRemoveColumn: false,
                      allowAddRow: false,
                      onRequestSaveAfterStructureChange: (c) {
                        return _saveNow(
                          cubit,
                          c,
                          contractId,
                        );
                      },
                      bottomScrollGap: 32,
                      rightScrollGap: 190,
                      floatingActionsBuilder: (ctx, c) {
                        return _buildFloatingActions(
                          context: ctx,
                          controller: c,
                          cubit: cubit,
                          contractId: contractId,
                          isBusy: isBusy,
                        );
                      },
                    ),
                  ),
                  if (isBusy)
                    _buildLoadingOverlay(
                      context: context,
                      isSaving: _saving,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetFloatingActionButton extends StatelessWidget {
  const _BudgetFloatingActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveBackgroundColor = enabled
        ? backgroundColor
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.80);

    final effectiveForegroundColor = enabled
        ? foregroundColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 164,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? borderColor.withValues(alpha: 0.70)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.50),
            ),
            boxShadow: enabled
                ? <BoxShadow>[
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: effectiveForegroundColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: effectiveForegroundColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: effectiveForegroundColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: effectiveForegroundColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}