import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_contract.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_state.dart';

import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_2_partes_valores.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_3_veiculo.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_4_status_prazos.dart';
import 'package:sipged/screens/modules/contracts/hiring/10Publicacao/section_5_responsavel.dart';

class PublicacaoExtratoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const PublicacaoExtratoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<PublicacaoExtratoPage> createState() => _PublicacaoExtratoPageState();
}

class _PublicacaoExtratoPageState extends State<PublicacaoExtratoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  PublicacaoExtratoData _formData = const PublicacaoExtratoData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentPubId;

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
    final currentId = (_contract.id ?? '').trim();

    if (currentId.isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) {
      return _contract.copyWith(id: _contractId);
    }

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

      context.read<PublicacaoExtratoCubit>().load(contractId);
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
      leadingLabel: 'Publicação',
      module: 'contracts_hiring_publicacao',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      targetUserIds: targetUserIds,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? 'contracts_hiring_publicacao',
        'contractId': _effectiveContract.id,
        'contractSummary': _effectiveContract.displaySummary,
      },
    );
  }

  Future<bool> _saveOnly() async {
    if (widget.readOnly) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Esta etapa está em modo somente leitura.',
        type: NotificationType.info,
      );
      return false;
    }

    final contractId = _contractId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para salvar.',
        type: NotificationType.error,
      );
      return false;
    }

    final cubit = context.read<PublicacaoExtratoCubit>();

    try {
      await cubit.saveAll(
        contractId: contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        await _notify(
          title: 'Publicação / Extrato',
          subtitle: 'Erro ao salvar.',
          details: cubit.state.error ?? 'Falha ao salvar',
          type: NotificationType.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: contractId,
        collectionName: 'publicacao',
      );

      final actorName = _currentActorName();

      await _notify(
        title: 'Publicação / Extrato atualizada',
        subtitle: 'Alterações salvas por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'publicacao_saved',
          'pubId': cubit.state.pubId,
          'contractId': contractId,
          'route': 'contracts_hiring_publicacao',
        },
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final pubCubit = context.read<PublicacaoExtratoCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tabController = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final pubId = pubCubit.state.pubId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para aprovar.',
        type: NotificationType.error,
      );
      return;
    }

    if (pubId == null || pubId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Documento não encontrado para aprovar.',
        type: NotificationType.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: contractId,
        collectionName: 'publicacao',
        approverUid: user?.uid ?? '',
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: contractId,
        collectionName: 'publicacao',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.arquivamento, true);
      unawaited(pipeline.refresh());

      tabController.animateTo(
        (tabController.index + 1).clamp(0, tabController.length - 1),
      );

      await _notify(
        title: 'Publicação / Extrato aprovada',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'publicacao_approved',
          'pubId': pubId,
          'contractId': contractId,
          'route': 'contracts_hiring_publicacao',
          'nextStage': 'arquivamento',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Erro ao aprovar a etapa.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final pubCubit = context.read<PublicacaoExtratoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final pubId = pubCubit.state.pubId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Contrato não identificado para atualizar.',
        type: NotificationType.error,
      );
      return;
    }

    if (pubId == null || pubId.isEmpty) {
      await _notify(
        title: 'Publicação / Extrato',
        subtitle: 'Documento não encontrado para atualizar aprovação.',
        type: NotificationType.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: contractId,
        collectionName: 'publicacao',
        updatedByUid: user?.uid ?? '',
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação da Publicação / Extrato atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'publicacao_approval_updated',
          'pubId': pubId,
          'contractId': contractId,
          'route': 'contracts_hiring_publicacao',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Publicação / Extrato',
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
      child: BlocListener<PublicacaoExtratoCubit, PublicacaoExtratoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.pubId != curr.pubId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.pubId;
          final needsHydrate = !_hydrated || _currentPubId != incomingId;

          if (needsHydrate) {
            final data = PublicacaoExtratoData.fromSectionsMap(
              state.sectionsData,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentPubId = incomingId;
            });
          }

          final contractId = _contractId;

          if ((incomingId ?? '').isNotEmpty && contractId.isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: contractId,
              collectionName: 'publicacao',
            );

            if ((_contract.id ?? '') != contractId) {
              unawaited(_loadContract(contractId));
            }
          }
        },
        child: BlocBuilder<PublicacaoExtratoCubit, PublicacaoExtratoState>(
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
                stageKey: HiringStageKey.publicacao,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('publicacao-extrato-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadadosExtrato(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionPartesValoresVigencia(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionVeiculoPublicacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionStatusPrazos(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionResponsavel(
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
                        title: 'Publicação / Extrato',
                        icon: Icons.campaign_outlined,
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