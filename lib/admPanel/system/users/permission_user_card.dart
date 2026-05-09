import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/admPanel/system/users/permission_group_expansion.dart';
import 'package:sipged/admPanel/system/users/module_permission_tile.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/user_expand_icon_badge.dart';
import 'package:sipged/admPanel/system/users/user_header_content.dart';

class PermissionUserCard extends StatefulWidget {
  const PermissionUserCard({
    super.key,
    required this.user,
    required this.nameText,
    required this.userPermissions,
    required this.groups,
    required this.onPickRole,
    required this.onPersistGroupRead,
    required this.onPersistModulePermission,
    this.onEditUser,
    this.availableTenants = const <TenantData>[],
    this.userTenantIds = const <String>[],
    this.tenantLabelBuilder,
    this.onPersistTenantAccess,
  });

  final UserData user;
  final String nameText;
  final perm.UserPermissionData userPermissions;

  final Map<String, List<ModuleData>> groups;

  final Future<void> Function()? onEditUser;

  final Future<void> Function({
  required String tenantId,
  required perm.SystemUserRole picked,
  }) onPickRole;

  final Future<void> Function({
  required String tenantId,
  required List<String> modules,
  required bool allow,
  }) onPersistGroupRead;

  final Future<void> Function({
  required String tenantId,
  required String module,
  required String action,
  required bool allow,
  }) onPersistModulePermission;

  final List<TenantData> availableTenants;
  final List<String> userTenantIds;
  final String Function(TenantData tenant)? tenantLabelBuilder;

  final Future<void> Function({
  required String tenantId,
  required bool allow,
  })? onPersistTenantAccess;

  @override
  State<PermissionUserCard> createState() => _PermissionUserCardState();
}

class _PermissionUserCardState extends State<PermissionUserCard> {
  bool _expanded = false;
  bool _editing = false;
  bool _savingTenantAccess = false;
  bool _savingPermission = false;
  String? _savingTenantId;
  String? _selectedTenantId;

  @override
  void initState() {
    super.initState();
    _selectedTenantId = _initialSelectedTenantId();
  }

  @override
  void didUpdateWidget(covariant PermissionUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final current = _selectedTenantId?.trim();

    if (current == null || current.isEmpty) {
      _selectedTenantId = _initialSelectedTenantId();
      return;
    }

    final exists = widget.availableTenants.any(
          (tenant) => tenant.id.trim() == current,
    );

    if (!exists && widget.availableTenants.isNotEmpty) {
      _selectedTenantId = _initialSelectedTenantId();
    }
  }

  bool get _hasStatusRestriction {
    return widget.user.hasStatusRestriction;
  }

  bool get _canEditTenantAccess {
    return !_hasStatusRestriction && widget.onPersistTenantAccess != null;
  }

  List<String> get _cleanUserTenantIds {
    final list = widget.userTenantIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  String? get _cleanSelectedTenantId {
    final id = _selectedTenantId?.trim();

    if (id == null || id.isEmpty) return null;

    return id;
  }

  bool get _selectedTenantAllowed {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null) return false;

    return _cleanUserTenantIds.contains(tenantId);
  }

  String? _initialSelectedTenantId() {
    final linkedTenants = _cleanUserTenantIds;

    for (final tenantId in linkedTenants) {
      final exists = widget.availableTenants.any(
            (tenant) => tenant.id.trim() == tenantId,
      );

      if (exists) return tenantId;
    }

    if (widget.availableTenants.isNotEmpty) {
      return widget.availableTenants.first.id.trim();
    }

    return linkedTenants.isNotEmpty ? linkedTenants.first : null;
  }

  perm.SystemUserRole get _effectiveBaseRole {
    return widget.userPermissions.roleForTenant(
      _cleanSelectedTenantId,
    );
  }

  bool get _effectiveIsSuper {
    return widget.userPermissions.isSuperUserForTenant(
      _cleanSelectedTenantId,
    );
  }

  int get _totalModules {
    return widget.groups.values.fold<int>(
      0,
          (total, items) {
        final validModules = items
            .map((e) => e.permissionModule.trim())
            .where((module) => module.isNotEmpty)
            .length;

        return total + validModules;
      },
    );
  }

  int get _readableModules {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null) return 0;

    int readable = 0;

    for (final items in widget.groups.values) {
      for (final item in items) {
        final module = item.permissionModule.trim();

        if (module.isEmpty) continue;

        final canRead = widget.userPermissions.canModuleString(
          module: module,
          action: 'read',
          tenantId: tenantId,
        );

        if (canRead) {
          readable++;
        }
      }
    }

    return _effectiveIsSuper ? _totalModules : readable;
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

  String _tenantLabel(TenantData tenant) {
    final external = widget.tenantLabelBuilder;

    if (external != null) {
      final label = external(tenant).trim();

      if (label.isNotEmpty) return label;
    }

    final companyName = (tenant.companyName ?? '').trim();
    if (companyName.isNotEmpty) return companyName;

    final fantasyName = (tenant.fantasyName ?? '').trim();
    if (fantasyName.isNotEmpty) return fantasyName;

    final label = tenant.label.trim();
    if (label.isNotEmpty) return label;

    return tenant.id;
  }

  TenantData? _tenantById(String tenantId) {
    final cleanId = tenantId.trim();

    if (cleanId.isEmpty) return null;

    for (final tenant in widget.availableTenants) {
      if (tenant.id.trim() == cleanId) {
        return tenant;
      }
    }

    return null;
  }

  String _tenantNameById(String tenantId) {
    final tenant = _tenantById(tenantId);

    if (tenant == null) return tenantId;

    return _tenantLabel(tenant);
  }

  Future<void> _toggleTenantAccess({
    required String tenantId,
    required bool allow,
  }) async {
    final callback = widget.onPersistTenantAccess;
    final cleanTenantId = tenantId.trim();

    if (callback == null || cleanTenantId.isEmpty) return;
    if (_savingTenantAccess || _savingPermission) return;

    setState(() {
      _savingTenantAccess = true;
      _savingTenantId = cleanTenantId;
    });

    try {
      await callback(
        tenantId: cleanTenantId,
        allow: allow,
      );

      if (!allow && _selectedTenantId == cleanTenantId) {
        setState(() {
          _selectedTenantId = cleanTenantId;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingTenantAccess = false;
          _savingTenantId = null;
        });
      }
    }
  }

  Future<void> _handleRolePicked(perm.SystemUserRole picked) async {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null || _savingTenantAccess || _savingPermission) return;

    setState(() {
      _savingPermission = true;
    });

    try {
      await widget.onPickRole(
        tenantId: tenantId,
        picked: picked,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPermission = false;
        });
      }
    }
  }

  Future<void> _handleGroupRead({
    required List<String> modules,
    required bool allow,
  }) async {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null || _savingTenantAccess || _savingPermission) return;

    setState(() {
      _savingPermission = true;
    });

    try {
      await widget.onPersistGroupRead(
        tenantId: tenantId,
        modules: modules,
        allow: allow,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPermission = false;
        });
      }
    }
  }

  Future<void> _handleModulePermission({
    required String module,
    required String action,
    required bool allow,
  }) async {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null || _savingTenantAccess || _savingPermission) return;

    setState(() {
      _savingPermission = true;
    });

    try {
      await widget.onPersistModulePermission(
        tenantId: tenantId,
        module: module,
        action: action,
        allow: allow,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPermission = false;
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

  Widget _buildTenantCountBadge() {
    final count = _cleanUserTenantIds.length;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.business_rounded,
            color: Color(0xFF2563EB),
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            count == 1 ? '1 EMPRESA' : '$count EMPRESAS',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
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
        _buildTenantCountBadge(),
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

  Widget _buildTenantSelectorSection() {
    final selectedTenantId = _cleanSelectedTenantId;

    final availableTenants = [...widget.availableTenants]
      ..sort(
            (a, b) => _tenantLabel(a).toLowerCase().compareTo(
          _tenantLabel(b).toLowerCase(),
        ),
      );

    final unknownTenantIds = _cleanUserTenantIds
        .where((tenantId) => _tenantById(tenantId) == null)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTenantSelectorHeader(),
          const SizedBox(height: 12),
          if (availableTenants.isEmpty)
            _buildTenantEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;

                final selector = DropdownButtonFormField<String>(
                  initialValue: selectedTenantId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Empresa para configurar permissões',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFD0D5DD),
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
                  items: availableTenants.map((tenant) {
                    final tenantId = tenant.id.trim();
                    final allowed = _cleanUserTenantIds.contains(tenantId);

                    return DropdownMenuItem<String>(
                      value: tenantId,
                      child: Row(
                        children: [
                          Icon(
                            allowed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: allowed
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _tenantLabel(tenant),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _savingTenantAccess || _savingPermission
                      ? null
                      : (value) {
                    final clean = value?.trim();

                    if (clean == null || clean.isEmpty) return;

                    setState(() {
                      _selectedTenantId = clean;
                    });
                  },
                );

                final accessSwitch = _buildSelectedTenantAccessSwitch();

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      selector,
                      const SizedBox(height: 10),
                      accessSwitch,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: selector),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 260,
                      child: accessSwitch,
                    ),
                  ],
                );
              },
            ),
          if (unknownTenantIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildUnknownTenantsWarning(unknownTenantIds),
          ],
        ],
      ),
    );
  }

  Widget _buildTenantSelectorHeader() {
    final total = _cleanUserTenantIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Empresa e permissões do usuário',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          total == 0
              ? 'Selecione uma empresa e marque os módulos para liberar acesso.'
              : total == 1
              ? 'Usuário possui acesso a 1 empresa.'
              : 'Usuário possui acesso a $total empresas.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedTenantAccessSwitch() {
    final selectedTenantId = _cleanSelectedTenantId;
    final isSavingThis =
        _savingTenantAccess && _savingTenantId == selectedTenantId;

    if (selectedTenantId == null) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFDE68A),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 19,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selecione uma empresa.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _selectedTenantAllowed
            ? const Color(0xFFECFDF3)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedTenantAllowed
              ? const Color(0xFFA7F3D0)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          if (isSavingThis)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          else
            Icon(
              _selectedTenantAllowed
                  ? Icons.verified_user_rounded
                  : Icons.lock_outline_rounded,
              color: _selectedTenantAllowed
                  ? const Color(0xFF059669)
                  : const Color(0xFF64748B),
              size: 19,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedTenantAllowed ? 'Acesso liberado' : 'Sem acesso',
              style: TextStyle(
                color: _selectedTenantAllowed
                    ? const Color(0xFF047857)
                    : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: _selectedTenantAllowed,
            onChanged:
            _canEditTenantAccess && !_savingTenantAccess && !_savingPermission
                ? (value) {
              _toggleTenantAccess(
                tenantId: selectedTenantId,
                allow: value,
              );
            }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTenantEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhuma empresa foi encontrada em tenants.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownTenantsWarning(List<String> unknownTenantIds) {
    final text = unknownTenantIds.map(_tenantNameById).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'O usuário possui vínculos com tenants que não aparecem mais na lista: $text.',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionUnavailable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.business_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selecione uma empresa para configurar as permissões de módulos deste usuário.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingPermissionBanner() {
    if (!_savingPermission) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Salvando permissões...',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGroups() {
    final tenantId = _cleanSelectedTenantId;

    if (tenantId == null) {
      return _buildPermissionUnavailable();
    }

    return Column(
      children: widget.groups.entries.map((entry) {
        final groupLabel = entry.key;
        final items = entry.value;

        final modules = items
            .map((e) => e.permissionModule.trim())
            .where((module) => module.isNotEmpty)
            .toList(growable: false);

        int checkedCount = 0;

        for (final module in modules) {
          final canRead = widget.userPermissions.canModuleString(
            module: module,
            action: 'read',
            tenantId: tenantId,
          );

          if (canRead) {
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
            checkedCount: _effectiveIsSuper ? modules.length : checkedCount,
            value: _effectiveIsSuper ? true : triValue,
            isSuper: _effectiveIsSuper,
            onChanged: _effectiveIsSuper || _savingPermission
                ? null
                : (value) async {
              final target = value ?? false;

              await _handleGroupRead(
                modules: modules,
                allow: target,
              );
            },
            children: [
              ...items.map((item) {
                final moduleId = item.permissionModule.trim();

                if (moduleId.isEmpty) {
                  return const SizedBox.shrink();
                }

                final effective =
                widget.userPermissions.effectiveModulePermissions(
                  module: moduleId,
                  tenantId: tenantId,
                );

                return ModulePermissionTile(
                  moduleId: moduleId,
                  title: item.labelModule.trim().toUpperCase(),
                  isSuper: _effectiveIsSuper,
                  effective: effective,
                  onChanged: ({
                    required String action,
                    required bool allow,
                  }) async {
                    await _handleModulePermission(
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
    final cardColor =
    _hasStatusRestriction ? const Color(0xFFF7F8FA) : Colors.white;

    final borderColor =
    _hasStatusRestriction ? const Color(0xFFE4E7EC) : const Color(0xFFE5E7EB);

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
            baseRole: _effectiveBaseRole,
            isSuper: _effectiveIsSuper,
            onPickRole: _handleRolePicked,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTenantSelectorSection(),
                  _buildSavingPermissionBanner(),
                  _buildPermissionGroups(),
                ],
              ),
            ),
          ]
              : const <Widget>[],
        ),
      ),
    );
  }
}