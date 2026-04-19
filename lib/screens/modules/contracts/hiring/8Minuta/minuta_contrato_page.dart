import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_state.dart';

import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_1_identificacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_2_partes_objeto.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_3_valor.dart';
import 'package:sipged/screens/modules/contracts/hiring/8Minuta/section_4_gestao_refs.dart';

class MinutaContratoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const MinutaContratoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<MinutaContratoPage> createState() => _MinutaContratoPageState();
}

class _MinutaContratoPageState extends State<MinutaContratoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  MinutaContratoData _formData = const MinutaContratoData.empty();
  bool _hydrated = false;
  String? _currentMinutaId;

  final _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());
    context.read<MinutaContratoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<MinutaContratoCubit>();

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
          title: const Text('Minuta'),
          subtitle: const Text('Erro ao salvar.'),
          details: Text(err),
          type: AppNotificationType.error,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Minuta'),
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
      child: BlocListener<MinutaContratoCubit, MinutaState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) ||
            (prev.minutaId != curr.minutaId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.minutaId;
          final needsHydrate = !_hydrated || _currentMinutaId != incomingId;
          if (needsHydrate) {
            final data = MinutaContratoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentMinutaId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'minuta',
              );
            }
          }
        },
        child: BlocBuilder<MinutaContratoCubit, MinutaState>(
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
                stageKey: HiringStageKey.minuta,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('minuta-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionIdentificacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionPartesObjeto(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionValor(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionGestaoRefs(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar:
                  BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, pstate) {
                      return StageProgress(
                        title: 'Minuta do Contrato',
                        icon: Icons.description_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          final minutaCubit =
                          context.read<MinutaContratoCubit>();
                          final pipeline =
                          context.read<PipelineProgressCubit>();
                          final tab = DefaultTabController.of(context);
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final minutaId = minutaCubit.state.minutaId;
                          if (minutaId == null || minutaId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text(
                                  'Documento não encontrado para aprovar.',
                                ),
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
                              collectionName: 'minuta',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'minuta',
                              completed: true,
                            );

                            if (!mounted) return;

                            pipeline.setStageEnabled(
                              HiringStageKey.minuta,
                              true,
                            );
                            unawaited(pipeline.refresh());

                            tab.animateTo(
                              (tab.index + 1).clamp(0, tab.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text(
                                  'Aprovado e etapa concluída.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          final minutaCubit =
                          context.read<MinutaContratoCubit>();
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final minutaId = minutaCubit.state.minutaId;
                          if (minutaId == null || minutaId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text(
                                  'Documento não encontrado para atualizar.',
                                ),
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
                              collectionName: 'minuta',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            if (!mounted) return;

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text(
                                  'Aprovação atualizada.',
                                ),
                                type: AppNotificationType.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Minuta'),
                                subtitle: const Text(
                                  'Erro ao atualizar aprovação.',
                                ),
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