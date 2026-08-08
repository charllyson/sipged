// lib/screens/modules/contracts/hiring/1Dfd/dfd_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Progress/progress_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_hiring.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/tab/stage_progress.dart';
import 'package:sipged/_widgets/overlays/screen_lock.dart';

import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_1_identificacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_2_objeto.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_3_localizacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_4_estimativa.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_5_riscos.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_6_documentos.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_7_aprovacao.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/section_8_observacoes.dart';

class DfdPage extends StatefulWidget {
  const DfdPage({
    super.key,
    required this.contractId,
    this.readOnly = false,
  });

  final String contractId;
  final bool readOnly;

  @override
  State<DfdPage> createState() => _DfdPageState();
}

class _DfdPageState extends State<DfdPage>
    with SipGedValidation, AutomaticKeepAliveClientMixin {
  static const String _notificationSource = 'contracts_hiring_dfd';
  static const String _route = 'contracts_hiring_dfd';

  late final ProgressCubit _progressBloc;

  ProgressCubit? _pipelineProgressCubit;

  DfdData _formData = const DfdData.empty();
  ContractData _contract = ContractData.empty();

  bool _hydrated = false;
  bool _loadingContract = false;

  String? _currentDfdId;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  bool get _isEditable => !widget.readOnly;

  String get _tenantId {
    return context.read<DfdCubit>().tenantId.trim();
  }

  String get _stateOrWidgetContractId {
    final stateId = context.read<DfdCubit>().state.contractId?.trim();

    if (stateId != null && stateId.isNotEmpty) {
      return stateId;
    }

    return widget.contractId.trim();
  }

  ContractData get _effectiveContract {
    final effectiveId = _stateOrWidgetContractId;

    if ((_contract.id ?? '').trim().isNotEmpty) {
      return _contract;
    }

    if (effectiveId.isNotEmpty) {
      return _contract.copyWith(id: effectiveId);
    }

    return _contract;
  }

  String get _notificationDemandName {
    final descricaoObjeto = _formData.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    final contractId = _stateOrWidgetContractId;
    final displaySummary = _contract.displaySummary.trim();

    if (displaySummary.isNotEmpty &&
        displaySummary != 'Contrato $contractId' &&
        !displaySummary.startsWith('Contrato ')) {
      return displaySummary;
    }

    return 'Demanda sem identificação';
  }

  String get _processNumber {
    final processoAdministrativo = _formData.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _stateOrWidgetContractId;
  }

  @override
  void initState() {
    super.initState();

    final dfdCubit = context.read<DfdCubit>();

    _progressBloc = ProgressCubit(
      repo: ProgressRepository(
        tenantId: dfdCubit.tenantId,
      ),
    );

    final contractId = widget.contractId.trim();

    if (contractId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<DfdCubit>().load(contractId);
        unawaited(_loadContract(contractId));
        unawaited(
          _progressBloc.bindToStage(
            contractId: contractId,
            collectionName: ProgressRepository.stageDfd,
          ),
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_pipelineProgressCubit != null) {
      return;
    }

    try {
      _pipelineProgressCubit = context.read<ProgressCubit>();
    } catch (_) {
      _pipelineProgressCubit = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    unawaited(_progressBloc.close());

    super.dispose();
  }

  Future<void> _loadContract(String contractId) async {
    final cid = contractId.trim();
    final tenantId = _tenantId;

    if (cid.isEmpty) {
      return;
    }

    if (tenantId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _contract = ContractData.empty().copyWith(id: cid);
        _loadingContract = false;
      });

      debugPrint(
        '[DfdPage] tenantId vazio ao carregar contrato $cid.',
      );

      return;
    }

    if (mounted) {
      setState(() {
        _loadingContract = true;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection('contracts')
          .doc(cid)
          .get();

      if (!mounted) {
        return;
      }

      if (snapshot.exists) {
        setState(() {
          _contract = ContractData.fromDocument(snapshot: snapshot);
          _loadingContract = false;
        });
      } else {
        setState(() {
          _contract = ContractData.empty().copyWith(id: cid);
          _loadingContract = false;
        });
      }
    } catch (error, stack) {
      debugPrint(
        '[DfdPage] Erro ao carregar contrato | '
            'tenantId=$tenantId | '
            'contractId=$cid | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      if (!mounted) {
        return;
      }

      setState(() {
        _contract = ContractData.empty().copyWith(id: cid);
        _loadingContract = false;
      });
    }
  }

  String _currentActorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }

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
          if (photo.isNotEmpty) {
            return photo;
          }
        }
      }
    }

    final firebasePhoto = user?.photoURL?.trim() ?? '';
    if (firebasePhoto.isNotEmpty) {
      return firebasePhoto;
    }

    return '';
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,
    NotificationStatus? type,
    Duration duration = const Duration(seconds: 4),
    bool local = true,
    bool bell = false,
    bool push = false,
    bool email = false,
    bool sms = false,
    Iterable<String> targetUserIds = const <String>[],
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final actorId = user?.uid.trim();
    final actorName = _currentActorName();
    final actorPhotoUrl = _currentActorPhotoUrl();

    final effectiveContract = _effectiveContract;
    final effectiveContractId =
    (effectiveContract.id ?? _stateOrWidgetContractId).trim();

    final demandName = _notificationDemandName;

    final channels = <NotificationChannel>{
      if (local) NotificationChannel.local,
      if (bell) NotificationChannel.bell,
      if (push) NotificationChannel.push,
      if (email) NotificationChannel.email,
      if (sms) NotificationChannel.sms,
    };

    if (channels.isEmpty) {
      return;
    }

    await NotificationHiring.show(
      context: context,
      contract: effectiveContract,
      title: title,
      subtitle: subtitle,
      details: details,
      module: _route,
      notificationSource: _notificationSource,
      source: 'dfd_notification',
      status: type ?? status,
      duration: duration,
      delivery: NotificationDelivery.localBellAndPush,
      sendPush: channels.contains(NotificationChannel.push),
      targetUserIds: targetUserIds,
      actorId: actorId,
      actorName: actorName,
      extra: <String, dynamic>{
        ...extra,
        'route': extra['route'] ?? _route,
        'module': _route,
        'source': 'dfd_notification',
        'sourceKey': _notificationSource,
        'subSource': _notificationSource,
        'notificationSource': _notificationSource,
        'requestedChannels': channels.map((item) => item.key).toList(),
        'actorId': actorId,
        'actorName': actorName,
        if (actorPhotoUrl.isNotEmpty) 'actorPhotoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoURL': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'profilePhotoUrl': actorPhotoUrl,
        if (_tenantId.isNotEmpty) 'tenantId': _tenantId,
        if (effectiveContractId.isNotEmpty) 'contractId': effectiveContractId,
        'contractTitle': demandName,
        'contractSummary': demandName,
        'descricaoObjeto': demandName,
        'nomeDemanda': demandName,
        if (_processNumber.trim().isNotEmpty) 'contractNumber': _processNumber,
        if (_processNumber.trim().isNotEmpty) 'processNumber': _processNumber,
        if (_formData.processoAdministrativo?.trim().isNotEmpty == true)
          'processoAdministrativo': _formData.processoAdministrativo,
      },
    );
  }

  Future<bool> _saveOnly({
    bool notifySuccess = true,
  }) async {
    if (widget.readOnly) {
      await _notify(
        title: 'DFD',
        subtitle: 'Esta etapa está em modo somente leitura.',
        status: NotificationStatus.info,
        local: true,
      );

      return false;
    }

    final cubit = context.read<DfdCubit>();

    try {
      final currentIdFromState = cubit.state.contractId;
      final initialId =
      widget.contractId.trim().isNotEmpty ? widget.contractId.trim() : null;

      final finalContractId = await cubit.saveAllWithAutoContract(
        contractId: currentIdFromState ?? initialId,
        data: _formData,
      );

      if (!mounted) {
        return false;
      }

      if (!cubit.state.saveSuccess || finalContractId == null) {
        final err = cubit.state.error ?? 'Falha ao salvar';

        await _notify(
          title: 'DFD',
          subtitle: 'Erro ao salvar.',
          details: err,
          status: NotificationStatus.error,
          duration: const Duration(seconds: 6),
          local: true,
        );

        return false;
      }

      await _loadContract(finalContractId);

      if (!mounted) {
        return false;
      }

      unawaited(
        _progressBloc.bindToStage(
          contractId: finalContractId,
          collectionName: ProgressRepository.stageDfd,
        ),
      );

      if (notifySuccess) {
        await _notify(
          title: 'DFD atualizado',
          subtitle: _notificationDemandName,
          details: 'Alterado por ${_currentActorName()}.',
          status: NotificationStatus.success,
          local: true,
          bell: true,
          push: true,
          email: false,
          sms: false,
          targetUserIds: const <String>[],
          extra: <String, dynamic>{
            'action': 'dfd_saved',
            'dfdId': cubit.state.dfdId,
            'tenantId': _tenantId,
            'contractId': finalContractId,
            'route': _route,
            'notificationSource': _notificationSource,
          },
        );
      }

      return true;
    } catch (error, stack) {
      debugPrint(
        '[DfdPage] Erro em _saveOnly | '
            'tenantId=$_tenantId | '
            'contractId=${widget.contractId} | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      if (!mounted) {
        return false;
      }

      await _notify(
        title: 'DFD',
        subtitle: 'Erro ao salvar.',
        details: '$error',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        local: true,
      );

      return false;
    }
  }

  Future<void> _saveApproveAndNext() async {
    final dfdCubit = context.read<DfdCubit>();
    final tabController = DefaultTabController.of(context);
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) {
      return;
    }

    final dfdState = dfdCubit.state;
    final dfdId = dfdState.dfdId;
    final contractIdForApprove = dfdState.contractId?.trim().isNotEmpty == true
        ? dfdState.contractId!.trim()
        : widget.contractId.trim();

    if ((dfdId ?? '').isEmpty || contractIdForApprove.isEmpty) {
      await _notify(
        title: 'DFD',
        subtitle: 'Documento não encontrado para aprovar.',
        status: NotificationStatus.error,
        local: true,
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.approveStage(
        contractId: contractIdForApprove,
        collectionName: ProgressRepository.stageDfd,
        approverUid: uid,
        approverName: actorName,
      );

      await repo.setCompleted(
        contractId: contractIdForApprove,
        collectionName: ProgressRepository.stageDfd,
        responsibleUserId: _formData.solicitanteUserId,
        approverUserId: _formData.autoridadeUserId,
        responsibleName: _formData.solicitanteNome,
        approverName: _formData.autoridadeAprovadora,
        completed: true,
      );

      if (!mounted) {
        return;
      }

      unawaited(
        _progressBloc.bindToStage(
          contractId: contractIdForApprove,
          collectionName: ProgressRepository.stageDfd,
        ),
      );

      _pipelineProgressCubit?.setStageEnabled(ProgressData.etp, true);
      unawaited(_pipelineProgressCubit?.refreshPipeline());

      tabController.animateTo(
        (tabController.index + 1).clamp(0, tabController.length - 1),
      );

      await _notify(
        title: 'DFD aprovado',
        subtitle: _notificationDemandName,
        details: 'Aprovado por $actorName.',
        status: NotificationStatus.success,
        local: true,
        bell: true,
        push: true,
        email: false,
        sms: false,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'dfd_approved',
          'dfdId': dfdId,
          'tenantId': _tenantId,
          'contractId': contractIdForApprove,
          'route': _route,
          'notificationSource': _notificationSource,
          'nextStage': ProgressData.etp,
          'responsibleUserId': _formData.solicitanteUserId,
          'approverUserId': _formData.autoridadeUserId,
        },
      );
    } catch (error, stack) {
      debugPrint(
        '[DfdPage] Erro em _saveApproveAndNext | '
            'tenantId=$_tenantId | '
            'contractId=$contractIdForApprove | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      if (!mounted) {
        return;
      }

      await _notify(
        title: 'DFD',
        subtitle: 'Erro ao aprovar.',
        details: '$error',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        local: true,
      );
    }
  }

  Future<void> _updateApproved() async {
    final dfdCubit = context.read<DfdCubit>();
    final repo = _progressBloc.repo;

    final saved = await _saveOnly(
      notifySuccess: false,
    );

    if (!mounted || !saved) {
      return;
    }

    final dfdState = dfdCubit.state;
    final dfdId = dfdState.dfdId;
    final contractIdForApprove = dfdState.contractId?.trim().isNotEmpty == true
        ? dfdState.contractId!.trim()
        : widget.contractId.trim();

    if ((dfdId ?? '').isEmpty || contractIdForApprove.isEmpty) {
      await _notify(
        title: 'DFD',
        subtitle: 'Documento não encontrado para atualizar.',
        status: NotificationStatus.error,
        local: true,
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final actorName = _currentActorName();

    try {
      await repo.touchApproval(
        contractId: contractIdForApprove,
        collectionName: ProgressRepository.stageDfd,
        updatedByUid: uid,
        updatedByName: actorName,
      );

      if (!mounted) {
        return;
      }

      unawaited(
        _progressBloc.bindToStage(
          contractId: contractIdForApprove,
          collectionName: ProgressRepository.stageDfd,
        ),
      );

      unawaited(_pipelineProgressCubit?.refreshPipeline());

      await _notify(
        title: 'Aprovação do DFD atualizada',
        subtitle: _notificationDemandName,
        details: 'Atualizado por $actorName.',
        status: NotificationStatus.success,
        local: true,
        bell: true,
        push: true,
        email: false,
        sms: false,
        targetUserIds: const <String>[],
        extra: <String, dynamic>{
          'action': 'dfd_approval_updated',
          'dfdId': dfdId,
          'tenantId': _tenantId,
          'contractId': contractIdForApprove,
          'route': _route,
          'notificationSource': _notificationSource,
          'responsibleUserId': _formData.solicitanteUserId,
          'approverUserId': _formData.autoridadeUserId,
        },
      );
    } catch (error, stack) {
      debugPrint(
        '[DfdPage] Erro em _updateApproved | '
            'tenantId=$_tenantId | '
            'contractId=$contractIdForApprove | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      if (!mounted) {
        return;
      }

      await _notify(
        title: 'DFD',
        subtitle: 'Erro ao atualizar aprovação.',
        details: '$error',
        status: NotificationStatus.error,
        duration: const Duration(seconds: 6),
        local: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final users = context.select<UserCubit, List<UserData>>(
          (cubit) => cubit.state.all,
    );

    return BlocProvider<ProgressCubit>.value(
      value: _progressBloc,
      child: BlocListener<DfdCubit, DfdState>(
        listenWhen: (prev, curr) {
          return (prev.loading && !curr.loading) ||
              prev.dfdId != curr.dfdId ||
              prev.contractId != curr.contractId;
        },
        listener: (context, state) {
          if (!mounted) {
            return;
          }

          if (state.loading || !state.hasValidPath) {
            return;
          }

          final incomingId = state.dfdId;
          final needsHydrate = !_hydrated || _currentDfdId != incomingId;

          if (needsHydrate) {
            final data = DfdData.fromSectionsMap(
              state.sectionsData,
              contractId: state.contractId,
            );

            setState(() {
              _formData = data;
              _hydrated = true;
              _currentDfdId = incomingId;
            });
          }

          final effectiveContractId = state.contractId?.trim().isNotEmpty == true
              ? state.contractId!.trim()
              : widget.contractId.trim();

          if ((incomingId ?? '').isNotEmpty && effectiveContractId.isNotEmpty) {
            unawaited(
              _progressBloc.bindToStage(
                contractId: effectiveContractId,
                collectionName: ProgressRepository.stageDfd,
              ),
            );

            if ((_contract.id ?? '') != effectiveContractId) {
              unawaited(_loadContract(effectiveContractId));
            }
          }
        },
        child: BlocBuilder<DfdCubit, DfdState>(
          builder: (context, state) {
            final progressState = context.watch<ProgressCubit>().state;

            final locked = state.loading ||
                state.saving ||
                progressState.loading ||
                _loadingContract;

            final msg = state.loading
                ? 'Sincronizando os dados...'
                : state.saving
                ? 'Salvando os dados...'
                : progressState.loading
                ? 'Atualizando aprovação...'
                : _loadingContract
                ? 'Carregando dados do contrato...'
                : null;

            final effectiveContractId =
            state.contractId?.trim().isNotEmpty == true
                ? state.contractId!.trim()
                : widget.contractId.trim();

            return ScreenLock(
              locked: locked,
              message: msg,
              details: locked ? 'Por favor, aguarde.' : null,
              keepAppBarUndimmed: true,
              child: Scaffold(
                body: Stack(
                  children: <Widget>[
                    const BackgroundChange(),
                    SingleChildScrollView(
                      key: const PageStorageKey<String>('dfd-scroll'),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RepaintBoundary(
                            child: SectionIdentificacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionObjeto(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionLocalizacao(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionEstimativa(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionRiscos(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionDocumentos(
                              data: _formData,
                              isEditable: _isEditable,
                              contractId: effectiveContractId,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionAprovacao(
                              data: _formData,
                              users: users,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: SectionObservacoes(
                              data: _formData,
                              isEditable: _isEditable,
                              onChanged: (updated) {
                                setState(() => _formData = updated);
                              },
                            ),
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
                      busy: state.saving || pstate.loading,
                      approved: pstate.approved,
                      onSave: () => _saveOnly(),
                      onSaveAndNext: _saveApproveAndNext,
                      onUpdateApproved: _updateApproved,
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