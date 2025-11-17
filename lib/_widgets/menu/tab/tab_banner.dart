// lib/_widgets/menu/tab/tab_banner.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/images/mini_avatars/mini_avatars.dart';

import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_store.dart';

import 'package:siged/_widgets/list/search/search_user_permission_widget.dart';

// permissões globais & por documento
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;

// selo reutilizável
import 'package:siged/_widgets/stamp/stamp.dart';

class TabBanner extends StatefulWidget {
  const TabBanner({
    super.key,
    required this.contract,
    this.titleText, // 🔹 agora opcional
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

  /// Contrato continua sendo o modelo principal
  final ProcessData contract;

  /// Texto pronto para exibir no banner (ex.: "123/2024 – Objeto X")
  /// Se for null ou vazio, o banner não aparece.
  final String? titleText;

  final VoidCallback? onTap;
  final bool interactive;
  final UserData? userData;
  final ProcessBloc? contractsBloc;

  // Selo
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

  bool _can(String action, {ProcessData? c}) {
    final userState = context.read<UserBloc>().state;
    final currentUser = widget.userData ?? userState.current;
    final contract = c ?? _contractData;
    if (currentUser == null || contract == null) return false;
    return perms.userCanOnContract(
      user: currentUser,
      contract: contract,
      action: action,
    );
  }

  Future<void> _openParticipantsDialogFromBanner(
      BuildContext context,
      ProcessData contrato,
      ) async {
    final contractBloc = widget.contractsBloc ?? context.read<ProcessBloc>();
    final userState = context.read<UserBloc>().state;
    final canEditParticipants = _can('edit', c: contrato);
    final users = userState.all;

    final screenW = MediaQuery.of(context).size.width;
    final dialogW = math.min(screenW - 64, 760.0);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            return AlertDialog(
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              content: SizedBox(
                width: dialogW,
                child: SearchUserPermissionWidget(
                  title: 'Participantes do contrato',
                  allUsers: users,
                  initialUserIds:
                  contrato.permissionContractId.keys.toList(),
                  enabled: canEditParticipants,
                  width: dialogW,
                  multiple: true,
                  participantsMode: true,
                  labelFor: (uid) => userState.labelFor(uid),
                  getRole: (uid) {
                    final st = context.read<UserBloc>().state;
                    final u = st.byId[uid];
                    final base = (u != null)
                        ? roles.roleForUser(u)
                        : roles.BaseRole.LEITOR;
                    return roles.baseRoleLabel(base);
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
                    final atuais =
                    Map<String, Map<String, bool>>.from(
                      contrato.permissionContractId,
                    );

                    // remove quem saiu
                    for (final uid in atuais.keys.toList()) {
                      if (!uids.contains(uid)) {
                        await contractBloc.removeParticipant(
                          contractId: contrato.id!,
                          userId: uid,
                        );
                        contrato.removeParticipantLocal(uid);
                      }
                    }

                    // adiciona quem entrou
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
                      rebuildDialog: () => setStateSB(() {}),
                    );
                  }
                      : null,
                ),
              ),
            );
          },
        );
      },
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
    final userState = context.read<UserBloc>().state;
    final contract = _contractData;

    // usa o texto vindo de fora, se não tiver, não mostra banner
    final titleText = widget.titleText?.trim() ?? '';
    if (titleText.isEmpty) {
      return const SizedBox.shrink();
    }

    final ids = contract.permissionContractId.keys.toList();
    final users =
    ids.map((id) => userState.byId[id] ?? UserData(uid: id)).toList();

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

    final titleStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
    );
    final metaStyle = const TextStyle(
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
            // Conteúdo principal
            Expanded(
              child: isMobile
              // MOBILE: 2 linhas
                  ? Column(
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
              )
              // DESKTOP: 1 linha, altura fixa
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
