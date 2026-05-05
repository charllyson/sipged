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
  final perm.SystemUserRole baseRole;
  final bool isSuper;
  final Future<void> Function(perm.SystemUserRole picked) onPickRole;

  final VoidCallback? onEditUser;
  final bool editing;

  final Widget? topActions;

  bool get _roleDropdownEnabled {
    return !user.hasStatusRestriction;
  }

  String _roleLabel(perm.SystemUserRole role) {
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

  String get _email {
    final value = (user.email ?? '').trim();
    return value.isEmpty ? 'E-mail não informado' : value;
  }

  Widget _buildEditButton({required bool compact}) {
    if (onEditUser == null) return const SizedBox.shrink();

    return Tooltip(
      message: 'Editar usuário',
      child: GestureDetector(
        onTap: editing ? null : onEditUser,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD0D5DD),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: editing
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            )
                : const Icon(
              Icons.edit_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityBlock({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nameText.trim().isEmpty ? 'Usuário sem nome' : nameText.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: user.hasStatusRestriction
                ? const Color(0xFF475467)
                : const Color(0xFF111827),
            fontSize: compact ? 16 : 19,
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

  Widget _buildChipsLine({required bool compact}) {
    return Wrap(
      spacing: compact ? 7 : 8,
      runSpacing: compact ? 7 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        _buildEditButton(compact: compact),
        ?topActions,
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<perm.SystemUserRole>(
      initialValue: baseRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isSuper ? 'Tipo de usuário • super' : 'Tipo de usuário',
        filled: true,
        fillColor: _roleDropdownEnabled
            ? Colors.white
            : const Color(0xFFF2F4F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _roleDropdownEnabled
                ? const Color(0xFFD0D5DD)
                : const Color(0xFFE4E7EC),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),
      items: perm.SystemUserRole.values.map((role) {
        return DropdownMenuItem<perm.SystemUserRole>(
          value: role,
          child: Text(
            _roleLabel(role),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _roleDropdownEnabled
                  ? const Color(0xFF101828)
                  : const Color(0xFF98A2B3),
            ),
          ),
        );
      }).toList(),
      onChanged: _roleDropdownEnabled
          ? (picked) {
        if (picked == null) return;
        onPickRole(picked);
      }
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarShell(user: user),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildIdentityBlock(compact: false),
        ),
        const SizedBox(width: 14),
        Flexible(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildChipsLine(compact: false),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 270,
          child: _buildRoleDropdown(),
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
              child: _buildIdentityBlock(compact: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _buildChipsLine(compact: true),
        ),
        const SizedBox(height: 14),
        _buildRoleDropdown(),
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