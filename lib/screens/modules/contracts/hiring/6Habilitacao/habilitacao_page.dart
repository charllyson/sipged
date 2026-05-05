// lib/screens/modules/contracts/hiring/6Habilitacao/habilitacao_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/progress_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/pipeline_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_state.dart';

import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/menu/tab/stage_gate.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_1_metadados.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_2_empresa.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_3_certidoes.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_4_juridica_tecnica.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_5_licitacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/6Habilitacao/section_6_consolidacao.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

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

  static const String _notificationSource = 'contracts_hiring_habilitacao';
  static const String _route = 'contracts_hiring_habilitacao';

  final DfdRepository _dfdRepository = DfdRepository();

  late final ProgressCubit _progressBloc;

  HabilitacaoData _formData = const HabilitacaoData.empty();
  ProcessData _contract = ProcessData.empty();
  DfdData? _dfdData;

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentHabId;

  final ScrollController _scrollController = ScrollController();

  bool get _isEditable => !widget.readOnly;

  String get _contractId => widget.contractId.trim();

  ProcessData get _effectiveContract {
    if ((_contract.id ?? '').trim().isNotEmpty) return _contract;
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

      if (_contractId.isNotEmpty) {
        context.read<HabilitacaoCubit>().load(_contractId);
        unawaited(_loadContract(_contractId));
        unawaited(_loadDfdData(_contractId));
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
    } catch (e, stack) {
      debugPrint('[HabilitacaoPage] Erro ao carregar contrato $cid: $e');
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
      debugPrint('[HabilitacaoPage] Falha ao carregar DFD do contrato: $e');
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

    /// Vazio = helper resolve todos os usuários com permissão ao contrato.
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
      source: 'habilitacao_notification',
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
        'source': 'habilitacao_notification',
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
        if (_dfdData?.processoAdministrativo?.trim().isNotEmpty == true)
          'processoAdministrativo': _dfdData?.processoAdministrativo,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'Habilitação',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
      );
      return false;
    }

    final cubit = context.read<HabilitacaoCubit>();

    try {
      await cubit.saveAll(
        contractId: _contractId,
        sectionsData: _formData.toSectionsMap(),
      );

      if (!mounted) return false;

      if (!cubit.state.saveSuccess) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'Habilitação',
          subtitle: 'Erro ao salvar.',
          details: err,
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
        );

        return false;
      }

      await _loadContract(_contractId);
      await _loadDfdData(_contractId);

      if (!mounted) return false;

      _progressBloc.bindToStage(
        contractId: _contractId,
        collectionName: 'habilitacao',
      );

      if (notifySuccess) {
        await _notify(
          title: 'Habilitação atualizada',
          subtitle: _notificationDemandName,
          details: 'Alterado por ${_currentActorName()}.',
          status: NotificationStatus.success,
          saveInBell: true,
          sendPush: true,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'habilitacao_saved',
            'habilitacaoId': cubit.state.habId,
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
        title: 'Habilitação',
        subtitle: 'Erro ao salvar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final habCubit = context.read<HabilitacaoCubit>();
    final pipeline = context.read<PipelineCubit>();
    final controller = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final habId = habCubit.state.habId;

    if (habId == null || habId.isEmpty) {
      await _notify(
        title: 'Habilitação',
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
        collectionName: 'habilitacao',
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: _contractId,
        collectionName: 'habilitacao',
        completed: true,
      );

      if (!mounted) return;

      pipeline.setStageEnabled(HiringStageKey.dotacao, true);
      unawaited(pipeline.refresh());

      controller.animateTo(
        (controller.index + 1).clamp(0, controller.length - 1),
      );

      await _notify(
        title: 'Habilitação aprovada',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'habilitacao_approved',
          'habilitacaoId': habId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': 'dotacao',
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Habilitação',
        subtitle: 'Erro ao aprovar.',
        details: '$e',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _updateApproved() async {
    final habCubit = context.read<HabilitacaoCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) return;

    final habId = habCubit.state.habId;

    if (habId == null || habId.isEmpty) {
      await _notify(
        title: 'Habilitação',
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
        collectionName: 'habilitacao',
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) return;

      await _notify(
        title: 'Aprovação da Habilitação atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'habilitacao_approval_updated',
          'habilitacaoId': habId,
          'contractId': _contractId,
          'route': _route,
          'notificationSource': _notificationSource,
        },
      );
    } catch (e) {
      if (!mounted) return;

      await _notify(
        title: 'Habilitação',
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
      child: BlocListener<HabilitacaoCubit, HabilitacaoState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) || prev.habId != curr.habId;
        },
        listener: (context, state) {
          if (!mounted || state.loading || !state.hasValidPath) return;

          final incomingId = state.habId;
          final needsHydrate = !_hydrated || _currentHabId != incomingId;

          if (needsHydrate) {
            final data = HabilitacaoData.fromSectionsMap(state.sectionsData);

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentHabId = incomingId;
            });
          }

          if ((incomingId ?? '').isNotEmpty) {
            _progressBloc.bindToStage(
              contractId: _contractId,
              collectionName: 'habilitacao',
            );

            if ((_contract.id ?? '') != _contractId) {
              unawaited(_loadContract(_contractId));
              unawaited(_loadDfdData(_contractId));
            }
          }
        },
        child: BlocBuilder<HabilitacaoCubit, HabilitacaoState>(
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
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionEmpresa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionCertidoes(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionJuridicaTecnica(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionLicitation(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                            const SizedBox(height: 12),
                            SectionConsolidation(
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
                        title: 'Habilitação / Regularidade',
                        icon: Icons.verified_user_outlined,
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