// lib/screens/process/hiring/1Dfd/dfd_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// ===== Progress (etapas)
import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';

// ===== DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

// ===== Usuários
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ===== Widgets / UI
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';

// ===== Seções
import 'package:siged/screens/process/hiring/1Dfd/section_1_identificacao.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_2_objeto.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_3_localizacao.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_4_estimativa.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_5_riscos.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_6_documentos.dart'; // lazy interna
import 'package:siged/screens/process/hiring/1Dfd/section_7_aprovacao.dart';
import 'package:siged/screens/process/hiring/1Dfd/section_8_observacoes.dart';

// ===== Utils
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// ===== Overlay leve
import 'package:siged/_widgets/overlays/screen_lock.dart';

// ===== Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ===== Pipeline (habilitação dinâmica das abas)
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

class DfdPage extends StatefulWidget {
  final DfdController controller;
  final String contractId;

  const DfdPage({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  State<DfdPage> createState() => _DfdPageState();
}

class _DfdPageState extends State<DfdPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ===== Progress bloc FIXO (não recriar no build)
  late final ProgressBloc _progressBloc;

  // ===== Controle de hidratação e IDs atuais
  bool _hydrated = false;
  String? _currentDfdId;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());

    // Dispara o load inicial do DFD
    context.read<DfdBloc>().add(DfdLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<DfdBloc>();
    final quick = widget.controller.quickValidate();
    if (quick != null) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Validação do DFD'),
          subtitle: Text(quick),
          type: AppNotificationType.warning,
        ),
      );
      return;
    }

    // <<< Aguarda transição saving true->false uma única vez >>>
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(DfdSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(),
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('DFD'),
            subtitle: const Text('Erro ao salvar.'),
            details: Text(err),
            type: AppNotificationType.error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('DFD'),
          subtitle: const Text('Alterações salvas com sucesso.'),
          type: AppNotificationType.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final c = widget.controller;
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return BlocProvider.value(
      value: _progressBloc, // bloc fixo para os filhos
      child: BlocListener<DfdBloc, DfdState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.dfdId != curr.dfdId),
        listener: (context, state) async {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          // Hidrata sempre que trocar o dfdId
          final incomingId = state.dfdId;
          final needsHydrate = !_hydrated || _currentDfdId != incomingId;
          if (needsHydrate) {
            c.fromSectionMaps(state.sectionsData); // pode vir lista vazia (limpa)
            _hydrated = true;
            _currentDfdId = incomingId;
            setState(() {}); // reflete no UI
          }

          // Bind único (ProgressBloc deduplica)
          if (incomingId != null && incomingId.isNotEmpty) {
            _progressBloc.add(ProgressBindRequested(
              contractId: widget.contractId,
              collectionName: 'dfd',
              stageId: incomingId,
            ));
          }
        },
        child: BlocBuilder<DfdBloc, DfdState>(
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
                      key: const PageStorageKey('dfd-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 12, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionIdentificacao(controller: c),
                          SectionObjeto(controller: c),
                          SectionLocalizacao(controller: c),
                          SectionEstimativa(controller: c),
                          SectionRiscos(controller: c),

                          // Documentos (lazy interna)
                          SectionDocumentos(
                            controller: c,
                            contractId: widget.contractId,
                          ),

                          SectionAprovacao(controller: c, users: users),
                          SectionObservacoes(controller: c),
                          const SizedBox(height: 8),
                          if (state.loading)
                            const LinearProgressIndicator(minHeight: 2),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rodapé dinâmico (approved -> Atualizar)
                bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Documento de Formalização de Demanda (DFD)',
                      icon: Icons.assignment_turned_in_outlined,
                      busy: state.saving,
                      approved: pstate.approved,

                      onSave: _saveOnly,

                      onSaveAndNext: () async {
                        await _saveOnly();

                        final dfdId = context.read<DfdBloc>().state.dfdId;
                        if (dfdId == null || dfdId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
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
                            collectionName: 'dfd',
                            stageId: dfdId,
                            approverUid: uid,
                            approverName: nameOrEmail,
                          );

                          await repo.setCompleted(
                            contractId: widget.contractId,
                            collectionName: 'dfd',
                            stageId: dfdId,
                            completed: true,
                            responsibleUserId: c.dfdSolicitanteUserId,
                            approverUserId: c.dfdAutoridadeAprovadoraUserId,
                            responsibleName: c.dfdSolicitanteCtrl.text,
                            approverName: c.dfdAutoridadeAprovadoraCtrl.text,
                          );

                          // 🔹 Liberação otimista da próxima etapa + refresh
                          final pipeline =
                          context.read<PipelineProgressCubit>();
                          pipeline.setStageEnabled(HiringStageKey.etp, true);
                          unawaited(pipeline.refresh());

                          // Vai para a próxima aba
                          final tab = DefaultTabController.of(context);
                          tab?.animateTo((tab.index + 1)
                              .clamp(0, tab.length - 1));

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
                              subtitle:
                              const Text('Aprovado e etapa concluída.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
                              subtitle: const Text('Erro ao aprovar.'),
                              details: Text('$e'),
                              type: AppNotificationType.error,
                            ),
                          );
                        }
                      },

                      onUpdateApproved: () async {
                        await _saveOnly();

                        final dfdId = context.read<DfdBloc>().state.dfdId;
                        if (dfdId == null || dfdId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
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
                            collectionName: 'dfd',
                            stageId: dfdId,
                            updatedByUid: uid,
                            updatedByName: nameOrEmail,
                          );

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
                              subtitle: const Text('Aprovação atualizada.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
                              subtitle:
                              const Text('Erro ao atualizar aprovação.'),
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
