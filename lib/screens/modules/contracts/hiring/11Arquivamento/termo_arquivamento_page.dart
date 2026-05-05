// lib/screens/modules/contracts/hiring/11Arquivamento/termo_arquivamento_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_state.dart';

import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_2_motivo_abrangencia.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_3_fundamentacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_4_pecas_anexas.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_5_decisao_autoridade.dart';
import 'package:sipged/screens/modules/contracts/hiring/11Arquivamento/section_6_reabertura.dart';

class TermoArquivamentoPage extends StatefulWidget {
  final String contractId;
  final bool readOnly;

  const TermoArquivamentoPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  @override
  State<TermoArquivamentoPage> createState() => _TermoArquivamentoPageState();
}

class _TermoArquivamentoPageState extends State<TermoArquivamentoPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const String _route = 'contracts_hiring_arquivamento';
  static const String _notificationSource = 'contracts_hiring_arquivamento';

  final DfdRepository _dfdRepository = DfdRepository();

  late final ProgressCubit _progressBloc;

  TermoArquivamentoData _formData = const TermoArquivamentoData.empty();
  ProcessData _contract = ProcessData.empty();
  DfdData? _dfdData;

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentTaId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ProcessData get _effectiveContract {
    final currentId = (_contract.id ?? '').trim();

    if (currentId.isNotEmpty) return _contract;
    if (_contractId.isNotEmpty) return _contract.copyWith(id: _contractId);

    return _contract;
  }

  String get _notificationDemandName {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    final displaySummary = _contract.displaySummary.trim();

    if (displaySummary.isNotEmpty &&
        displaySummary != 'Contrato $_contractId' &&
        !displaySummary.startsWith('Contrato ')) {
      return displaySummary;
    }

    return 'Demanda sem identificação';
  }

  String get _processNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    _progressBloc = ProgressCubit(repo: ProgressRepository());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contractId = _contractId;
      if (contractId.isEmpty) return;

      context.read<TermoArquivamentoCubit>().load(contractId);
      unawaited(_loadContract(contractId));
      unawaited(_loadDfdData(contractId));
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
    } catch (e, stack) {
      debugPrint('[TermoArquivamentoPage] Erro ao carregar contrato $cid: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _contract = ProcessData.empty().copyWith(id: cid);
        _loadingContract = false;
      });
    }
  }

  Future<void> _loadDfdData(String contractId) async {
    final cid = contractId.trim();
    if (cid.isEmpty) return;

    try {
      final data = await _dfdRepository.readDataForContract(cid);

      if (!mounted) return;

      setState(() {
        _dfdData = data;
      });
    } catch (e, stack) {
      debugPrint('[TermoArquivamentoPage] Falha ao carregar DFD: $e');
      debugPrintStack(stackTrace: stack);
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

  String _currentActorPhotoUrl() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';

    if (uid.isNotEmpty) {
      final users = context.read<UserCubit>().state.all;

      for (final item in users) {
        if ((item.uid ?? '').trim() == uid) {
          final photo = item.urlPhoto?.trim() ?? '';
          if (photo.isNotEmpty) return photo;
        }
      }
    }

    final firebasePhoto = user?.photoURL?.trim() ?? '';
    if (firebasePhoto.isNotEmpty) return firebasePhoto;

    return '';
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

    /// Vazio = NotificationHiring resolve todos os usuários com permissão ao contrato.
    Iterable<String> targetUserIds = const <String>[],

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final actorId = user?.uid.trim();
    final actorName = _currentActorName();
    final actorPhotoUrl = _currentActorPhotoUrl();

    final effectiveContract = _effectiveContract;
    final effectiveContractId = (effectiveContract.id ?? _contractId).trim();
    final demandName = _notificationDemandName;

    await NotificationHiring.show(
      context: context,
      contract: effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      module: _route,
      notificationSource: _notificationSource,
      source: 'arquivamento_notification',
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: NotificationDelivery.localBellAndPush,
      targetUserIds: targetUserIds,
      actorId: actorId,
      actorName: actorName,
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'arquivamento_notification',
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,
        'actorId': actorId,
        'actorName': actorName,
        if (actorPhotoUrl.isNotEmpty) 'actorPhotoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoURL': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'profilePhotoUrl': actorPhotoUrl,
        if (effectiveContractId.isNotEmpty) 'contractId': effectiveContractId,
        'contractTitle': demandName,
        'contractSummary': demandName,
        'descricaoObjeto': demandName,
        'nomeDemanda': demandName,
        if (_processNumber.trim().isNotEmpty) 'contractNumber': _processNumber,
        if (_processNumber.trim().isNotEmpty) 'processNumber': _processNumber,
        if (_processNumber.trim().isNotEmpty)
          'processoAdministrativo': _processNumber,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final contractId = _contractId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Contrato não identificado para salvar.',
        status: NotificationStatus.error,
      );
      return false;
    }

    final cubit = context.read<TermoArquivamentoCubit>();

    try {
      await cubit.saveAll(
        contractId: contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        await _notify(
          title: 'Termo de Arquivamento',
          subtitle: 'Erro ao salvar.',
          details: cubit.state.error ?? 'Falha ao salvar',
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(contractId);
      await _loadDfdData(contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: contractId,
        collectionName: 'arquivamento',
      );

      if (notifySuccess) {
        final actorName = _currentActorName();

        await _notify(
          title: 'Termo de Arquivamento atualizado',
          subtitle: _notificationDemandName,
          details: 'Alterado por $actorName.',
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'arquivamento_saved',
            'taId': cubit.state.taId,
            'contractId': contractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final taCubit = context.read<TermoArquivamentoCubit>();
    final pipeline = context.read<PipelineCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final taId = taCubit.state.taId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Contrato não identificado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (taId == null || taId.isEmpty) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: contractId,
        collectionName: 'arquivamento',
        approverUid: user?.uid ?? '',
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: contractId,
        collectionName: 'arquivamento',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.arquivamento, true);
      unawaited(pipeline.refresh());

      await _notify(
        title: 'Termo de Arquivamento aprovado',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'arquivamento_approved',
          'taId': taId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final taCubit = context.read<TermoArquivamentoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final contractId = _contractId;
    final taId = taCubit.state.taId;

    if (contractId.isEmpty) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Contrato não identificado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    if (taId == null || taId.isEmpty) {
      await _notify(
        title: 'Termo de Arquivamento',
        subtitle: 'Documento não encontrado para atualizar.',
        status: NotificationStatus.error,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: contractId,
        collectionName: 'arquivamento',
        updatedByUid: user?.uid ?? '',
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação do Termo de Arquivamento atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'arquivamento_approval_updated',
          'taId': taId,
          'contractId': contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Termo de Arquivamento',
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
      child: BlocListener<TermoArquivamentoCubit, TermoArquivamentoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.taId != curr.taId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.taId;
          final needsHydrate = !_hydrated || _currentTaId != incomingId;

          if (needsHydrate) {
            final data = TermoArquivamentoData.fromSectionsMap(
              state.sectionsData,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentTaId = incomingId;
            });
          }

          final contractId = _contractId;

          if ((incomingId ?? '').isNotEmpty && contractId.isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: contractId,
              collectionName: 'arquivamento',
            );

            if ((_contract.id ?? '') != contractId) {
              unawaited(_loadContract(contractId));
              unawaited(_loadDfdData(contractId));
            }
          }
        },
        child: BlocBuilder<TermoArquivamentoCubit, TermoArquivamentoState>(
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
                stageKey: HiringStageKey.arquivamento,
                child: Scaffold(
                  body: Stack(
                    children: [
                      const BackgroundChange(),
                      SingleChildScrollView(
                        key: const PageStorageKey('termo-arquivamento-scroll'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionMetadadosTA(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionMotivoAbrangenciaTA(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionFundamentacaoTA(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionPecasAnexasTA(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionDecisaoAutoridadeTA(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionReaberturaTA(
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
                    builder: (context, progressState) {
                      return StageProgress(
                        title: 'Termo de Arquivamento',
                        icon: Icons.archive_outlined,
                        busy: state.saving || progressState.loading,
                        approved: progressState.approved,
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