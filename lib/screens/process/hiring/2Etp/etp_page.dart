// lib/screens/process/hiring/2Etp/etp_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/gates/stage_gate.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

import 'package:siged/_blocs/process/hiring/2Etp/etp_bloc.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

import 'package:siged/screens/process/hiring/2Etp/section_1_identificacao_etp.dart';
import 'package:siged/screens/process/hiring/2Etp/section_2_motivacao_obj_requisitos.dart';
import 'package:siged/screens/process/hiring/2Etp/section_3_alternativas_solucao.dart';
import 'package:siged/screens/process/hiring/2Etp/section_4_mercado_estimativa.dart';
import 'package:siged/screens/process/hiring/2Etp/section_5_cronograma_indicadores.dart';
import 'package:siged/screens/process/hiring/2Etp/section_6_premissas_restricoes_licenciamento.dart';
import 'package:siged/screens/process/hiring/2Etp/section_7_documentos_equipe.dart';
import 'package:siged/screens/process/hiring/2Etp/section_8_conclusao.dart';

class EtpPage extends StatefulWidget {
  final EtpController controller;
  final String contractId;

  const EtpPage({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  State<EtpPage> createState() => _EtpPageState();
}

class _EtpPageState extends State<EtpPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentEtpId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    context.read<EtpBloc>().add(EtpLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<EtpBloc>();
    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação do ETP'),
          subtitle: Text(quick),
          type: AppNotificationType.warning,
        ),
      );
      return;
    }

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(EtpSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
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
    final c = widget.controller;

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<EtpBloc, EtpState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.etpId != curr.etpId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.etpId;
          final needsHydrate = !_hydrated || _currentEtpId != incomingId;
          if (needsHydrate) {
            c.fromSectionMaps(state.sectionsData); // pode vir vazio -> limpa
            _hydrated = true;
            _currentEtpId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'etp',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<EtpBloc, EtpState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressBloc>().state;

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
              child: StageGate( // opcional: controla edição conforme gate
                stageKey: HiringStageKey.etp,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionIdentificacaoEtp(controller: c),
                            SectionMotivacaoObjRequisitos(controller: c),
                            SectionAlternativasSolucao(controller: c),
                            SectionMercadoEstimativa(controller: c),
                            SectionCronogramaIndicadores(controller: c),
                            SectionPremissasRestricoesLicenciamento(controller: c),
                            SectionDocumentosEquipe(controller: c),
                            SectionConclusao(controller: c),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar:
                  BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Estudo Técnico Preliminar (ETP)',
                        icon: Icons.description_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final etpId = context.read<EtpBloc>().state.etpId;
                          if (etpId == null || etpId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text(
                                    'Documento não encontrado para aprovar.'),
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

                          final repo = _progressBloc.repo;
                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              stageId: etpId,
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              stageId: etpId,
                              completed: true,
                            );

                            // 🔹 Liberação otimista: TR
                            final pipeline =
                            context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(HiringStageKey.tr, true);
                            unawaited(pipeline.refresh());

                            final tab = DefaultTabController.of(context);
                            tab?.animateTo(
                              (tab.index + 1).clamp(0, tab.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle:
                                const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
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
                          await _saveOnly();

                          final etpId =
                              context.read<EtpBloc>().state.etpId;
                          if (etpId == null || etpId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text(
                                    'Documento não encontrado para atualizar.'),
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

                          final repo = _progressBloc.repo;
                          try {
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'etp',
                              stageId: etpId,
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle:
                                const Text('Aprovação atualizada.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('ETP'),
                                subtitle: const Text(
                                    'Erro ao atualizar aprovação.'),
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
