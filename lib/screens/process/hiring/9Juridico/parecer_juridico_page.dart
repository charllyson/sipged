// lib/screens/process/hiring/9Juridico/parecer_juridico_page.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Users / Utils
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// Layout / Widgets
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Progress
import 'package:siged/_blocs/process/hiring/0Stages/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Stages/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:siged/_blocs/process/hiring/0Stages/pipeline_progress.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_stages.dart';

// Parecer
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_bloc.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

// Sections
import 'package:siged/screens/process/hiring/9Juridico/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/9Juridico/section_2_documentos.dart';
import 'package:siged/screens/process/hiring/9Juridico/section_3_checklist.dart';
import 'package:siged/screens/process/hiring/9Juridico/section_4_conclusao.dart';
import 'package:siged/screens/process/hiring/9Juridico/section_5_pendencias.dart';
import 'package:siged/screens/process/hiring/9Juridico/section_6_assinaturas.dart';

class ParecerJuridicoPage extends StatefulWidget {
  final ParecerJuridicoController controller;
  final String contractId;
  final bool readOnly;

  const ParecerJuridicoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<ParecerJuridicoPage> createState() => _ParecerJuridicoPageState();
}

class _ParecerJuridicoPageState extends State<ParecerJuridicoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentParecerId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    widget.controller.setEditable(!widget.readOnly);

    context.read<ParecerJuridicoBloc>().add(ParecerLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<ParecerJuridicoBloc>();

    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação do Parecer'),
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

    bloc.add(ParecerSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Parecer Jurídico'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Parecer Jurídico'),
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
      child: BlocListener<ParecerJuridicoBloc, ParecerState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.parecerId != curr.parecerId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.parecerId;
          final needsHydrate = !_hydrated || _currentParecerId != incomingId;
          if (needsHydrate) {
            widget.controller.fromSectionMaps(state.sectionsData);
            _hydrated = true;
            _currentParecerId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'parecer', // coleção da etapa
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<ParecerJuridicoBloc, ParecerState>(
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
                          SectionMetadados(controller: widget.controller, users: users),
                          SectionDocumentos(controller: widget.controller),
                          SectionChecklist(controller: widget.controller),
                          SectionConclusao(controller: widget.controller),
                          SectionPendencias(controller: widget.controller),
                          SectionAssinaturas(controller: widget.controller, users: users),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Parecer Jurídico',
                      icon: Icons.gavel_outlined,
                      busy: state.saving,
                      approved: pstate.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: () async {
                        await _saveOnly();

                        final parecerId = context.read<ParecerJuridicoBloc>().state.parecerId;
                        if (parecerId == null || parecerId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
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
                            collectionName: 'parecer',
                            stageId: parecerId,
                            approverUid: uid,
                            approverName: nameOrEmail,
                          );
                          await repo.setCompleted(
                            contractId: widget.contractId,
                            collectionName: 'parecer',
                            stageId: parecerId,
                            completed: true,
                          );

                          // 🔹 Liberação otimista da próxima etapa: Publicação
                          final pipeline = context.read<PipelineProgressCubit>();
                          pipeline.setStageEnabled(HiringStageKey.parecer, true); // ← ajuste se o enum divergir
                          unawaited(pipeline.refresh());

                          final tab = DefaultTabController.of(context);
                          tab?.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
                              subtitle: const Text('Aprovado e etapa concluída.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
                              subtitle: const Text('Erro ao aprovar.'),
                              details: Text('$e'),
                              type: AppNotificationType.error,
                            ),
                          );
                        }
                      },
                      onUpdateApproved: () async {
                        await _saveOnly();

                        final parecerId = context.read<ParecerJuridicoBloc>().state.parecerId;
                        if (parecerId == null || parecerId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
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
                            collectionName: 'parecer',
                            stageId: parecerId,
                            updatedByUid: uid,
                            updatedByName: nameOrEmail,
                          );
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
                              subtitle: const Text('Aprovação atualizada.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Parecer Jurídico'),
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
