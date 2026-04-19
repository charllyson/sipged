import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

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
  bool _hydrated = false;
  String? _currentEtpId;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());
    context.read<EtpCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<EtpCubit>();

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = cubit.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    await cubit.saveAll(
      contractId: widget.contractId,
      sectionsData: _formData.toSectionsMap(),
    );

    await completer.future;

    if (!mounted) return;

    if (!cubit.state.saveSuccess) {
      final err = cubit.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('ETP'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('ETP'),
        subtitle: const Text('Alterações salvas com sucesso.'),
        type: AppNotificationType.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<EtpCubit, EtpState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.etpId != curr.etpId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.etpId;
          final needsHydrate = !_hydrated || _currentEtpId != incomingId;

          if (needsHydrate) {
            final data = EtpData.fromSectionsMap(state.sectionsData);
            setState(() => _formData = data);

            _hydrated = true;
            _currentEtpId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'etp',
              );
            }
          }
        },
        child: BlocBuilder<EtpCubit, EtpState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked = state.loading || state.saving || pstate.loading;
            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : pstate.loading
                ? 'Atualizando aprovação...'
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
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionMotivationObj(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionAlternativeSolution(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionMercadoEstimativa(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionCronogramaIndicadores(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionPremissasRestricoesLicenciamento(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionDocumentosEquipe(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionConclusao(
                              data: _formData,
                              isEditable: !widget.readOnly,
                              onChanged: (updated) => setState(() => _formData = updated),
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
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          final etpCubit = context.read<EtpCubit>();
                          final pipeline = context.read<PipelineProgressCubit>();
                          final tab = DefaultTabController.of(context);
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final etpId = etpCubit.state.etpId;
                          if (etpId == null || etpId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Documento não encontrado para aprovar.'),
                                type: AppNotificationType.error,
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user?.uid ?? '';
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              completed: true,
                            );

                            if (!mounted) return;

                            pipeline.setStageEnabled(HiringStageKey.tr, true);
                            unawaited(pipeline.refresh());

                            tab.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          final etpCubit = context.read<EtpCubit>();
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final etpId = etpCubit.state.etpId;
                          if (etpId == null || etpId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Documento não encontrado para atualizar.'),
                                type: AppNotificationType.error,
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user?.uid ?? '';
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          try {
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );
                            if (!mounted) return;
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Aprovação atualizada.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text('Erro ao atualizar aprovação.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
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