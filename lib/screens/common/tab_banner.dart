// lib/_widgets/tabs/tab_banner.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';

import 'package:sipged/_widgets/images/mini_avatars/mini_avatars.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/screens/common/search/search_user_permission_widget.dart';

import 'package:sipged/_widgets/stamp/stamp.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class TabBanner extends StatefulWidget {
  const TabBanner({
    super.key,
    required this.contract,
    this.publicacaoExtratoData,
    this.dfdData,
    this.onTap,
    this.interactive = true,
    this.userData,
    this.contractsCubit,
    this.showStamp = false,
    this.stampApproved = false,
    this.stampScaleFactor = 1.0,
    this.stampApprovedLabel = 'Aprovado',
    this.stampPendingLabel = 'Pendente',
    this.stampApprovedIcon = Icons.verified_outlined,
    this.stampPendingIcon = Icons.verified_user_outlined,
    this.stampApprovedColor,
    this.stampPendingColor,
    this.titleText,
    this.contractNumberText,
  });

  final ContractData contract;

  final PublicacaoExtratoData? publicacaoExtratoData;
  final DfdData? dfdData;

  final String? titleText;
  final String? contractNumberText;

  final VoidCallback? onTap;
  final bool interactive;
  final UserData? userData;
  final ContractCubit? contractsCubit;

  final bool showStamp;
  final bool stampApproved;
  final double stampScaleFactor;
  final String stampApprovedLabel;
  final String stampPendingLabel;
  final IconData stampApprovedIcon;
  final IconData stampPendingIcon;
  final Color? stampApprovedColor;
  final Color? stampPendingColor;

  @override
  State<TabBanner> createState() => _TabBannerState();
}

class _TabBannerState extends State<TabBanner> {
  late ContractData _contractData;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contract;
  }

  @override
  void didUpdateWidget(covariant TabBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.contract.id != widget.contract.id ||
        oldWidget.contract != widget.contract) {
      _contractData = widget.contract;
    }
  }

  UserData? _currentUser() {
    final userState = context.read<UserCubit>().state;

    return widget.userData ?? userState.current;
  }

  UserPermissionData? _currentPermissionData() {
    final user = _currentUser();

    if (user == null) {
      return null;
    }

    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty) {
      return null;
    }

    final permissionState = context.read<PermissionCubit>().state;
    final currentPermissions = permissionState.current;

    if (currentPermissions == null) {
      return null;
    }

    if (currentPermissions.uid.trim() != uid) {
      return null;
    }

    return currentPermissions;
  }

  String? _activeTenantId() {
    return context.read<PermissionCubit>().state.activeTenantId?.trim();
  }

  bool _can(String action, {ContractData? c}) {
    final permissionData = _currentPermissionData();

    if (permissionData == null) {
      return false;
    }

    return SystemPermission.canContract(
      permissions: permissionData,
      contract: c ?? _contractData,
      action: action,
      tenantId: _activeTenantId(),
    );
  }

  List<String> _participantIdsOf(ContractData contract) {
    final ids = contract.participantsInfo.keys
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();

    ids.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ids;
  }

  Map<String, bool> _participantPermsOf({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return SystemPermission.emptyDocPerms();
    }

    final info = contract.participantsInfo[cleanUid];

    if (info == null) {
      return SystemPermission.emptyDocPerms();
    }

    return SystemPermission.normalizeDocPerms(
      info['permissions'],
    );
  }

  String _participantRoleOf({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return SystemRoleCodec.serialize(PermissionUser.leitor);
    }

    final info = contract.participantsInfo[cleanUid];

    final storedRole = info?['role']?.toString().trim();

    if (storedRole == null || storedRole.isEmpty) {
      return SystemRoleCodec.serialize(PermissionUser.leitor);
    }

    final parsedRole = SystemRoleCodec.parseOrDefault(
      storedRole,
      fallback: PermissionUser.leitor,
    );

    return SystemRoleCodec.serialize(parsedRole);
  }

  String _normalizeForCompare(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('nº', '')
        .replaceAll('n°', '')
        .replaceAll('n.', '')
        .replaceAll('n', '')
        .replaceAll('contrato', '')
        .replaceAll('processo', '')
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('—', '')
        .replaceAll('/', '')
        .replaceAll('.', '')
        .replaceAll('_', '')
        .trim();
  }

  bool _isDatabaseIdText(String? value) {
    final raw = value?.trim();
    final id = _contractData.id?.trim();

    if (raw == null || raw.isEmpty) return false;
    if (id == null || id.isEmpty) return false;

    if (raw == id) return true;

    final normalizedValue = _normalizeForCompare(raw);
    final normalizedId = _normalizeForCompare(id);

    if (normalizedValue.isEmpty || normalizedId.isEmpty) return false;

    return normalizedValue == normalizedId;
  }

  bool _isProbablyFirestoreId(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) return false;

    if (clean.length < 16) return false;
    if (clean.contains('/')) return false;
    if (clean.contains('.')) return false;
    if (clean.contains(' ')) return false;

    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean);
  }

  String _cleanText(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) return '';

    if (_isDatabaseIdText(clean)) return '';

    if (_isProbablyFirestoreId(clean)) return '';

    return clean;
  }

  String _removeLeadingContractLabel(String value) {
    return value
        .replaceFirst(
      RegExp(
        r'^contrato\s*(n[º°.]?)?\s*[:\-—]?\s*',
        caseSensitive: false,
      ),
      '',
    )
        .trim();
  }

  String _removeLeadingProcessLabel(String value) {
    return value
        .replaceFirst(
      RegExp(
        r'^processo\s*(n[º°.]?)?\s*[:\-—]?\s*',
        caseSensitive: false,
      ),
      '',
    )
        .trim();
  }

  String _resolveNumberText() {
    final customNumber = _cleanText(widget.contractNumberText);

    if (customNumber.isNotEmpty) {
      return customNumber;
    }

    final numeroContrato = _cleanText(
      widget.publicacaoExtratoData?.numeroContrato,
    );

    if (numeroContrato.isNotEmpty) {
      final clean = _removeLeadingContractLabel(numeroContrato);

      if (clean.isNotEmpty &&
          !_isDatabaseIdText(clean) &&
          !_isProbablyFirestoreId(clean)) {
        return 'CONTRATO Nº $clean';
      }
    }

    final processoPublicacao = _cleanText(
      widget.publicacaoExtratoData?.processo,
    );

    if (processoPublicacao.isNotEmpty) {
      final clean = _removeLeadingProcessLabel(processoPublicacao);

      if (clean.isNotEmpty &&
          !_isDatabaseIdText(clean) &&
          !_isProbablyFirestoreId(clean)) {
        return 'Processo nº $clean';
      }
    }

    final processoDfd = _cleanText(
      widget.dfdData?.processoAdministrativo,
    );

    if (processoDfd.isNotEmpty) {
      final clean = _removeLeadingProcessLabel(processoDfd);

      if (clean.isNotEmpty &&
          !_isDatabaseIdText(clean) &&
          !_isProbablyFirestoreId(clean)) {
        return 'Processo nº $clean';
      }
    }

    return '';
  }

  String _resolveDescricaoObjetoText() {
    return _cleanText(widget.dfdData?.descricaoObjeto);
  }

  String _composeTitle() {
    final numberText = _resolveNumberText();
    final descricaoObjeto = _resolveDescricaoObjetoText();

    if (numberText.isEmpty && descricaoObjeto.isEmpty) return '';
    if (numberText.isEmpty) return descricaoObjeto;
    if (descricaoObjeto.isEmpty) return numberText;

    return '$numberText — $descricaoObjeto';
  }

  Map<String, bool> _initialParticipantPerms() {
    return SystemPermission.initialDocPerms();
  }

  Map<String, dynamic> _initialParticipantMeta({
    required UserData user,
  }) {
    final name = user.name?.trim();
    final surname = user.surname?.trim();
    final email = user.email?.trim();
    final photoUrl = user.urlPhoto?.trim();

    final fullName = <String>[
      if (name != null && name.isNotEmpty) name,
      if (surname != null && surname.isNotEmpty) surname,
    ].join(' ').trim();

    return <String, dynamic>{
      'role': SystemRoleCodec.serialize(PermissionUser.colaborador),
      'active': true,
      'permissions': _initialParticipantPerms(),
      if (name != null && name.isNotEmpty) 'name': name,
      if (surname != null && surname.isNotEmpty) 'surname': surname,
      if (fullName.isNotEmpty) 'displayName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    };
  }

  Future<void> _openParticipantsDialogFromBanner(
      BuildContext context,
      ContractData contrato,
      ) async {
    final ContractCubit contractCubit =
        widget.contractsCubit ?? context.read<ContractCubit>();

    final userState = context.read<UserCubit>().state;
    final mediaQuery = MediaQuery.of(context);

    if (!_can('read', c: contrato)) return;

    final bool canEditParticipants = _can('edit', c: contrato);
    final List<UserData> users = userState.all;

    final double screenW = mediaQuery.size.width;
    final double dialogW = math.min(screenW - 64, 760.0);

    await showWindowDialog<void>(
      contentPadding: EdgeInsets.zero,
      context: context,
      title: 'Participantes do contrato',
      width: dialogW,
      child: SearchUserPermissionWidget(
        title: 'Participantes do contrato',
        allUsers: users,
        initialUserIds: _participantIdsOf(_contractData),
        enabled: canEditParticipants,
        width: dialogW,
        multiple: true,
        participantsMode: true,
        labelFor: (uid) => userState.labelFor(uid),
        getRole: (uid) {
          return _participantRoleOf(
            contract: _contractData,
            uid: uid,
          );
        },
        getPerms: (uid) {
          return _participantPermsOf(
            contract: _contractData,
            uid: uid,
          );
        },
        roleOptions: <String>[
          SystemRoleCodec.serialize(PermissionUser.gestorRegional),
          SystemRoleCodec.serialize(PermissionUser.fiscal),
          SystemRoleCodec.serialize(PermissionUser.colaborador),
          SystemRoleCodec.serialize(PermissionUser.leitor),
        ],
        onUserAdded: canEditParticipants
            ? (uid, user) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          await contractCubit.addParticipant(
            contractId: contractId,
            userId: uid,
            permMap: _initialParticipantPerms(),
            meta: _initialParticipantMeta(user: user),
          );

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
        onChanged: canEditParticipants
            ? (uids) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          final selectedIds = uids
              .map((uid) => uid.trim())
              .where((uid) => uid.isNotEmpty)
              .toSet();

          final currentIds = _participantIdsOf(_contractData);

          for (final uid in currentIds) {
            if (!selectedIds.contains(uid)) {
              await contractCubit.removeParticipant(
                contractId: contractId,
                userId: uid,
              );
            }
          }

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
        onTogglePerm: canEditParticipants
            ? (uid, permKey, value) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          final parsedAction = PermissionActionCodec.tryParse(permKey);

          if (parsedAction == null) return;

          await contractCubit.updateContractPermissions(
            contractId: contractId,
            userId: uid,
            permissionType: PermissionActionCodec.serialize(parsedAction),
            value: value,
          );

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
        onSetPerms: canEditParticipants
            ? (uid, newPerms) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          await contractCubit.setParticipantPerms(
            contractId: contractId,
            userId: uid,
            permsMap: SystemPermission.normalizeDocPerms(newPerms),
          );

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
        onChangeRole: canEditParticipants
            ? (uid, newRole) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          final parsedRole = SystemRoleCodec.parseOrDefault(
            newRole,
            fallback: PermissionUser.leitor,
          );

          await contractCubit.setParticipantRole(
            contractId: contractId,
            userId: uid,
            role: SystemRoleCodec.serialize(parsedRole),
          );

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
        onRemove: canEditParticipants
            ? (uid) async {
          final contractId = _contractData.id?.trim();

          if (contractId == null || contractId.isEmpty) return;

          await contractCubit.removeParticipant(
            contractId: contractId,
            userId: uid,
          );

          if (!mounted) return;

          await _refreshLocalContract(_contractData);
        }
            : null,
      ),
    );
  }

  Future<void> _refreshLocalContract(ContractData contrato) async {
    final cubit = widget.contractsCubit ?? context.read<ContractCubit>();

    final contractId = contrato.id?.trim();

    if (contractId == null || contractId.isEmpty) return;

    final fresh = await cubit.getById(
      contractId,
      forceServer: true,
    );

    if (fresh == null || !mounted) return;

    setState(() {
      _contractData = fresh;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contractData;
    final titleText = widget.titleText?.trim().isNotEmpty == true
        ? widget.titleText!.trim()
        : _composeTitle();

    if (titleText.isEmpty) return const SizedBox.shrink();

    if (!_can('read', c: contract)) return const SizedBox.shrink();

    final userState = context.read<UserCubit>().state;

    final ids = _participantIdsOf(contract);

    final users = ids
        .map(
          (id) => userState.byId[id] ?? UserData(uid: id),
    )
        .toList();

    final visible = users
        .where(
          (u) =>
      (u.name?.trim().isNotEmpty ?? false) ||
          (u.email?.trim().isNotEmpty ?? false),
    )
        .toList();

    final primary = visible.isNotEmpty ? visible.first : null;

    final primaryName = primary?.name?.trim().isNotEmpty == true
        ? primary!.name!
        : (primary?.email?.trim().isNotEmpty == true
        ? primary!.email!
        : (primary?.uid ?? 'usuário'));

    final others = users.length > 1 ? users.length - 1 : 0;

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isNarrow = width < 520;

    const titleStyle = TextStyle(
      color: Colors.black87,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
    );

    const metaStyle = TextStyle(
      color: Colors.black54,
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    );

    final participantsText = users.isEmpty
        ? 'nenhum participante informado'
        : others > 0
        ? 'visível para $primaryName e outras $others pessoas'
        : 'visível para $primaryName';

    final participantsRow = Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MiniAvatars(users: visible),
        Text(
          participantsText,
          style: metaStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final stampWidget = widget.showStamp
        ? Stamp(
      approved: widget.stampApproved,
      compact: isNarrow,
      dense: true,
      scaleFactor: widget.stampScaleFactor * (isNarrow ? 0.9 : 1.0),
      approvedLabel: widget.stampApprovedLabel,
      pendingLabel: widget.stampPendingLabel,
      approvedIcon: widget.stampApprovedIcon,
      pendingIcon: widget.stampPendingIcon,
      approvedColor: widget.stampApprovedColor ?? Colors.green,
      pendingColor: widget.stampPendingColor ?? Colors.grey,
    )
        : null;

    return InkWell(
      onTap: widget.onTap ??
              () async {
            if (widget.interactive) {
              await _openParticipantsDialogFromBanner(
                context,
                _contractData,
              );
            }
          },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: isMobile
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 2),
                    participantsRow,
                  ],
                ),
              )
                  : SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        titleText,
                        style: titleStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 2,
                      child: participantsRow,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.showStamp) ...[
              const SizedBox(width: 12),
              Align(
                alignment: Alignment.centerRight,
                child: stampWidget,
              ),
            ],
          ],
        ),
      ),
    );
  }
}