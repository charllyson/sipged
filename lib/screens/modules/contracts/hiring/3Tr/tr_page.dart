// lib/screens/modules/contracts/hiring/3Tr/tr_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/overlays/screen_lock.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_progress_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_1_objeto_fundamentacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_2_escopo_requisitos.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_3_local_prazos_cronograma.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_4_medicao_aceite_indicadores.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_5_obrigacoes_equipe_gestao.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_6_licenciamento_seguranca_sustentabilidade.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_7_precos_pagamento_reajuste.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_8_riscos_penalidades_condicoes.dart';
import 'package:sipged/screens/modules/contracts/hiring/3Tr/section_9_documentos_referencias.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

class TermoReferenciaPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const TermoReferenciaPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<TermoReferenciaPage> createState() => _TermoReferenciaPageState();
}

class _TermoReferenciaPageState extends State<TermoReferenciaPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const String _notificationSource = 'contracts_hiring_tr';
  static const String _route = 'contracts_hiring_tr';

  late final ProgressCubit _progressBloc;

  TrData _formData = const TrData.empty();
  ProcessData _contract = ProcessData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentTrId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ProcessData get _effectiveContract {
    if ((_contract.id ?? '').trim().isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);
    return _contract;
  }

  @override
  void initState() {
    super.initState();

    _progressBloc = ProgressCubit(repo: ProgressRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_contractId.isNotEmpty) {
        context.read<TrCubit>().load(_contractId);
        unawaited(_loadContract(_contractId));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressBloc.close();
    super.dispose();
  }

  Future<void> _loadContract(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    if (mounted) {
      setState(() => _loadingContract = true);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(cid)
          .get();

      if (!mounted) return;

      setState(() {
        _contract = snapshot.exists
            ? ProcessData.fromDocument(snapshot: snapshot)
            : ProcessData.empty().copyWith(id: cid);

        _loadingContract = false;
      });
    } catch (e) {
      debugPrint('[TermoReferenciaPage] Erro ao carregar contrato $cid: $e');

      if (!mounted) return;

      setState(() {
        _contract = ProcessData.empty().copyWith(id: cid);
        _loadingContract = false;
      });
    }
  }

  String _currentActorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade com chamadas antigas.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,

    /// Quando vazio, o helper deve resolver todos os usuários com permissão no contrato.
    Iterable<String> targetUserIds = const <String>[],

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final effectiveContract = _effectiveContract;

    await NotificationHiring.show(
      context: context,
      contract: effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'TR',
      module: _route,
      notificationSource: _notificationSource,
      source: 'tr_notification',
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: NotificationDelivery.localBellAndPush,
      targetUserIds: targetUserIds,
      actorId: user?.uid,
      actorName: _currentActorName(),
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'tr_notification',
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,
        if ((effectiveContract.id ?? '').trim().isNotEmpty)
          'contractId': effectiveContract.id,
        if (effectiveContract.displaySummary.trim().isNotEmpty)
          'contractSummary': effectiveContract.displaySummary,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'TR',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final cubit = context.read<TrCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'TR',
          subtitle: 'Erro ao salvar.',
          details: err,
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(_contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: _contractId,
        collectionName: 'tr',
      );

      if (notifySuccess) {
        await _notify(
          title: 'TR atualizado',
          subtitle: 'Alterações salvas por ${_currentActorName()}.',
          details: _effectiveContract.displaySummary,
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,

          /// Vazio = todos com permissão ao contrato.
          targetUserIds: const <String>[],

          extra: <String, dynamic>{
            'action': 'tr_saved',
            'trId': cubit.state.trId,
            'contractId': _contractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'TR',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final trCubit = context.read<TrCubit>();
    final pipeline = context.read<PipelineProgressCubit>();
    final tab = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final trId = trCubit.state.trId;

    if (trId == null || trId.isEmpty) {
      await _notify(
        title: 'TR',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: _contractId,
        collectionName: 'tr',
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: 'tr',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.cotacao, true);
      unawaited(pipeline.refresh());

      tab.animateTo(
        (tab.index + 1).clamp(0, tab.length - 1),
      );

      await _notify(
        title: 'TR aprovado',
        subtitle: 'Etapa concluída por $actorName.',
        details: _effectiveContract.displaySummary,
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,

        /// Vazio = todos com permissão ao contrato.
        targetUserIds: const <String>[],

        extra: <String, dynamic>{
          'action': 'tr_approved',
          'trId': trId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': 'cotacao',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'TR',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final trCubit = context.read<TrCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final trId = trCubit.state.trId;

    if (trId == null || trId.isEmpty) {
      await _notify(
        title: 'TR',
        subtitle: 'Documento não encontrado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: _contractId,
        collectionName: 'tr',
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação do TR atualizada',
        subtitle: 'Atualizada por $actorName.',
        details: _effectiveContract.displaySummary,
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,

        /// Vazio = todos com permissão ao contrato.
        targetUserIds: const <String>[],

        extra: <String, dynamic>{
          'action': 'tr_approval_updated',
          'trId': trId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'TR',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _progressBloc,
      child: BlocListener<TrCubit, TrState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.trId != curr.trId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.trId;
          final needsHydrate = !_hydrated || _currentTrId != incomingId;

          if (needsHydrate) {
            final data = TrData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentTrId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: _contractId,
              collectionName: 'tr',
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
            }
          }
        },
        child: BlocBuilder<TrCubit, TrState>(
          builder: (context, state) {
            final pstate = context.watch<ProgressCubit>().state;

            final locked = state.loading ||
                state.saving ||
                pstate.loading ||
                _loadingContract;

            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : pstate.loading
                ? 'Atualizando aprovação...'
                : _loadingContract
                ? 'Carregando dados do contrato...'
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
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('tr-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionObjetoFundamentacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionEscopoRequisitos(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionLocalPrazosCronograma(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionMedicaoAceiteIndicadores(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionObrigacoesEquipeGestao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionLicenciamentoSegurancaSustentabilidade(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionPrecosPagamentoReajuste(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionRiscosPenalidadesCondicoes(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionDocumentosReferencias(
                              data: _formData,
                              isEditable: _isEditable,
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
                        title: 'Termo de Referência',
                        icon: Icons.rule_folder_outlined,
                        busy: state.saving || pstate.loading,
                        approved: pstate.approved,
                        onSave: _saveOnly,
                        onSaveAndNext: _saveApproveAndNext,
                        onUpdateApproved: _updateApproved,
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