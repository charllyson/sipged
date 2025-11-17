// lib/screens/process/hiring/7Dotacao/dotacao_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Users / Utils
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// Layout / Inputs / Widgets
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Pipeline / Progress
import 'package:siged/_blocs/process/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// Dotação
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

// Seções
import 'package:siged/screens/process/hiring/7Dotacao/section_1_identificacao.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_2_vinculacao_programatica.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_3_natureza_despesa.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_4_reserva.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_5_empenho.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_6_cronograma.dart';
import 'package:siged/screens/process/hiring/7Dotacao/section_7_documentos_links.dart';

class DotacaoPage extends StatefulWidget {
  final DotacaoController controller;
  final String contractId;
  final bool readOnly;

  const DotacaoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<DotacaoPage> createState() => _DotacaoPageState();
}

class _DotacaoPageState extends State<DotacaoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentDotId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    widget.controller.setEditable(!widget.readOnly);

    context.read<DotacaoBloc>().add(DotacaoLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<DotacaoBloc>();

    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação da Dotação'),
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

    bloc.add(DotacaoSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Dotação'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Dotação'),
        subtitle: const Text('Alterações salvas com sucesso.'),
        type: AppNotificationType.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<DotacaoBloc, DotacaoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.dotacaoId != curr.dotacaoId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.dotacaoId;
          final needsHydrate = !_hydrated || _currentDotId != incomingId;
          if (needsHydrate) {
            widget.controller.fromSectionMaps(state.sectionsData);
            _hydrated = true;
            _currentDotId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'dotacao',
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<DotacaoBloc, DotacaoState>(
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
              child: Scaffold(
                body: Stack(
                  children: [
                    const BackgroundClean(),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionIdentificacao(controller: widget.controller, users: users),
                          SectionVinculacaoProgramatica(controller: widget.controller),
                          SectionNaturezaDespesa(controller: widget.controller),
                          SectionReserva(controller: widget.controller),
                          SectionEmpenho(controller: widget.controller),
                          SectionCronograma(controller: widget.controller),
                          SectionDocumentosLinks(controller: widget.controller),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Dotação Orçamentária',
                      icon: Icons.account_balance_wallet_outlined,
                      busy: state.saving,
                      approved: pstate.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: () async {
                        await _saveOnly();

                        final dotId = context.read<DotacaoBloc>().state.dotacaoId;
                        if (dotId == null || dotId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
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
                            collectionName: 'dotacao',
                            stageId: dotId,
                            approverUid: uid,
                            approverName: nameOrEmail,
                          );
                          await repo.setCompleted(
                            contractId: widget.contractId,
                            collectionName: 'dotacao',
                            stageId: dotId,
                            completed: true,
                          );

                          // 🔹 Liberação otimista: próxima etapa (Minuta)
                          final pipeline = context.read<PipelineProgressCubit>();
                          pipeline.setStageEnabled(HiringStageKey.dotacao, true);
                          unawaited(pipeline.refresh());

                          final tab = DefaultTabController.of(context);
                          tab?.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
                              subtitle: const Text('Aprovado e etapa concluída.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
                              subtitle: const Text('Erro ao aprovar.'),
                              details: Text('$e'),
                              type: AppNotificationType.error,
                            ),
                          );
                        }
                      },
                      onUpdateApproved: () async {
                        await _saveOnly();

                        final dotId = context.read<DotacaoBloc>().state.dotacaoId;
                        if (dotId == null || dotId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
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
                            collectionName: 'dotacao',
                            stageId: dotId,
                            updatedByUid: uid,
                            updatedByName: nameOrEmail,
                          );
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
                              subtitle: const Text('Aprovação atualizada.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Dotação'),
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
            );
          },
        ),
      ),
    );
  }
}
