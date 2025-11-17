// lib/screens/process/hiring/6Habilitacao/habilitacao_page.dart
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

import 'package:siged/_blocs/process/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_state.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';

// BLoC Habilitação
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// Sections (widgets)
import 'package:siged/screens/process/hiring/6Habilitacao/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/section_2_empresa.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/section_3_certidoes.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/section_4_juridica_tecnica.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/section_5_licitacao.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/section_6_consolidacao.dart';

class HabilitacaoPage extends StatefulWidget {
  final HabilitacaoController controller;
  final String contractId;
  final bool readOnly;
  const HabilitacaoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<HabilitacaoPage> createState() => _HabilitacaoPageState();
}

class _HabilitacaoPageState extends State<HabilitacaoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentHabId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    context.read<HabilitacaoBloc>().add(HabilitacaoLoadRequested(widget.contractId));
    widget.controller.setEditable(!widget.readOnly);
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<HabilitacaoBloc>();

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(HabilitacaoSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Habilitação/Regularidade'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Habilitação/Regularidade'),
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
      child: BlocListener<HabilitacaoBloc, HabilitacaoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.habId != curr.habId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.habId;
          final needsHydrate = !_hydrated || _currentHabId != incomingId;
          if (needsHydrate) {
            c.fromSectionMaps(state.sectionsData); // pode vir vazio -> limpa
            _hydrated = true;
            _currentHabId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'habilitacao',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<HabilitacaoBloc, HabilitacaoState>(
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
                stageKey: HiringStageKey.habilitacao,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundClean(),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadados(controller: c),
                            SectionEmpresa(controller: c),
                            SectionCertidoes(controller: c),
                            SectionJuridicaTecnica(controller: c),
                            SectionLicitacao(controller: c, contractId: widget.contractId),
                            SectionConsolidacao(controller: c),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Habilitação / Regularidade',
                        icon: Icons.verified_user_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          await _saveOnly();

                          final habId = context.read<HabilitacaoBloc>().state.habId;
                          if (habId == null || habId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Documento não encontrado para aprovar.'),
                                type: AppNotificationType.error,
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user?.uid ?? '';
                          final nameOrEmail = (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          final repo = _progressBloc.repo;
                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              stageId: habId,
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );
                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              stageId: habId,
                              completed: true,
                            );

                            // 🔹 Liberação otimista: Dotação
                            final pipeline = context.read<PipelineProgressCubit>();
                            pipeline.setStageEnabled(HiringStageKey.dotacao, true);
                            unawaited(pipeline.refresh());

                            final tab = DefaultTabController.of(context);
                            tab?.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          await _saveOnly();

                          final habId = context.read<HabilitacaoBloc>().state.habId;
                          if (habId == null || habId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Documento não encontrado para atualizar.'),
                                type: AppNotificationType.error,
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user?.uid ?? '';
                          final nameOrEmail = (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          final repo = _progressBloc.repo;
                          try {
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              stageId: habId,
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Aprovação atualizada.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
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
