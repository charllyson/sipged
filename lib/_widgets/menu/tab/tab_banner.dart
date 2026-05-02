import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/mini_avatars/mini_avatars.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/list/search/search_user_permission_widget.dart';

import 'package:sipged/_blocs/system/module/module_permission.dart' as perms;
import 'package:sipged/_blocs/system/user/user_permission.dart' as roles;
import 'package:sipged/_blocs/modules/contracts/_process/contract_permission.dart'
as acl;

import 'package:sipged/_widgets/stamp/stamp.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class TabBanner extends StatefulWidget {
  const TabBanner({
    super.key,
    required this.contract,
    this.titleText,
    this.contractNumberText,
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
  });

  final ProcessData contract;

  /// Texto principal do banner.
  ///
  /// Exemplo:
  /// Recuperação funcional da rodovia AL-101
  final String? titleText;

  /// Texto exibido antes do resumo.
  ///
  /// Exemplo:
  /// Contrato nº 012/2026
  /// Processo nº E:05500.000000/2026
  final String? contractNumberText;

  final VoidCallback? onTap;
  final bool interactive;
  final UserData? userData;
  final ProcessCubit? contractsCubit;

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
  late ProcessData _contractData;

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
    final st = context.read<UserCubit>().state;
    return widget.userData ?? st.current;
  }

  bool _can(String action, {ProcessData? c}) {
    final u = _currentUser();
    if (u == null) return false;

    return acl.ContractPermissions.can(
      user: u,
      contract: c ?? _contractData,
      action: action,
    );
  }

  String _composeTitle({
    required String number,
    required String title,
  }) {
    final cleanNumber = number.trim();
    final cleanTitle = title.trim();

    if (cleanNumber.isEmpty && cleanTitle.isEmpty) return '';
    if (cleanNumber.isEmpty) return cleanTitle;
    if (cleanTitle.isEmpty) return cleanNumber;

    return '$cleanNumber — $cleanTitle';
  }

  Future<void> _openParticipantsDialogFromBanner(
      BuildContext context,
      ProcessData contrato,
      ) async {
    final ProcessCubit contractCubit =
        widget.contractsCubit ?? context.read<ProcessCubit>();
    final userState = context.read<UserCubit>().state;
    final mediaQuery = MediaQuery.of(context);

    if (!_can('read', c: contrato)) return;

    final bool canEditParticipants = _can('edit', c: contrato);
    final List<UserData> users = userState.all;

    final double screenW = mediaQuery.size.width;
    final double dialogW = math.min(screenW - 64, 760.0);

    await showWindowDialog<void>(
      context: context,
      title: 'Participantes do contrato',
      width: dialogW,
      child: SearchUserPermissionWidget(
        title: 'Participantes do contrato',
        allUsers: users,
        initialUserIds: contrato.permissionContractId.keys.toList(),
        enabled: canEditParticipants,
        width: dialogW,
        multiple: true,
        participantsMode: true,
        labelFor: (uid) => userState.labelFor(uid),
        getRole: (uid) {
          final u = userState.byId[uid];
          final base =
          (u != null) ? roles.roleForUser(u) : roles.UserProfile.leitor;

          return roles.UserRoleCodec.label(base);
        },
        getPerms: (uid) {
          final raw = contrato.permissionContractId[uid];
          return perms.normalizePermMap(raw);
        },
        roleOptions: const [],
        onChangeRole: null,
        onChanged: canEditParticipants
            ? (uids) async {
          if (contrato.id == null) return;

          final atuais = Map<String, Map<String, bool>>.from(
            contrato.permissionContractId,
          );

          for (final uid in atuais.keys.toList()) {
            if (!uids.contains(uid)) {
              await contractCubit.removeParticipant(
                contractId: contrato.id!,
                userId: uid,
              );
            }
          }

          for (final uid in uids) {
            if (!atuais.containsKey(uid)) {
              final initialPerms = perms.initialDocPerms();

              await contractCubit.addParticipant(
                contractId: contrato.id!,
                userId: uid,
                permMap: initialPerms,
                meta: const {},
              );
            }
          }

          if (!mounted) return;
          await _refreshLocalContract(contrato);
        }
            : null,
      ),
    );
  }

  Future<void> _refreshLocalContract(ProcessData contrato) async {
    final cubit = widget.contractsCubit ?? context.read<ProcessCubit>();
    if (contrato.id == null) return;

    final fresh = await cubit.getById(contrato.id!);
    if (fresh == null || !mounted) return;

    setState(() => _contractData = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contractData;

    final titleText = _composeTitle(
      number: widget.contractNumberText ?? '',
      title: widget.titleText ?? '',
    );

    if (titleText.isEmpty) return const SizedBox.shrink();

    if (!_can('read', c: contract)) return const SizedBox.shrink();

    final userState = context.read<UserCubit>().state;

    final ids = contract.permissionContractId.keys.toList();

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

    final others = (users.length > 1) ? users.length - 1 : 0;

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

    final participantsRow = Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MiniAvatars(users: visible),
        Text(
          others > 0
              ? 'visível para $primaryName e outras $others pessoas'
              : 'visível só para você',
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
              await _openParticipantsDialogFromBanner(context, _contractData);
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