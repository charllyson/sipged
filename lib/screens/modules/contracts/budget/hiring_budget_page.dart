import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/table/magic/magic_adapter.dart';
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';
import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;

class HiringBudgetPage extends StatefulWidget {
  const HiringBudgetPage({
    super.key,
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<HiringBudgetPage> createState() => _HiringBudgetPageState();
}

class _HiringBudgetPageState extends State<HiringBudgetPage> {
  bool _saving = false;

  String get _contractId => widget.contractData.id?.trim() ?? '';


  String get _contractSummary {
    final data = widget.contractData;

    final summary = (data.summarySubjectContract ?? '').trim();
    if (summary.isNotEmpty) return summary;

    final number = (data.contractNumber ?? '').trim();
    if (number.isNotEmpty) return 'Contrato $number';

    final process = (data.processNumber ?? '').trim();
    if (process.isNotEmpty) return 'Processo $process';

    if (_contractId.isNotEmpty) return 'Contrato $_contractId';

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final data = widget.contractData;

    final number = (data.contractNumber ?? '').trim();
    if (number.isNotEmpty) return number;

    final process = (data.processNumber ?? '').trim();
    if (process.isNotEmpty) return process;

    return _contractId;
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
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? '').toString().trim();
        final surname = (meta['surname'] ?? '').toString().trim();

        final composed = [name, surname]
            .where((e) => e.trim().isNotEmpty)
            .join(' ')
            .trim();

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

  List<String> _contractNotificationRecipients({
    required String? currentUserId,
  }) {
    final current = currentUserId?.trim();
    final ids = <String>{};

    for (final entry in widget.contractData.permissionContractId.entries) {
      final userId = entry.key.trim();
      if (userId.isEmpty) continue;

      final perms = entry.value;

      final canRead = perms['read'] == true ||
          perms['view'] == true ||
          perms['create'] == true ||
          perms['edit'] == true ||
          perms['update'] == true ||
          perms['delete'] == true ||
          perms['admin'] == true ||
          perms['owner'] == true;

      if (!canRead) continue;
      if (current != null && current.isNotEmpty && userId == current) {
        continue;
      }

      ids.add(userId);
    }

    for (final userId in widget.contractData.participantsInfo.keys) {
      final clean = userId.trim();
      if (clean.isEmpty) continue;

      if (current != null && current.isNotEmpty && clean == current) {
        continue;
      }

      ids.add(clean);
    }

    return ids.toList();
  }

  Future<void> _showNotification({
    required String title,
    String? subtitle,
    String? details,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Iterable<String> targetUserIds = const <String>[],
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);

    final resolvedTargets = <String>{
      ...targetUserIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };

    if (resolvedTargets.isEmpty && (saveInBell || sendPush)) {
      resolvedTargets.addAll(
        _contractNotificationRecipients(
          currentUserId: currentUserId,
        ),
      );
    }

    final notification = NotificationData(
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Orçamento',
      type: type,
      duration: duration,
      persistInFirebase: saveInBell,
      createdBy: currentUserId,
      extra: <String, dynamic>{
        'module': 'contracts_budget',
        'route': 'contracts_budget',
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'contractSummary': _contractSummary,
        'contractTitle': _contractSummary,
        'actorId': currentUserId,
        'actorName': actorName,
        'sendPush': sendPush,
        'targetUserIds': resolvedTargets.toList(),
        ...extra,
      },
    );

    final notificationCubit = context.read<NotificationCubit>();

    if (resolvedTargets.isEmpty) {
      await notificationCubit.show(notification);
      return;
    }

    await notificationCubit.showToUsers(
      notification,
      userIds: resolvedTargets.toList(),
      alsoShowLocalToast: true,
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
        type: NotificationType.warning,
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
        type: NotificationType.error,
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
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'budget_updated',
          'contractId': cleanContractId,
          'route': 'contracts_budget',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _showNotification(
        title: 'Falha ao salvar orçamento',
        subtitle: '$e',
        details: _contractSummary,
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
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
                              type: NotificationType.info,
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