import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

import 'package:sipged/_blocs/system/notification/local/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_state.dart';

import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_1_identificacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_2_vinculacao_programatica.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_3_natureza_despesa.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_4_reserva.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_5_empenho.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_6_cronograma.dart';
import 'package:sipged/screens/modules/contracts/hiring/7Dotacao/section_7_documentos_links.dart';

class DotacaoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const DotacaoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<DotacaoPage> createState() => _DotacaoPageState();
}

class _DotacaoPageState extends State<DotacaoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  DotacaoData _formData = const DotacaoData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentDotId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  List<String> get _defaultPushTargets {
    final uid = _currentUserId;
    if (uid.isEmpty) return const <String>[];
    return <String>[uid];
  }

  ProcessData get _effectiveContract {
    if ((_contract.id ?? '').trim().isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);
    return _contract;
  }

  @override
  void initState() {
    super.initState();

    _progressBloc = ProgressCubit(repo: ProgressRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_contractId.isNotEmpty) {
        context.read<DotacaoCubit>().load(_contractId);
        unawaited(_loadContract(_contractId));
      }
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
    } catch (_) {
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
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Iterable<String> targetUserIds = const <String>[],
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    await NotificationContract.show(
      context: context,
      contract: _effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'Dotação',
      module: 'contracts_hiring_dotacao',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      targetUserIds: targetUserIds,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? 'contracts_hiring_dotacao',
        'contractId': _effectiveContract.id,
        'contractSummary': _effectiveContract.displaySummary,
      },
    );
  }

  Future<bool> _saveOnly() async {
    if (widget.readOnly) {
      await _notify(
        title: 'Dotação',
        subtitle: 'Esta etapa está em modo somente leitura.',
        type: NotificationType.info,
      );
      return false;
    }

    final cubit = context.read<DotacaoCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'Dotação',
          subtitle: 'Erro ao salvar.',
          details: err,
          type: NotificationType.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(_contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: _contractId,
        collectionName: 'dotacao',
      );

      await _notify(
        title: 'Dotação atualizada',
        subtitle: 'Alterações salvas por ${_currentActorName()}.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'dotacao_saved',
          'dotacaoId': cubit.state.dotacaoId,
          'contractId': _contractId,
          'route': 'contracts_hiring_dotacao',
        },
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Dotação',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final dotacaoCubit = context.read<DotacaoCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final dotacaoId = dotacaoCubit.state.dotacaoId;

    if (dotacaoId == null || dotacaoId.isEmpty) {
      await _notify(
        title: 'Dotação',
        subtitle: 'Documento não encontrado para aprovar.',
        type: NotificationType.error,
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: _contractId,
        collectionName: 'dotacao',
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: 'dotacao',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.minuta, true);
      unawaited(pipeline.refresh());

      tab.animateTo(
        (tab.index + 1).clamp(0, tab.length - 1),
      );

      await _notify(
        title: 'Dotação aprovada',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'dotacao_approved',
          'dotacaoId': dotacaoId,
          'contractId': _contractId,
          'route': 'contracts_hiring_dotacao',
          'nextStage': 'minuta',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Dotação',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final dotacaoCubit = context.read<DotacaoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final dotacaoId = dotacaoCubit.state.dotacaoId;

    if (dotacaoId == null || dotacaoId.isEmpty) {
      await _notify(
        title: 'Dotação',
        subtitle: 'Documento não encontrado para atualizar.',
        type: NotificationType.error,
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: _contractId,
        collectionName: 'dotacao',
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação da Dotação atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'dotacao_approval_updated',
          'dotacaoId': dotacaoId,
          'contractId': _contractId,
          'route': 'contracts_hiring_dotacao',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Dotação',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<DotacaoCubit, DotacaoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) ||
              prev.dotacaoId != curr.dotacaoId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.dotacaoId;
          final needsHydrate = !_hydrated || _currentDotId != incomingId;

          if (needsHydrate) {
            final data = DotacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentDotId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: _contractId,
              collectionName: 'dotacao',
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
            }
          }
        },
        child: BlocBuilder<DotacaoCubit, DotacaoState>(
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
                stageKey: HiringStageKey.dotacao,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('dotacao-scroll'),
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
                            SectionVinculacaoProgramatica(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionNaturezaDespesa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionReserva(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionEmpenho(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionCronograma(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionDocumentosLinks(
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
                        title: 'Dotação Orçamentária',
                        icon: Icons.account_balance_wallet_outlined,
                        busy: state.saving,
                        approved: progressState.approved,
                        onSave: () async {
                          await _saveOnly();
                        },
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