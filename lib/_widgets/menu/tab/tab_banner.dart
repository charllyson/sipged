// lib/_widgets/menu/tab/tab_banner.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/images/mini_avatars/mini_avatars.dart';

import 'package:siged/_blocs/process/contracts/contract_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/contracts/contract_store.dart';

import 'package:siged/_widgets/list/search/search_user_permission_widget.dart';

// permissões globais & por documento
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;

/// Banner reutilizável que exibe o resumo do contrato + participantes.
/// AGORA INTERATIVO: se [interactive] = true, o próprio banner abre o diálogo
/// de participantes com checagens de permissão e sincroniza o contrato local.
/// - Usa UserBloc para resolver nomes/avatars dos UIDs em `permissionContractId`.
/// - Se não houver título (ou vier vazio), não renderiza nada.
/// - Você ainda pode passar [onTap] para sobrepor o comportamento padrão.
class TabBanner extends StatefulWidget {
  const TabBanner({
    super.key,
    required this.contract,
    this.titleBuilder,
    this.onTap,
    this.interactive = true,
    this.userData,
    this.contractsBloc,
  });

  final ContractData contract;

  /// Caso informado, define o texto do título no lugar de `summarySubjectContract`.
  final String Function(ContractData c)? titleBuilder;

  /// Callback opcional ao tocar no banner (sobrepõe o comportamento padrão).
  final VoidCallback? onTap;

  /// Se true, o banner abre o diálogo de participantes ao clicar (se onTap == null).
  final bool interactive;

  /// (Opcional) Para evitar leituras repetidas do UserBloc
  final UserData? userData;

  /// (Opcional) Injetar bloc explicitamente; senão pega do Provider.
  final ContractBloc? contractsBloc;

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

  // ======== Permissão contextual no contrato ========
  bool _can(String action, {ContractData? c}) {
    final userState = context.read<UserBloc>().state;
    final currentUser = widget.userData ?? userState.current;
    final contract = c ?? _contractData;
    if (currentUser == null || contract == null) return false;
    return perms.userCanOnContract(user: currentUser, contract: contract, action: action);
  }

  // ======== Diálogo de participantes (embutido) ========
  Future<void> _openParticipantsDialogFromBanner(
      BuildContext context,
      ContractData contrato,
      ) async {
    final contractBloc = widget.contractsBloc ?? context.read<ContractBloc>();
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              contentPadding: EdgeInsets.zero,
              titlePadding: EdgeInsets.zero,
              actionsPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              content: SizedBox(
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
                    final base = (u != null) ? roles.roleForUser(u) : roles.BaseRole.LEITOR;
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
                    final atuais = Map<String, Map<String, bool>>.from(
                      contrato.permissionContractId,
                    );

                    // Remoções
                    for (final uid in atuais.keys.toList()) {
                      if (!uids.contains(uid)) {
                        await contractBloc.removeParticipant(
                          contractId: contrato.id!,
                          userId: uid,
                        );
                        contrato.removeParticipantLocal(uid);
                      }
                    }

                    // Inclusões
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

                    await context.read<ContractsStore>().refresh();
                    await _refreshLocalContract(
                      contrato,
                      rebuildDialog: () => setStateSB(() {}),
                    );
                  }
                      : null,
                  onTogglePerm: canEditParticipants
                      ? (uid, key, val) async {
                    if (contrato.id == null) return;
                    final current = Map<String, bool>.from(
                      contrato.permissionContractId[uid] ?? const {},
                    );
                    final normalized = perms.normalizePermMap(current);
                    normalized[key] = val;

                    await contractBloc.setParticipantPerms(
                      contractId: contrato.id!,
                      userId: uid,
                      perms: normalized,
                    );

                    contrato.permissionContractId[uid] = normalized;

                    await context.read<ContractsStore>().refresh();
                    await _refreshLocalContract(
                      contrato,
                      rebuildDialog: () => setStateSB(() {}),
                    );
                  }
                      : null,
                  onRemove: canEditParticipants
                      ? (uid) async {
                    if (contrato.id == null) return;
                    await contractBloc.removeParticipant(
                      contractId: contrato.id!,
                      userId: uid,
                    );
                    contrato.removeParticipantLocal(uid);
                    await context.read<ContractsStore>().refresh();
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

  // ======== Sincroniza contrato local após mudar participantes/permissões ========
  Future<void> _refreshLocalContract(
      ContractData contrato, {
        VoidCallback? rebuildDialog,
      }) async {
    final bloc = widget.contractsBloc ?? context.read<ContractBloc>();
    if (contrato.id == null) return;

    final fresh = await bloc.getContractById(contrato.id!);
    if (fresh == null) return;

    if (!mounted) return;
    setState(() {
      contrato.permissionContractId
        ..clear()
        ..addAll(fresh.permissionContractId);
      contrato.participantsInfo
        ..clear()
        ..addAll(fresh.participantsInfo);

      _contractData = fresh;
    });

    rebuildDialog?.call();
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    final contract = _contractData;

    // Título
    final titleText = (widget.titleBuilder != null)
        ? widget.titleBuilder!(contract)
        : (contract.summarySubjectContract ?? '');

    if ((titleText.trim()).isEmpty) {
      return const SizedBox.shrink();
    }

    // Participantes visíveis
    final ids = contract.permissionContractId.keys.toList();
    final users = ids.map((id) => userState.byId[id] ?? UserData(id: id)).toList();

    final visible = users
        .where((u) => ((u.name ?? '').trim().isNotEmpty) || ((u.email ?? '').trim().isNotEmpty))
        .toList();

    final primary = visible.isNotEmpty ? visible.first : (users.isNotEmpty ? users.first : null);
    final primaryName = (primary?.name?.trim().isNotEmpty ?? false)
        ? primary!.name!.trim()
        : (primary?.email?.trim().isNotEmpty ?? false)
        ? primary!.email!.trim()
        : (primary?.id ?? 'usuário');
    final others = (users.length > 1) ? users.length - 1 : 0;

    Widget rightBlock(TextStyle style) => Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        MiniAvatars(users: visible),
        Text(
          others > 0
              ? 'visível para $primaryName e outras $others pessoas'
              : 'visível só para você',
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, cons) {
        final isNarrow = cons.maxWidth < 520;
        final titleStyle = const TextStyle(
          color: Colors.black87,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        );
        final metaStyle = const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );

        final banner = Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isNarrow ? 4 : 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: isNarrow
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(titleText, textAlign: TextAlign.center, style: titleStyle),
              const SizedBox(height: 2),
              rightBlock(metaStyle.copyWith(fontSize: 11.5)),
            ],
          )
              : Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(titleText, textAlign: TextAlign.center, style: titleStyle),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: rightBlock(metaStyle),
              ),
            ],
          ),
        );

        return InkWell(
          onTap: () async {
            // Preferência do chamador:
            if (widget.onTap != null) {
              widget.onTap!();
              return;
            }
            // Comportamento padrão interativo:
            if (widget.interactive) {
              await _openParticipantsDialogFromBanner(context, _contractData);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: banner,
        );
      },
    );
  }
}
