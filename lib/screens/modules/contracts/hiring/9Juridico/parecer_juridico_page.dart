import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_2_documentos.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_3_checklist.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_4_conclusao.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_5_pendencias.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_6_assinaturas.dart';

class ParecerJuridicoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const ParecerJuridicoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<ParecerJuridicoPage> createState() => _ParecerJuridicoPageState();
}

class _ParecerJuridicoPageState extends State<ParecerJuridicoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  ParecerJuridicoData _formData = const ParecerJuridicoData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentParecerId;

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
      if (_contractId.isEmpty) return;

      context.read<ParecerJuridicoCubit>().load(_contractId);
      unawaited(_loadContract(_contractId));
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
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Iterable<String> targetUserIds = const <String>[],
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    await NotificationHiring.show(
      context: context,
      contract: _effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'Jurídico',
      module: 'contracts_hiring_parecer',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      targetUserIds: targetUserIds,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? 'contracts_hiring_parecer',
        'contractId': _effectiveContract.id,
        'contractSummary': _effectiveContract.displaySummary,
      },
    );
  }

  Future<bool> _saveOnly() async {
    if (widget.readOnly) {
      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Esta etapa está em modo somente leitura.',
        type: NotificationStatus.info,
      );
      return false;
    }

    if (_contractId.isEmpty) {
      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Contrato não identificado para salvar.',
        type: NotificationStatus.error,
      );
      return false;
    }

    final cubit = context.read<ParecerJuridicoCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        await _notify(
          title: 'Parecer Jurídico',
          subtitle: 'Erro ao salvar.',
          details: cubit.state.error ?? 'Falha ao salvar',
          type: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );
        return false;
      }

      await _loadContract(_contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: _contractId,
        collectionName: 'parecer',
      );

      await _notify(
        title: 'Parecer Jurídico atualizado',
        subtitle: 'Alterações salvas por ${_currentActorName()}.',
        details: _effectiveContract.displaySummary,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'parecer_saved',
          'parecerId': cubit.state.parecerId,
          'contractId': _contractId,
          'route': 'contracts_hiring_parecer',
        },
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final parecerCubit = context.read<ParecerJuridicoCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final parecerId = parecerCubit.state.parecerId;

    if (parecerId == null || parecerId.isEmpty) {
      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Documento não encontrado para aprovar.',
        type: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: _contractId,
        collectionName: 'parecer',
        approverUid: user?.uid ?? '',
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: 'parecer',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.publicacao, true);
      unawaited(pipeline.refresh());

      tab.animateTo((tab.index + 1).clamp(0, tab.length - 1));

      await _notify(
        title: 'Parecer Jurídico aprovado',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'parecer_approved',
          'parecerId': parecerId,
          'contractId': _contractId,
          'route': 'contracts_hiring_parecer',
          'nextStage': 'publicacao',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final parecerCubit = context.read<ParecerJuridicoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final parecerId = parecerCubit.state.parecerId;

    if (parecerId == null || parecerId.isEmpty) {
      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Documento não encontrado para atualizar.',
        type: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: _contractId,
        collectionName: 'parecer',
        updatedByUid: user?.uid ?? '',
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação do Parecer Jurídico atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: _defaultPushTargets,
        extra: <String, dynamic>{
          'action': 'parecer_approval_updated',
          'parecerId': parecerId,
          'contractId': _contractId,
          'route': 'contracts_hiring_parecer',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Parecer Jurídico',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$e',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final users = context.select<UserCubit, List<UserData>>(
          (cubit) => cubit.state.all,
    );

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<ParecerJuridicoCubit, ParecerState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) ||
              prev.parecerId != curr.parecerId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.parecerId;
          final needsHydrate = !_hydrated || _currentParecerId != incomingId;

          if (needsHydrate) {
            final data = ParecerJuridicoData.fromSectionsMap(
              state.sectionsData,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentParecerId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty && _contractId.isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: _contractId,
              collectionName: 'parecer',
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
            }
          }
        },
        child: BlocBuilder<ParecerJuridicoCubit, ParecerState>(
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
                stageKey: HiringStageKey.parecer,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('parecer-juridico-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadados(
                              data: _formData,
                              isEditable: _isEditable,
                              users: users,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionDocumentos(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionChecklist(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionConclusao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionPendencias(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionAssinaturas(
                              data: _formData,
                              isEditable: _isEditable,
                              users: users,
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
                        title: 'Parecer Jurídico',
                        icon: Icons.gavel_outlined,
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