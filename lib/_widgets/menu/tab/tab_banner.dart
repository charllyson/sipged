import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/images/mini_avatars/mini_avatars.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_store.dart';

import 'package:siged/_widgets/list/search/search_user_permission_widget.dart';

// RBAC (módulo)
import 'package:siged/_blocs/system/permitions/module_permission.dart' as perms;
// perfis
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
// ✅ ACL do contrato
import 'package:siged/_blocs/system/permitions/contract_permission.dart' as acl;

import 'package:siged/_widgets/stamp/stamp.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

class TabBanner extends StatefulWidget {
  const TabBanner({
    super.key,
    required this.contract,
    this.titleText,
    this.onTap,
    this.interactive = true,
    this.userData,
    this.contractsBloc,
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
  final String? titleText;

  final VoidCallback? onTap;
  final bool interactive;
  final UserData? userData;
  final ProcessBloc? contractsBloc;

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
    if (oldWidget.contract.id != widget.contract.id) {
      _contractData = widget.contract;
    }
  }

  UserData? _currentUser() {
    final st = context.read<UserBloc>().state;
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

  Future<void> _openParticipantsDialogFromBanner(
      BuildContext context,
      ProcessData contrato,
      ) async {
    final contractBloc = widget.contractsBloc ?? context.read<ProcessBloc>();
    final userState = context.read<UserBloc>().state;

    // precisa pelo menos conseguir ler o contrato
    if (!_can('read', c: contrato)) return;

    final canEditParticipants = _can('edit', c: contrato);
    final users = userState.all;

    final screenW = MediaQuery.of(context).size.width;
    final dialogW = math.min(screenW - 64, 760.0);

    await showWindowDialogMac<void>(
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
          final st = context.read<UserBloc>().state;
          final u = st.byId[uid];
          final base = (u != null) ? roles.roleForUser(u) : roles.UserProfile.LEITOR;
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
              await contractBloc.removeParticipant(
                contractId: contrato.id!,
                userId: uid,
              );
              contrato.removeParticipantLocal(uid);
            }
          }

          for (final uid in uids) {
            if (!atuais.containsKey(uid)) {
              final initialPerms = perms.initialDocPerms();
              await contractBloc.addParticipant(
                contractId: contrato.id!,
                userId: uid,
                permMap: initialPerms,
                meta: const {},
              );

              contrato.upsertParticipantLocal(
                uid,
                read: initialPerms['read']!,
                edit: initialPerms['edit']!,
                delete: initialPerms['delete']!,
                meta: const {},
              );
            }
          }

          await context.read<ProcessStore>().refresh();
          await _refreshLocalContract(
            contrato,
            rebuildDialog: () => setState(() {}),
          );
        }
            : null,
      ),
    );
  }

  Future<void> _refreshLocalContract(
      ProcessData contrato, {
        VoidCallback? rebuildDialog,
      }) async {
    final bloc = widget.contractsBloc ?? context.read<ProcessBloc>();
    if (contrato.id == null) return;

    final fresh = await bloc.getContractById(contrato.id!);
    if (fresh == null || !mounted) return;

    setState(() => _contractData = fresh);
    rebuildDialog?.call();
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contractData;
    final titleText = widget.titleText?.trim() ?? '';
    if (titleText.isEmpty) return const SizedBox.shrink();

    // ✅ se não pode ler, não mostra banner
    if (!_can('read', c: contract)) return const SizedBox.shrink();

    final userState = context.read<UserBloc>().state;

    final ids = contract.permissionContractId.keys.toList();
    final users = ids.map((id) => userState.byId[id] ?? UserData(uid: id)).toList();

    final visible = users
        .where((u) =>
    (u.name?.trim().isNotEmpty ?? false) ||
        (u.email?.trim().isNotEmpty ?? false))
        .toList();

    final primary = visible.isNotEmpty ? visible.first : null;
    final primaryName = primary?.name?.trim().isNotEmpty == true
        ? primary!.name!
        : (primary?.email?.trim().isNotEmpty == true
        ? primary!.email!
        : (primary?.uid ?? 'usuário'));

    final others = (users.length > 1) ? users.length - 1 : 0;

    final isMobile = MediaQuery.of(context).size.width < 720;
    final isNarrow = MediaQuery.of(context).size.width < 520;

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
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titleText, textAlign: TextAlign.center, style: titleStyle),
                  const SizedBox(height: 2),
                  participantsRow,
                ],
              )
                  : SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        titleText,
                        style: titleStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(child: participantsRow),
                  ],
                ),
              ),
            ),
            if (widget.showStamp) ...[
              const SizedBox(width: 12),
              Align(alignment: Alignment.centerRight, child: stampWidget),
            ],
          ],
        ),
      ),
    );
  }
}
