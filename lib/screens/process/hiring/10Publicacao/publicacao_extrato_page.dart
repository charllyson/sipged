import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Users / Utils =====
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

// ===== Layout / Widgets =====
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/overlays/screen_lock.dart';
import 'package:siged/_widgets/progress/stage_progress.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ===== Progress (etapas) =====
import 'package:siged/_blocs/process/hiring/0Progress/progress_bloc.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_event.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_state.dart';
import 'package:siged/_blocs/process/hiring/0Progress/progress_repository.dart';
import 'package:siged/_blocs/process/hiring/0Progress/pipeline_progress_cubit.dart';

import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

// ===== Publicação / Extrato =====
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_1_metadados.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_2_partes_valores.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_3_veiculo.dart';

// ===== Seções =====
import 'package:siged/screens/process/hiring/10Publicacao/section_4_status_prazos.dart';
import 'package:siged/screens/process/hiring/10Publicacao/section_5_responsavel.dart';

class PublicacaoExtratoPage extends StatefulWidget {
  final PublicacaoExtratoController controller;
  final String contractId; // ⬅️ necessário para carregar/salvar a etapa
  final bool readOnly;

  const PublicacaoExtratoPage({
    super.key,
    required this.controller,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<PublicacaoExtratoPage> createState() => _PublicacaoExtratoPageState();
}

class _PublicacaoExtratoPageState extends State<PublicacaoExtratoPage>
    with FormValidationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressBloc _progressBloc;
  bool _hydrated = false;
  String? _currentPubId;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressBloc(repo: ProgressRepository());
    widget.controller.isEditable = !widget.readOnly;

    // Dispara o carregamento da estrutura/dados
    context.read<PublicacaoExtratoBloc>()
        .add(PublicacaoExtratoLoadRequested(widget.contractId));
  }

  @override
  void dispose() {
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final bloc = context.read<PublicacaoExtratoBloc>();

    // validação rápida se você tiver algum método no controller (opcional)
    // final quick = widget.controller.quickValidate();
    // if (quick != null) { ... }

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    bloc.add(PublicacaoExtratoSaveRequested(
      contractId: widget.contractId,
      sectionsData: widget.controller.toSectionMaps(), // mantém seu padrão
    ));

    await completer.future;

    if (!bloc.state.saveSuccess) {
      final err = bloc.state.error ?? 'Falha ao salvar';
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Publicação / Extrato'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Publicação / Extrato'),
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
      child: BlocListener<PublicacaoExtratoBloc, PublicacaoExtratoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.pubId != curr.pubId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.pubId;
          final needsHydrate = !_hydrated || _currentPubId != incomingId;
          if (needsHydrate) {
            // hidrata o controller com os maps vindos do Firestore
            widget.controller.fromSectionMaps(state.sectionsData);
            _hydrated = true;
            _currentPubId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.add(ProgressBindRequested(
                contractId: widget.contractId,
                collectionName: 'publicacao', // coleção da etapa
                stageId: incomingId,
              ));
            }
          }
        },
        child: BlocBuilder<PublicacaoExtratoBloc, PublicacaoExtratoState>(
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
                          // Seções em arquivos separados
                          SectionMetadadosExtrato(controller: widget.controller),
                          SectionPartesValoresVigencia(controller: widget.controller),
                          SectionVeiculoPublicacao(controller: widget.controller),
                          SectionStatusPrazos(controller: widget.controller),
                          SectionResponsavel(controller: widget.controller),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, pstate) {
                    return StageProgress(
                      title: 'Publicação / Extrato',
                      icon: Icons.campaign_outlined,
                      busy: state.saving,
                      approved: pstate.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: () async {
                        await _saveOnly();

                        final pubId = context.read<PublicacaoExtratoBloc>().state.pubId;
                        if (pubId == null || pubId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
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
                            collectionName: 'publicacao',
                            stageId: pubId,
                            approverUid: uid,
                            approverName: nameOrEmail,
                          );
                          await repo.setCompleted(
                            contractId: widget.contractId,
                            collectionName: 'publicacao',
                            stageId: pubId,
                            completed: true,
                          );

                          // 🔹 Liberação otimista da próxima etapa (ajuste a chave conforme seu enum)
                          final pipeline = context.read<PipelineProgressCubit>();
                          pipeline.setStageEnabled(HiringStageKey.publicacao, true);
                          unawaited(pipeline.refresh());

                          final tab = DefaultTabController.of(context);
                          tab?.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
                              subtitle: const Text('Aprovado e etapa concluída.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
                              subtitle: const Text('Erro ao aprovar.'),
                              details: Text('$e'),
                              type: AppNotificationType.error,
                            ),
                          );
                        }
                      },
                      onUpdateApproved: () async {
                        await _saveOnly();

                        final pubId = context.read<PublicacaoExtratoBloc>().state.pubId;
                        if (pubId == null || pubId.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
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
                            collectionName: 'publicacao',
                            stageId: pubId,
                            updatedByUid: uid,
                            updatedByName: nameOrEmail,
                          );
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
                              subtitle: const Text('Aprovação atualizada.'),
                              type: AppNotificationType.success,
                            ),
                          );
                        } catch (e) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Publicação / Extrato'),
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
