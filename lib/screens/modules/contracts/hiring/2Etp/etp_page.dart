import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/modules/contracts/_process/contract_bell_notifier.dart';

import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_1_identificacao_etp.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_2_motivacao_obj_requisitos.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_3_alternativas_solucao.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_4_mercado_estimativa.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_5_cronograma_indicadores.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_6_premissas_restricoes_licenciamento.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_7_documentos_equipe.dart';
import 'package:sipged/screens/modules/contracts/hiring/2Etp/section_8_conclusao.dart';

class EtpPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const EtpPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<EtpPage> createState() => _EtpPageState();
}

class _EtpPageState extends State<EtpPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  EtpData _formData = const EtpData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentEtpId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

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
        context.read<EtpCubit>().load(_contractId);
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
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    await ContractBellNotifier.show(
      context: context,
      contract: _effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'ETP',
      module: 'contracts_hiring_etp',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: extra,
    );
  }

  Future<bool> _saveOnly() async {
    if (widget.readOnly) {
      await _notify(
        title: 'ETP',
        subtitle: 'Esta etapa está em modo somente leitura.',
        type: NotificationType.info,
      );
      return false;
    }

    final cubit = context.read<EtpCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'ETP',
          subtitle: 'Erro ao salvar.',
          details: err,
          type: NotificationType.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(_contractId);

      if (!mounted) return false;

      await _notify(
        title: 'ETP atualizado',
        subtitle: 'Alterações salvas por ${_currentActorName()}.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        extra: <String, dynamic>{
          'action': 'etp_saved',
          'etpId': cubit.state.etpId,
        },
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'ETP',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final etpCubit = context.read<EtpCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final etpId = etpCubit.state.etpId;

    if (etpId == null || etpId.isEmpty) {
      await _notify(
        title: 'ETP',
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
        collectionName: 'etp',
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: 'etp',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.tr, true);
      unawaited(pipeline.refresh());

      tab.animateTo(
        (tab.index + 1).clamp(0, tab.length - 1),
      );

      await _notify(
        title: 'ETP aprovado',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        extra: <String, dynamic>{
          'action': 'etp_approved',
          'etpId': etpId,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'ETP',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final etpCubit = context.read<EtpCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly();

    if (!mounted || !saved) return;

    final etpId = etpCubit.state.etpId;

    if (etpId == null || etpId.isEmpty) {
      await _notify(
        title: 'ETP',
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
        collectionName: 'etp',
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação do ETP atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        type: NotificationType.success,
        saveInBell: true,
        extra: <String, dynamic>{
          'action': 'etp_approval_updated',
          'etpId': etpId,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'ETP',
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
      child: BlocListener<EtpCubit, EtpState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.etpId != curr.etpId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.etpId;
          final needsHydrate = !_hydrated || _currentEtpId != incomingId;

          if (needsHydrate) {
            final data = EtpData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentEtpId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: _contractId,
              collectionName: 'etp',
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
            }
          }
        },
        child: BlocBuilder<EtpCubit, EtpState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked =
                state.loading || state.saving || pstate.loading || _loadingContract;

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
                stageKey: HiringStageKey.etp,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('etp-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionIdentificacaoEtp(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionMotivationObj(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionAlternativeSolution(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionMercadoEstimativa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionCronogramaIndicadores(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionPremissasRestricoesLicenciamento(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionDocumentosEquipe(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionConclusao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Estudo Técnico Preliminar (ETP)',
                        icon: Icons.description_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
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