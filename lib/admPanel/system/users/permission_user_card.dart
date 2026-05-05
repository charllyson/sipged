import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/admPanel/system/users/permission_group_expansion.dart';

import 'module_permission_tile.dart';
import '../../../screens/common/login/sign_up/widgets/user_expand_icon_badge.dart';
import 'user_header_content.dart';

class PermissionUserCard extends StatefulWidget {
  const PermissionUserCard({
    super.key,
    required this.user,
    required this.nameText,
    required this.baseRole,
    required this.isSuper,
    required this.userPermissions,
    required this.tenantId,
    required this.groups,
    required this.onPickRole,
    required this.onPersistGroupRead,
    required this.onPersistModulePermission,
    this.onEditUser,
  });

  final UserData user;
  final String nameText;
  final perm.SystemUserRole baseRole;
  final bool isSuper;
  final perm.UserPermissionData userPermissions;
  final String? tenantId;
  final Map<String, List<PermItem>> groups;

  final Future<void> Function()? onEditUser;

  final Future<void> Function(perm.SystemUserRole picked) onPickRole;

  final Future<void> Function({
  required List<String> modules,
  required bool allow,
  }) onPersistGroupRead;

  final Future<void> Function({
  required String module,
  required String action,
  required bool allow,
  }) onPersistModulePermission;

  @override
  State<PermissionUserCard> createState() => _PermissionUserCardState();
}

class _PermissionUserCardState extends State<PermissionUserCard> {
  bool _expanded = false;
  bool _editing = false;

  bool get _hasStatusRestriction {
    return widget.user.hasStatusRestriction;
  }

  int get _totalModules {
    return widget.groups.values.fold<int>(
      0,
          (total, items) {
        return total +
            items
                .map((e) => e.module.trim())
                .where((module) => module.isNotEmpty)
                .length;
      },
    );
  }

  int get _readableModules {
    int readable = 0;

    for (final items in widget.groups.values) {
      for (final item in items) {
        final module = item.module.trim();

        if (module.isEmpty) continue;

        if (widget.userPermissions.canModuleString(
          module: module,
          action: 'read',
          tenantId: widget.tenantId,
        )) {
          readable++;
        }
      }
    }

    return widget.isSuper ? _totalModules : readable;
  }

  Future<void> _handleEditUser() async {
    final callback = widget.onEditUser;

    if (callback == null || _editing) return;

    setState(() {
      _editing = true;
    });

    try {
      await callback();
    } finally {
      if (mounted) {
        setState(() {
          _editing = false;
        });
      }
    }
  }

  Widget _buildStatusBadge() {
    if (!_hasStatusRestriction) return const SizedBox.shrink();

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: widget.user.statusLightColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: widget.user.statusBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.user.statusIcon,
            color: widget.user.statusColor,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            widget.user.statusLabel,
            style: TextStyle(
              color: widget.user.statusColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        if (_hasStatusRestriction) _buildStatusBadge(),
        UserExpandIconBadge(
          readable: _readableModules,
          total: _totalModules,
          color: widget.user.statusColor,
          backgroundColor: widget.user.statusLightColor,
          borderColor: widget.user.statusBorderColor,
        ),
      ],
    );
  }

  Widget _buildPermissionGroups() {
    return Column(
      children: widget.groups.entries.map((entry) {
        final groupLabel = entry.key;
        final items = entry.value;

        final modules = items
            .map((e) => e.module.trim())
            .where((module) => module.isNotEmpty)
            .toList(growable: false);

        int checkedCount = 0;

        for (final module in modules) {
          if (widget.userPermissions.canModuleString(
            module: module,
            action: 'read',
            tenantId: widget.tenantId,
          )) {
            checkedCount++;
          }
        }

        final all = checkedCount == modules.length && modules.isNotEmpty;
        final none = checkedCount == 0;
        final triValue = all ? true : (none ? false : null);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PermissionGroupExpansion(
            title: groupLabel,
            total: modules.length,
            checkedCount: widget.isSuper ? modules.length : checkedCount,
            value: widget.isSuper ? true : triValue,
            isSuper: widget.isSuper,
            onChanged: widget.isSuper
                ? null
                : (value) async {
              final target = value ?? false;

              await widget.onPersistGroupRead(
                modules: modules,
                allow: target,
              );
            },
            children: [
              ...items.map((item) {
                final moduleId = item.module.trim();

                if (moduleId.isEmpty) {
                  return const SizedBox.shrink();
                }

                final effective =
                widget.userPermissions.effectiveModulePermissions(
                  module: moduleId,
                  tenantId: widget.tenantId,
                );

                return ModulePermissionTile(
                  moduleId: moduleId,
                  title: item.label.trim().toUpperCase(),
                  isSuper: widget.isSuper,
                  effective: effective,
                  onChanged: ({
                    required String action,
                    required bool allow,
                  }) async {
                    await widget.onPersistModulePermission(
                      module: moduleId,
                      action: action,
                      allow: allow,
                    );
                  },
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _hasStatusRestriction
        ? const Color(0xFFF7F8FA)
        : Colors.white;

    final borderColor = _hasStatusRestriction
        ? const Color(0xFFE4E7EC)
        : const Color(0xFFE5E7EB);

    final shadowAlpha = _hasStatusRestriction ? 0.035 : 0.08;
    final shadowBlur = _hasStatusRestriction ? 14.0 : 24.0;
    final shadowOffsetY = _hasStatusRestriction ? 6.0 : 12.0;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: const Color(0xFFEEF4FF),
        highlightColor: const Color(0xFFEEF4FF),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(
                alpha: shadowAlpha,
              ),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffsetY),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          maintainState: false,
          tilePadding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          iconColor: const Color(0xFF2563EB),
          collapsedIconColor: const Color(0xFF667085),
          onExpansionChanged: (open) {
            setState(() {
              _expanded = open;
            });
          },
          trailing: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 30,
            color: _hasStatusRestriction
                ? const Color(0xFF98A2B3)
                : const Color(0xFF667085),
          ),
          title: UserHeaderContent(
            user: widget.user,
            nameText: widget.nameText,
            baseRole: widget.baseRole,
            isSuper: widget.isSuper,
            onPickRole: widget.onPickRole,
            onEditUser: widget.onEditUser == null ? null : _handleEditUser,
            editing: _editing,
            topActions: _buildHeaderActions(),
          ),
          children: _expanded
              ? [
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF0F2F5),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: _buildPermissionGroups(),
            ),
          ]
              : const <Widget>[],
        ),
      ),
    );
  }
}