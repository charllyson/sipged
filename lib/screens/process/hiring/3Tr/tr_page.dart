// lib/screens/process/hiring/3Tr/tr_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/gates/stage_gate.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

import 'package:siged/_blocs/process/hiring/3Tr/tr_bloc.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

// Seções
import 'package:siged/screens/process/hiring/3Tr/section_1_objeto_fundamentacao.dart';
import 'package:siged/screens/process/hiring/3Tr/section_2_escopo_requisitos.dart';
import 'package:siged/screens/process/hiring/3Tr/section_3_local_prazos_cronograma.dart';
import 'package:siged/screens/process/hiring/3Tr/section_4_medicao_aceite_indicadores.dart';
import 'package:siged/screens/process/hiring/3Tr/section_5_obrigacoes_equipe_gestao.dart';
import 'package:siged/screens/process/hiring/3Tr/section_6_licenciamento_seguranca_sustentabilidade.dart';
import 'package:siged/screens/process/hiring/3Tr/section_7_precos_pagamento_reajuste.dart';
import 'package:siged/screens/process/hiring/3Tr/section_8_riscos_penalidades_condicoes.dart';
import 'package:siged/screens/process/hiring/3Tr/section_9_documentos_referencias.dart';

class TermoReferenciaPage extends StatefulWidget {
  final TrController controller;
  final String contractId;

  const TermoReferenciaPage({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  State<TermoReferenciaPage> createState() => _TermoReferenciaPageState();
}

class _TermoReferenciaPageState extends State<TermoReferenciaPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentTrId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    context.read<TrBloc>().add(TrLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<TrBloc>();
    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação do TR'),
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

    bloc.add(TrSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('TR'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('TR'),
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
      // Injeta o controller para todas as seções
      child: ChangeNotifierProvider<TrController>.value(
        value: widget.controller,
        child: BlocListener<TrBloc, TrState>(
          listenWhen: (prev, curr) =>
          (prev.loading && !curr.loading) || (prev.trId != curr.trId),
          listener: (context, state) {
            if (!mounted || state.loading || !state.hasValidPath) return;

            final incomingId = state.trId;
            final needsHydrate = !_hydrated || _currentTrId != incomingId;
            if (needsHydrate) {
              widget.controller.fromSectionMaps(state.sectionsData);
              _hydrated = true;
              _currentTrId = incomingId;

              if (incomingId != null && incomingId.isNotEmpty) {
                _progressBloc.add(ProgressBindRequested(
                  contractId: widget.contractId,
                  collectionName: 'tr',
                  stageId: incomingId,
                ));
              }
            }
          },
          child: BlocBuilder<TrBloc, TrState>(
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
                  stageKey: HiringStageKey.tr,
                  child: Scaffold(
                    body: Stack(
                      children: [
                        const BackgroundClean(),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionObjetoFundamentacao(),
                              SectionEscopoRequisitos(),
                              SectionLocalPrazosCronograma(),
                              SectionMedicaoAceiteIndicadores(),
                              SectionObrigacoesEquipeGestao(),
                              SectionLicenciamentoSegurancaSustentabilidade(),
                              SectionPrecosPagamentoReajuste(),
                              SectionRiscosPenalidadesCondicoes(),
                              SectionDocumentosReferencias(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    bottomNavigationBar:
                    BlocBuilder<ProgressBloc, ProgressState>(
                      builder: (context, pstate) {
                        return StageProgress(
                          title: 'Termo de Referência',
                          icon: Icons.rule_folder_outlined,
                          busy: state.saving,
                          approved: pstate.approved,
                          onSave: _saveOnly,
                          onSaveAndNext: () async {
                            await _saveOnly();

                            final trId = context.read<TrBloc>().state.trId;
                            if (trId == null || trId.isEmpty) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('TR'),
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
                                collectionName: 'tr',
                                stageId: trId,
                                approverUid: uid,
                                approverName: nameOrEmail,
                              );
                              await repo.setCompleted(
                                contractId: widget.contractId,
                                collectionName: 'tr',
                                stageId: trId,
                                completed: true,
                              );

                              // 🔹 Liberação otimista: Cotação
                              final pipeline =
                              context.read<PipelineProgressCubit>();
                              pipeline.setStageEnabled(
                                  HiringStageKey.cotacao, true);
                              unawaited(pipeline.refresh());

                              DefaultTabController.of(context)
                                  ?.animateTo(
                                  (DefaultTabController.of(context)!.index +
                                      1)
                                      .clamp(
                                      0,
                                      DefaultTabController.of(context)!
                                          .length -
                                          1));

                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('TR'),
                                  subtitle: const Text(
                                      'Aprovado e etapa concluída.'),
                                  type: AppNotificationType.success,
                                ),
                              );
                            } catch (e) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('TR'),
                                  subtitle: const Text('Erro ao aprovar.'),
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
      ),
    );
  }
}
