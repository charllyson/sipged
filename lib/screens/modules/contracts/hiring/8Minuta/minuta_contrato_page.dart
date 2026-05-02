// lib/screens/modules/contracts/hiring/8Minuta/minuta_contrato_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_state.dart';

import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_1_identificacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_2_partes_objeto.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_3_valor.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_4_gestao_refs.dart';

class MinutaContratoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const MinutaContratoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<MinutaContratoPage> createState() => _MinutaContratoPageState();
}

class _MinutaContratoPageState extends State<MinutaContratoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const String _route = 'contracts_hiring_minuta';
  static const String _notificationSource = 'contracts_hiring_minuta';

  late final ProgressCubit _progressBloc;

  MinutaContratoData _formData = const MinutaContratoData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentMinutaId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ProcessData get _effectiveContract {
    final currentId = (_contract.id ?? '').trim();

    if (currentId.isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);

    return _contract;
  }

  @override
  void initState() {
    super.initState();

    _progressBloc = ProgressCubit(repo: ProgressRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contractId = _contractId;
      if (contractId.isEmpty) return;

      context.read<MinutaContratoCubit>().load(contractId);
      unawaited(_loadContract(contractId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _loadContract(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    if (mounted) {
      setState(() => _loadingContract = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(cid)
          .get();

      if (!mounted) return;

      setState(() {
        _contract = snapshot.exists
            ? ProcessData.fromDocument(snapshot: snapshot)
            : ProcessData.empty().copyWith(id: cid);

        _loadingContract = false;
      });
    } catch (e) {
      debugPrint('[MinutaContratoPage] Erro ao carregar contrato $cid: $e');

      if (!mounted) return;

      setState(() {
        _contract = ProcessData.empty().copyWith(id: cid);
        _loadingContract = false;
      });
    }
  }

  String _currentActorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,

    /// Vazio = helper resolve todos os usuários com permissão ao contrato.
    Iterable<String> targetUserIds = const <String>[],

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final effectiveContract = _effectiveContract;

    await NotificationHiring.show(
      context: context,
      contract: effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'Minuta',
      module: _route,
      notificationSource: _notificationSource,
      source: 'minuta_notification',
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: NotificationDelivery.localBellAndPush,
      targetUserIds: targetUserIds,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'minuta_notification',
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,
        if ((effectiveContract.id ?? '').trim().isNotEmpty)
          'contractId': effectiveContract.id,
        if (effectiveContract.displaySummary.trim().isNotEmpty)
          'contractSummary': effectiveContract.displaySummary,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final contractId = _contractId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Contrato não identificado para salvar.',
        status: NotificationStatus.error,
      );
      return false;
    }

    final cubit = context.read<MinutaContratoCubit>();

    try {
      await cubit.saveAll(
        contractId: contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        await _notify(
          title: 'Minuta',
          subtitle: 'Erro ao salvar.',
          details: cubit.state.error ?? 'Falha ao salvar',
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: contractId,
        collectionName: 'minuta',
      );

      if (notifySuccess) {
        final actorName = _currentActorName();

        await _notify(
          title: 'Minuta atualizada',
          subtitle: 'Alterações salvas por $actorName.',
          details: _effectiveContract.displaySummary,
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'minuta_saved',
            'minutaId': cubit.state.minutaId,
            'contractId': contractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Minuta',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final minutaCubit = context.read<MinutaContratoCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final minutaId = minutaCubit.state.minutaId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Contrato não identificado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (minutaId == null || minutaId.isEmpty) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: contractId,
        collectionName: 'minuta',
        approverUid: user?.uid ?? '',
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: contractId,
        collectionName: 'minuta',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.parecer, true);
      unawaited(pipeline.refresh());

      tab.animateTo(
        (tab.index + 1).clamp(0, tab.length - 1),
      );

      await _notify(
        title: 'Minuta aprovada',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'minuta_approved',
          'minutaId': minutaId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': 'parecer',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Minuta',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final minutaCubit = context.read<MinutaContratoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final minutaId = minutaCubit.state.minutaId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Contrato não identificado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (minutaId == null || minutaId.isEmpty) {
      await _notify(
        title: 'Minuta',
        subtitle: 'Documento não encontrado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: contractId,
        collectionName: 'minuta',
        updatedByUid: user?.uid ?? '',
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação da Minuta atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'minuta_approval_updated',
          'minutaId': minutaId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Minuta',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<MinutaContratoCubit, MinutaState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) ||
              prev.minutaId != curr.minutaId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.minutaId;
          final needsHydrate = !_hydrated || _currentMinutaId != incomingId;

          if (needsHydrate) {
            final data = MinutaContratoData.fromSectionsMap(
              state.sectionsData,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentMinutaId = incomingId;
            });
          }

          final contractId = _contractId;

          if ((incomingId ?? '').isNotEmpty && contractId.isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: contractId,
              collectionName: 'minuta',
            );

            if ((_contract.id ?? '') != contractId) {
              unawaited(_loadContract(contractId));
            }
          }
        },
        child: BlocBuilder<MinutaContratoCubit, MinutaState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked = state.loading ||
                state.saving ||
                pstate.loading ||
                _loadingContract;

            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : pstate.loading
                ? 'Atualizando aprovação...'
                : _loadingContract
                ? 'Carregando dados do contrato...'
                : null;

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Por favor, aguarde.' : null,
              keepAppBarUndimmed: true,
              child: StageGate(
                stageKey: HiringStageKey.minuta,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('minuta-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionIdentificacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionPartesObjeto(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionValor(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionGestaoRefs(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, progressState) {
                      return StageProgress(
                        title: 'Minuta do Contrato',
                        icon: Icons.description_outlined,
                        busy: state.saving || progressState.loading,
                        approved: progressState.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: _saveApproveAndNext,
                        onUpdateApproved: _updateApproved,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}