import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
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

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_2_documentos.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_3_checklist.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_4_conclusao.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_5_pendencias.dart';
import 'package:sipged/screens/modules/contracts/hiring/9Juridico/section_6_assinaturas.dart';

class ParecerJuridicoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const ParecerJuridicoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<ParecerJuridicoPage> createState() => _ParecerJuridicoPageState();
}

class _ParecerJuridicoPageState extends State<ParecerJuridicoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  ParecerJuridicoData _formData = const ParecerJuridicoData.empty();
  bool _hydrated = false;
  String? _currentParecerId;

  final _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());
    context.read<ParecerJuridicoCubit>().load(widget.contractId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<ParecerJuridicoCubit>();

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

    final users = context.select<UserBloc, List<UserData>>(
          (b) => b.state.all,
    );

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<ParecerJuridicoCubit, ParecerState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) ||
            (prev.parecerId != curr.parecerId),
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.parecerId;
          final needsHydrate = !_hydrated || _currentParecerId != incomingId;

          if (needsHydrate) {
            final data =
            ParecerJuridicoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
            });

            _hydrated = true;
            _currentParecerId = incomingId;

            if (incomingId != null && incomingId.isNotEmpty) {
              _progressBloc.bindToStage(
                contractId: widget.contractId,
                collectionName: 'parecer',
              );
            }
          }
        },
        child: BlocBuilder<ParecerJuridicoCubit, ParecerState>(
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
                stageKey: HiringStageKey.parecer,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('parecer-juridico-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadados(
                              data: _formData,
                              isEditable: _isEditable,
                              users: users,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionDocumentos(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionChecklist(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionConclusao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionPendencias(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            SectionAssinaturas(
                              data: _formData,
                              isEditable: _isEditable,
                              users: users,
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
                        title: 'Parecer Jurídico',
                        icon: Icons.gavel_outlined,
                        busy: state.saving,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: () async {
                          final parecerCubit =
                          context.read<ParecerJuridicoCubit>();
                          final pipeline =
                          context.read<PipelineProgressCubit>();
                          final tab = DefaultTabController.of(context);
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final parecerId = parecerCubit.state.parecerId;

                          if (parecerId == null || parecerId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Parecer Jurídico'),
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
                              collectionName: 'parecer',
                              approverUid: uid,
                              approverName: nameOrEmail,
                            );

                            await repo.setCompleted(
                              contractId: widget.contractId,
                              collectionName: 'parecer',
                              completed: true,
                            );

                            if (!mounted) return;

                            pipeline.setStageEnabled(
                              HiringStageKey.parecer,
                              true,
                            );
                            unawaited(pipeline.refresh());

                            tab.animateTo(
                              (tab.index + 1).clamp(0, tab.length - 1),
                            );

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Parecer Jurídico'),
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
                                title: const Text('Parecer Jurídico'),
                                subtitle: const Text('Erro ao aprovar.'),
                                details: Text('$e'),
                                type: AppNotificationType.error,
                              ),
                            );
                          }
                        },
                        onUpdateApproved: () async {
                          final parecerCubit =
                          context.read<ParecerJuridicoCubit>();
                          final repo = _progressBloc.repo;

                          await _saveOnly();

                          if (!mounted) return;

                          final parecerId = parecerCubit.state.parecerId;
                          if (parecerId == null || parecerId.isEmpty) {
                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Parecer Jurídico'),
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
                              collectionName: 'parecer',
                              updatedByUid: uid,
                              updatedByName: nameOrEmail,
                            );

                            if (!mounted) return;

                            NotificationCenter.instance.show(
                              AppNotification(
                                title: const Text('Parecer Jurídico'),
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
                                title: const Text('Parecer Jurídico'),
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