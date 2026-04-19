import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_2_empresa.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_3_certidoes.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_4_juridica_tecnica.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_5_licitacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_6_consolidacao.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';

class HabilitacaoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const HabilitacaoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<HabilitacaoPage> createState() => _HabilitacaoPageState();
}

class _HabilitacaoPageState extends State<HabilitacaoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  HabilitacaoData _formData = const HabilitacaoData.empty();
  bool _hydrated = false;
  String? _currentHabId;

  final _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());
    context.read<HabilitacaoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<HabilitacaoCubit>();

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

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<HabilitacaoCubit, HabilitacaoState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.habId != curr.habId),
        listener: (context, state) {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          final incomingId = state.habId;
          final needsHydrate = !_hydrated || _currentHabId != incomingId;

          if (needsHydrate) {
            final data = HabilitacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentHabId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'habilitacao',
              );
            }
          }
        },
        child: BlocBuilder<HabilitacaoCubit, HabilitacaoState>(
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
                stageKey: HiringStageKey.habilitacao,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('habilitacao-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadados(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionEmpresa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionCertidoes(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionJuridicaTecnica(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionLicitation(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) => setState(() => _formData = updated),
                            ),
                            const SizedBox(height: 12),
                            SectionConsolidation(
                              data: _formData,
                              isEditable: _isEditable,
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
                        title: 'Habilitação / Regularidade',
                        icon: Icons.verified_user_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          final habCubit = context.read<HabilitacaoCubit>();
                          final pipeline = context.read<PipelineProgressCubit>();
                          final controller = DefaultTabController.of(context);
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final habId = habCubit.state.habId;
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
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          try {
                            await repo.approveStage(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              completed: true,
                            );

                            if (!mounted) return;

                            pipeline.setStageEnabled(HiringStageKey.dotacao, true);
                            unawaited(pipeline.refresh());

                            controller.animateTo(
                              (controller.index + 1).clamp(0, controller.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Aprovado e etapa concluída.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
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
                          final habCubit = context.read<HabilitacaoCubit>();
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final habId = habCubit.state.habId;
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
                          final nameOrEmail =
                          (user?.displayName?.trim().isNotEmpty ?? false)
                              ? user!.displayName!
                              : (user?.email ?? uid);

                          try {
                            await repo.touchApproval(
                              contractId: widget.contractId,
                              collectionName: 'habilitacao',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            if (!mounted) return;

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Habilitação'),
                                subtitle: const Text('Aprovação atualizada.'),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
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