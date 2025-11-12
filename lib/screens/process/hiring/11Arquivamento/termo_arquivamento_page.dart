import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';

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

import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_bloc.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

// Seções
import 'package:siged/screens/process/hiring/11Arquivamento/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_2_motivo_abrangencia.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_3_fundamentacao.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_4_pecas_anexas.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_5_decisao_autoridade.dart';
import 'package:siged/screens/process/hiring/11Arquivamento/section_6_reabertura.dart';

class TermoArquivamentoPage extends StatefulWidget {
  final TermoArquivamentoController controller;
  final String contractId;

  const TermoArquivamentoPage({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  State<TermoArquivamentoPage> createState() => _TermoArquivamentoPageState();
}

class _TermoArquivamentoPageState extends State<TermoArquivamentoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentTaId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    context.read<TermoArquivamentoBloc>().add(TermoArquivamentoLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<TermoArquivamentoBloc>();

    // se tiver quickValidate no controller, pode habilitar:
    // final quick = widget.controller.quickValidate();
    // if (quick != null) { ... warning ...; return; }

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(TermoArquivamentoSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Termo de Arquivamento'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Termo de Arquivamento'),
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
      child: BlocListener<TermoArquivamentoBloc, TermoArquivamentoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.taId != curr.taId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.taId;
          final needsHydrate = !_hydrated || _currentTaId != incomingId;
          if (needsHydrate) {
            c.fromSectionMaps(state.sectionsData);
            _hydrated = true;
            _currentTaId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'arquivamento',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<TermoArquivamentoBloc, TermoArquivamentoState>(
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
              child: StageGate(
                stageKey: HiringStageKey.arquivamento, // ajuste se seu enum usar outro nome
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadadosTA(controller: c, users: context.read<UserBloc>().state.all),
                            SectionMotivoAbrangenciaTA(controller: c),
                            SectionFundamentacaoTA(controller: c),
                            SectionPecasAnexasTA(controller: c),
                            SectionDecisaoAutoridadeTA(controller: c, users: context.read<UserBloc>().state.all),
                            SectionReaberturaTA(controller: c),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Termo de Arquivamento',
                        icon: Icons.archive_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final taId = context.read<TermoArquivamentoBloc>().state.taId;
                          if (taId == null || taId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
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

                          final repo = _progressBloc.repo;
                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'arquivamento',
                              stageId: taId,
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'arquivamento',
                              stageId: taId,
                              completed: true,
                            );

                            // Última etapa (ajuste conforme seu pipeline)
                            final pipeline = context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(HiringStageKey.arquivamento, true);
                            unawaited(pipeline.refresh());

                            final tab = DefaultTabController.of(context);
                            tab?.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          await _saveOnly();

                          final taId = context.read<TermoArquivamentoBloc>().state.taId;
                          if (taId == null || taId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
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

                          final repo = _progressBloc.repo;
                          try {
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'arquivamento',
                              stageId: taId,
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
                                subtitle: const Text('Aprovação atualizada.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Termo de Arquivamento'),
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
