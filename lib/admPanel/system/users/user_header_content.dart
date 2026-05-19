import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/avatar_shell.dart';

class UserHeaderContent extends StatelessWidget {
  const UserHeaderContent({
    super.key,
    required this.user,
    required this.nameText,
    required this.baseRole,
    required this.isSuper,
    required this.onPickRole,
    this.onEditUser,
    this.editing = false,
    this.topActions,
  });

  final UserData user;
  final String nameText;
  final perm.PermissionUser baseRole;
  final bool isSuper;
  final Future<void> Function(perm.PermissionUser picked) onPickRole;

  final VoidCallback? onEditUser;
  final bool editing;

  final Widget? topActions;

  bool get _roleActionEnabled {
    return !user.hasStatusRestriction && !editing;
  }

  String get _email {
    final value = (user.email ?? '').trim();
    return value.isEmpty ? 'E-mail não informado' : value;
  }

  String get _resolvedName {
    final value = nameText.trim().replaceAll(RegExp(r'\s+'), ' ');
    return value.isEmpty ? 'Usuário sem nome' : value;
  }

  String _roleLabel(perm.PermissionUser role) {
    switch (role.name) {
      case 'superAdmin':
        return 'Super administrador';
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gestor';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Leitor';
      case 'blocked':
        return 'Bloqueado';
      case 'none':
        return 'Sem acesso';
      default:
        return role.name;
    }
  }

  IconData _roleIcon(perm.PermissionUser role) {
    switch (role.name) {
      case 'superAdmin':
        return Icons.admin_panel_settings_rounded;
      case 'admin':
        return Icons.shield_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'editor':
        return Icons.edit_note_rounded;
      case 'viewer':
        return Icons.visibility_rounded;
      case 'blocked':
        return Icons.block_rounded;
      case 'none':
        return Icons.lock_outline_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  Color _roleColor(perm.PermissionUser role) {
    switch (role.name) {
      case 'superAdmin':
        return const Color(0xFF7C2D12);
      case 'admin':
        return const Color(0xFF1D4ED8);
      case 'manager':
        return const Color(0xFF047857);
      case 'editor':
        return const Color(0xFF7C3AED);
      case 'viewer':
        return const Color(0xFF475569);
      case 'blocked':
        return const Color(0xFFDC2626);
      case 'none':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF374151);
    }
  }

  Widget _buildEditIconButton({
    required bool compact,
  }) {
    if (onEditUser == null) return const SizedBox.shrink();

    final size = compact ? 34.0 : 38.0;

    return Tooltip(
      message: 'Editar usuário',
      child: InkWell(
        onTap: editing ? null : onEditUser,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: editing ? const Color(0xFFF2F4F7) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD0D5DD),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.08),
                blurRadius: compact ? 8 : 12,
                offset: Offset(0, compact ? 3 : 5),
              ),
            ],
          ),
          child: Center(
            child: editing
                ? SizedBox(
              width: compact ? 15 : 17,
              height: compact ? 15 : 17,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            )
                : Icon(
              Icons.edit_rounded,
              color: const Color(0xFF2563EB),
              size: compact ? 18 : 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleIconButton({
    required bool compact,
  }) {
    final color = _roleColor(baseRole);
    final size = compact ? 34.0 : 38.0;

    return PopupMenuButton<perm.PermissionUser>(
      tooltip: 'Alterar tipo de usuário',
      enabled: _roleActionEnabled,
      onSelected: (picked) {
        onPickRole(picked);
      },
      itemBuilder: (context) {
        return perm.PermissionUser.values.map((role) {
          final selected = role == baseRole;
          final itemColor = _roleColor(role);

          return PopupMenuItem<perm.PermissionUser>(
            value: role,
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : _roleIcon(role),
                  color: selected ? const Color(0xFF059669) : itemColor,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _roleLabel(role),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Atual',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(growable: false);
      },
      child: Tooltip(
        message: isSuper
            ? 'Tipo: ${_roleLabel(baseRole)} • super'
            : 'Tipo: ${_roleLabel(baseRole)}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _roleActionEnabled
                  ? color.withValues(alpha: 0.22)
                  : const Color(0xFFE4E7EC),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.06),
                blurRadius: compact ? 8 : 10,
                offset: Offset(0, compact ? 3 : 4),
              ),
            ],
          ),
          child: Icon(
            _roleIcon(baseRole),
            color: const Color(0xFF2563EB),
            size: compact ? 18 : 20,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconActions({
    required bool compact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRoleIconButton(
          compact: compact,
        ),
        if (onEditUser != null) ...[
          SizedBox(width: compact ? 6 : 8),
          _buildEditIconButton(
            compact: compact,
          ),
        ],
      ],
    );
  }

  Widget _buildIdentityBlock({
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _resolvedName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: user.hasStatusRestriction
                ? const Color(0xFF475467)
                : const Color(0xFF111827),
            fontSize: compact ? 15.5 : 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: user.hasStatusRestriction
                ? const Color(0xFF98A2B3)
                : const Color(0xFF667085),
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRightActionsLine({
    required bool compact,
  }) {
    final children = <Widget>[
      ?topActions,
      _buildHeaderIconActions(compact: compact),
    ];

    return Wrap(
      spacing: compact ? 7 : 8,
      runSpacing: compact ? 7 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: children,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarShell(user: user),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: _buildIdentityBlock(
            compact: false,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildRightActionsLine(
              compact: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarShell(user: user),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIdentityBlock(
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRightActionsLine(
          compact: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        if (compact) {
          return _buildMobileLayout();
        }

        return _buildDesktopLayout();
      },
    );
  }
}