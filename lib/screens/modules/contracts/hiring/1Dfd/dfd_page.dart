// lib/screens/modules/contracts/hiring/1Dfd/dfd_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Progress (etapas)
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

// ===== DFD
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

// ===== Usuários
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

// ===== Widgets / UI
import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

// ===== Utils
import 'package:sipged/_utils/validates/sipged_validation.dart';

// ===== Overlay leve
import 'package:sipged/_widgets/overlays/screen_lock.dart';

// ===== Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// ===== Pipeline (habilitação dinâmica das abas)
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

// ===== Sections
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_1_identificacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_2_objeto.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_3_localizacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_4_estimativa.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_5_riscos.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_6_documentos.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_7_aprovacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_8_observacoes.dart';

class DfdPage extends StatefulWidget {
  final String contractId; // pode vir vazio para novo contrato
  final bool readOnly;

  const DfdPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<DfdPage> createState() => _DfdPageState();
}

class _DfdPageState extends State<DfdPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ProgressCubit _progressBloc;

  DfdData _formData = const DfdData.empty();
  bool _hydrated = false;
  String? _currentDfdId;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressBloc = ProgressCubit(repo: ProgressRepository());

    // Se já existe contractId, carregamos o DFD.
    final cid = widget.contractId.trim();
    if (cid.isNotEmpty) {
      // Safe: chama após frame inicial para evitar qualquer interação com build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DfdCubit>().load(cid);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _saveOnly() async {
    final cubit = context.read<DfdCubit>();

    final completer = Completer<void>();
    late final StreamSubscription sub;

    sub = cubit.stream.listen((s) {
      if (!s.saving) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    final currentIdFromState = cubit.state.contractId;
    final initialId =
    widget.contractId.trim().isNotEmpty ? widget.contractId.trim() : null;

    final finalContractId = await cubit.saveAllWithAutoContract(
      contractId: currentIdFromState ?? initialId,
      data: _formData,
    );

    await completer.future;

    if (!cubit.state.saveSuccess || finalContractId == null) {
      final err = cubit.state.error ?? 'Falha ao salvar';
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

    _progressBloc.bindToStage(
      contractId: finalContractId,
      collectionName: 'dfd',
    );

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

    final users = context.select<UserBloc, List<UserData>>(
          (b) => b.state.all,
    );

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<DfdCubit, DfdState>(
        listenWhen: (prev, curr) =>
        (prev.loading && !curr.loading) || (prev.dfdId != curr.dfdId),
        listener: (context, state) {
          if (!mounted) return;
          if (state.loading || !state.hasValidPath) return;

          final incomingId = state.dfdId;
          final needsHydrate = !_hydrated || _currentDfdId != incomingId;

          if (!needsHydrate) return;

          final data = DfdData.fromSectionsMap(state.sectionsData);

          // Listener é seguro para setState (não é build). Mantemos aqui.
          setState(() {
            _formData = data;
            _hydrated = true;
            _currentDfdId = incomingId;
          });

          final effectiveContractId = state.contractId ?? widget.contractId.trim();
          if ((incomingId ?? '').isNotEmpty && effectiveContractId.isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: effectiveContractId,
              collectionName: 'dfd',
            );
          }
        },
        child: BlocBuilder<DfdCubit, DfdState>(
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

            final effectiveContractId = state.contractId ?? widget.contractId.trim();

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Por favor, aguarde.' : null,
              keepAppBarUndimmed: true,
              child: Scaffold(
                body: Stack(
                  children: [
                    const BackgroundChange(),
                    SingleChildScrollView(
                      key: const PageStorageKey('dfd-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionIdentificacao(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              // aqui é OK (originado por interação de UI)
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionObjeto(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionLocalizacao(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionEstimativa(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionRiscos(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionDocumentos(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            contractId: effectiveContractId,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionAprovacao(
                            data: _formData,
                            users: users,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
                          ),
                          const SizedBox(height: 12),

                          SectionObservacoes(
                            data: _formData,
                            isEditable: !widget.readOnly,
                            onChanged: (updated) {
                              setState(() => _formData = updated);
                            },
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
                      title: 'Documento de Formalização de Demanda (DFD)',
                      icon: Icons.assignment_turned_in_outlined,
                      busy: state.saving,
                      approved: pstate.approved,
                      onSave: _saveOnly,
                      onSaveAndNext: () async {
                        await _saveOnly();

                        final dfdState = context.read<DfdCubit>().state;
                        final dfdId = dfdState.dfdId;
                        final contractIdForApprove =
                            dfdState.contractId ?? widget.contractId.trim();

                        if ((dfdId ?? '').isEmpty || contractIdForApprove.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
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
                            contractId: contractIdForApprove,
                            collectionName: 'dfd',
                            approverUid: uid,
                            approverName: nameOrEmail,
                          );

                          await repo.setCompleted(
                            contractId: contractIdForApprove,
                            collectionName: 'dfd',
                            responsibleUserId: _formData.solicitanteUserId,
                            approverUserId: _formData.autoridadeUserId,
                            responsibleName: _formData.solicitanteNome,
                            approverName: _formData.autoridadeAprovadora,
                            completed: true,
                          );

                          final pipeline = context.read<PipelineProgressCubit>();
                          pipeline.setStageEnabled(HiringStageKey.etp, true);
                          unawaited(pipeline.refresh());

                          final tab = DefaultTabController.of(context);
                          tab.animateTo((tab.index + 1).clamp(0, tab.length - 1));

                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
                              subtitle: const Text('Aprovado e etapa concluída.'),
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

                        final dfdState = context.read<DfdCubit>().state;
                        final dfdId = dfdState.dfdId;
                        final contractIdForApprove =
                            dfdState.contractId ?? widget.contractId.trim();

                        if ((dfdId ?? '').isEmpty || contractIdForApprove.isEmpty) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('DFD'),
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
                            contractId: contractIdForApprove,
                            collectionName: 'dfd',
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
