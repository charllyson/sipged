import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_budget.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/table/magic/magic_adapter.dart';
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';
import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;

class BudgetPage extends StatefulWidget {
  const BudgetPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final DfdRepository _dfdRepository = DfdRepository();

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
      details: cleanDetails?.isNotEmpty == true
          ? cleanDetails
          : _contractSummary,
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

    final st = cubit.state;
    final data = st.dataFor(cleanContractId);

    if (data == null || data.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    MagicAdapter.loadControllerFromDomain(
      controller: ctrl,
      data: data,
    );
  }

  Future<void> _saveNow(
      BudgetCubit cubit,
      bc.MagicTableController c,
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
      final domain = MagicAdapter.buildDomainFromController(controller: c);

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

  @override
  Widget build(BuildContext context) {
    final contractId = _contractId;

    return ChangeNotifierProvider<bc.MagicTableController>(
      create: (_) => bc.MagicTableController(
        cellPadHorizontal: const EdgeInsets.symmetric(horizontal: 12).horizontal,
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
            children: [
              const Positioned.fill(
                child: BackgroundChange(),
              ),
              Positioned.fill(
                child: MagicTableChanged(
                  selectAllOnEdit: false,
                  controller: ctrl,
                  onInit: (c) => _load(cubit, c, contractId),
                  allowAddColumn: false,
                  allowRemoveColumn: false,
                  allowAddRow: false,
                  onRequestSaveAfterStructureChange: (c) {
                    return _saveNow(cubit, c, contractId);
                  },
                  bottomScrollGap: 90,
                  rightScrollGap: 60,
                  floatingActionsBuilder: (ctx, c) {
                    return [
                      FloatingActionButton.small(
                        backgroundColor: Colors.white,
                        heroTag: 'pasteExcel',
                        tooltip: 'Colar do Excel (Ctrl+V)',
                        onPressed: isBusy ? null : () => c.pasteFromClipboard(),
                        child: const Icon(Icons.paste),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.small(
                        backgroundColor: Colors.white,
                        heroTag: 'saveBudget',
                        tooltip: 'Salvar orçamento no Firestore',
                        onPressed: isBusy
                            ? null
                            : () async {
                          if (!c.hasData) {
                            await _showNotification(
                              title: 'Nada para salvar',
                              subtitle:
                              'Cole dados do Excel antes de salvar.',
                              type: NotificationStatus.info,
                              saveInBell: false,
                              sendPush: false,
                            );
                            return;
                          }

                          await _saveNow(cubit, c, contractId);
                        },
                        child: const Icon(Icons.save),
                      ),
                    ];
                  },
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: FootBar(),
              ),
              if (isBusy) ...[
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.black38,
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 10,
                          spreadRadius: 1,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingTreeDots(
                          size: 28,
                          centered: false,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _saving
                              ? 'Salvando orçamento...'
                              : 'Carregando orçamento...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}