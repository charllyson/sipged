// lib/admPanel/system/tenants/manager_tenants_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/common/setup/initial_setup_page.dart';

class ManagerTenantsPage extends StatefulWidget {
  const ManagerTenantsPage({
    super.key,
    required this.currentUser,
  });

  final UserData currentUser;

  @override
  State<ManagerTenantsPage> createState() => _ManagerTenantsPageState();
}

class _ManagerTenantsPageState extends State<ManagerTenantsPage> {
  bool _didInit = false;
  bool _creating = false;
  bool _openingTenant = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInit) return;

      _didInit = true;

      final tenantCubit = context.read<TenantCubit>();
      final userCubit = context.read<UserCubit>();

      await Future.wait([
        tenantCubit.loadAvailableTenants(
          autoSelectWhenSingle: false,
          keepCurrentSelection: true,
          usePreferredTenant: true,
        ),
        userCubit.ensureLoaded(
          listenRealtime: true,
        ),
      ]);
    });
  }

  void _showNotification({
    required String title,
    required String message,
    required NotificationStatus status,
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: message,
        status: status,
        leadingLabel: 'Sistema',
        extra: const <String, dynamic>{
          'module': 'manager_tenants',
          'source': 'manager_tenants_page',
        },
      ),
    );
  }

  String _tenantLabel(TenantData tenant) {
    final companyName = (tenant.companyName ?? '').trim();
    if (companyName.isNotEmpty) return companyName;

    final fantasyName = (tenant.fantasyName ?? '').trim();
    if (fantasyName.isNotEmpty) return fantasyName;

    final label = tenant.label.trim();
    if (label.isNotEmpty) return label;

    return tenant.id;
  }

  List<UserData> _usersForTenant({
    required TenantData tenant,
    required List<UserData> users,
  }) {
    final tenantId = tenant.id.trim();

    if (tenantId.isEmpty) return const <UserData>[];

    final userCubit = context.read<UserCubit>();

    final result = users.where((user) {
      final ids = userCubit.tenantIdsOf(user);
      return ids.map((e) => e.trim()).contains(tenantId);
    }).toList();

    result.sort((a, b) {
      final aName = '${a.name ?? ''} ${a.surname ?? ''}'.trim();
      final bName = '${b.name ?? ''} ${b.surname ?? ''}'.trim();

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return result;
  }

  Future<void> _reloadAll() async {
    if (!mounted) return;

    await Future.wait([
      context.read<TenantCubit>().loadAvailableTenants(
        autoSelectWhenSingle: false,
        keepCurrentSelection: true,
        usePreferredTenant: true,
      ),
      context.read<UserCubit>().ensureLoaded(
        listenRealtime: true,
      ),
    ]);
  }

  Future<void> _openTenantSetup(TenantData tenant) async {
    if (_openingTenant || _creating) return;

    final tenantId = tenant.id.trim();

    if (tenantId.isEmpty) {
      _showNotification(
        title: 'Atenção',
        message: 'Empresa sem identificador válido.',
        status: NotificationStatus.warning,
      );
      return;
    }

    final tenantCubit = context.read<TenantCubit>();

    setState(() {
      _openingTenant = true;
    });

    try {
      await tenantCubit.selectTenant(
        tenantId,
        persistSelection: true,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) {
            return InitialSetupPage(
              user: widget.currentUser,
              presentationMode: InitialSetupPresentationMode.page,
              mode: InitialSetupMode.editTenant,
            );
          },
        ),
      );

      if (!mounted) return;

      await _reloadAll();
    } finally {
      if (mounted) {
        setState(() {
          _openingTenant = false;
        });
      }
    }
  }

  Future<void> _openCreateTenantPage() async {
    if (_creating || _openingTenant) return;

    setState(() {
      _creating = true;
    });

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) {
            return InitialSetupPage(
              user: widget.currentUser,
              presentationMode: InitialSetupPresentationMode.page,
              mode: InitialSetupMode.createTenant,
            );
          },
        ),
      );

      if (!mounted) return;

      await _reloadAll();
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Widget _buildCreateButton() {
    return FloatingActionButton.extended(
      heroTag: 'manager-tenants-create-tenant',
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      elevation: 4,
      onPressed: _creating || _openingTenant ? null : _openCreateTenantPage,
      icon: _creating
          ? const SizedBox(
        width: 18,
        height: 18,
        child: LoadingTreeDots(
          size: 18,
          strokeWidth: 2,
          color: Colors.white,
          centered: false,
        ),
      )
          : const Icon(Icons.add_business_rounded),
      label: Text(
        _creating ? 'Abrindo...' : 'Nova empresa',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      appBar: const UpBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            'Gerenciar empresas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      body: const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: LoadingTreeDots(size: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    return Scaffold(
      appBar: const UpBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            'Gerenciar empresas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateButton(),
      body: Stack(
        children: [
          const BackgroundChange(),
          Center(
            child: _ManagerTenantsErrorPanel(
              message: message,
              onRetry: _reloadAll,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPage() {
    return Scaffold(
      appBar: const UpBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            'Gerenciar empresas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateButton(),
      body: const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: Text(
              'Nenhuma empresa encontrada.',
              style: TextStyle(
                color: Color(0xFF475467),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required TenantState tenantState,
    required UserState userState,
  }) {
    final tenants = [...tenantState.availableTenants];

    tenants.sort((a, b) {
      return _tenantLabel(a).toLowerCase().compareTo(
        _tenantLabel(b).toLowerCase(),
      );
    });

    if (tenants.isEmpty) {
      return _buildEmptyPage();
    }

    return Scaffold(
      floatingActionButton: _buildCreateButton(),
      appBar: const UpBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            'Empresas, tenants e usuários vinculados',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                sliver: SliverList.separated(
                  itemCount: tenants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tenant = tenants[index];
                    final users = _usersForTenant(
                      tenant: tenant,
                      users: userState.all,
                    );

                    final selected =
                        tenant.id.trim() == tenantState.selectedTenantId?.trim();

                    return _TenantCard(
                      tenant: tenant,
                      tenantLabel: _tenantLabel(tenant),
                      linkedUsers: users,
                      selected: selected,
                      opening: _openingTenant,
                      onEdit: () => _openTenantSetup(tenant),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_openingTenant || _creating)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x44FFFFFF),
                child: Center(
                  child: LoadingTreeDots(size: 90),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantCubit, TenantState>(
      builder: (context, tenantState) {
        return BlocBuilder<UserCubit, UserState>(
          builder: (context, userState) {
            final loadingTenants =
                tenantState.isLoading && !tenantState.hasLoadedAvailableTenants;

            final loadingUsers =
                userState.isLoadingUsers && userState.all.isEmpty;

            if (loadingTenants || loadingUsers) {
              return _buildLoadingPage();
            }

            final tenantError = tenantState.error?.trim();

            if (tenantError != null && tenantError.isNotEmpty) {
              return _buildErrorPage(
                'Erro ao carregar empresas:\n$tenantError',
              );
            }

            final userError = userState.loadUsersError?.trim();

            if (userError != null && userError.isNotEmpty) {
              return _buildErrorPage(
                'Erro ao carregar usuários:\n$userError',
              );
            }

            return _buildContent(
              tenantState: tenantState,
              userState: userState,
            );
          },
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.tenantLabel,
    required this.linkedUsers,
    required this.selected,
    required this.opening,
    required this.onEdit,
  });

  final TenantData tenant;
  final String tenantLabel;
  final List<UserData> linkedUsers;
  final bool selected;
  final bool opening;
  final VoidCallback onEdit;

  String get _subtitle {
    final fantasy = (tenant.fantasyName ?? '').trim();
    final cnpj = (tenant.cnpj ?? '').trim();

    final parts = <String>[];

    if (fantasy.isNotEmpty &&
        fantasy.toLowerCase() != tenantLabel.toLowerCase()) {
      parts.add(fantasy);
    }

    if (cnpj.isNotEmpty) {
      parts.add(cnpj);
    }

    if (parts.isEmpty) return 'ID: ${tenant.id}';

    return '${parts.join(' • ')} • ID: ${tenant.id}';
  }

  int get _catalogCount {
    return tenant.units.length +
        tenant.roads.length +
        tenant.regions.length +
        tenant.fundingSources.length +
        tenant.programs.length +
        tenant.expenseNatures.length +
        tenant.companyBodies.length;
  }

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF059669);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
          width: selected ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.075),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        maintainState: false,
        tilePadding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: const Color(0xFF2563EB),
        collapsedIconColor: const Color(0xFF667085),
        leading: _TenantLogoShell(
          tenant: tenant,
          color: color,
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;

            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                _TenantInfoBadge(
                  icon: Icons.people_alt_rounded,
                  label: linkedUsers.length == 1
                      ? '1 usuário'
                      : '${linkedUsers.length} usuários',
                  color: const Color(0xFF2563EB),
                ),
                _TenantInfoBadge(
                  icon: Icons.inventory_2_rounded,
                  label: '$_catalogCount catálogos',
                  color: const Color(0xFF7C3AED),
                ),
                Tooltip(
                  message: 'Editar empresa e catálogos',
                  child: InkWell(
                    onTap: opening ? null : onEdit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: opening
                            ? const Color(0xFFF2F4F7)
                            : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF2563EB),
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 10),
                  actions,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 14),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: actions,
                  ),
                ),
              ],
            );
          },
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _TenantDetailsPanel(
            tenant: tenant,
            linkedUsers: linkedUsers,
          ),
        ],
      ),
    );
  }
}

class _TenantLogoShell extends StatelessWidget {
  const _TenantLogoShell({
    required this.tenant,
    required this.color,
  });

  final TenantData tenant;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final logoUrl = (tenant.logoUrl ?? '').trim();

    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: logoUrl.isEmpty
              ? ColoredBox(
            color: const Color(0xFFF2F4F7),
            child: Icon(
              Icons.business_rounded,
              color: color,
              size: 24,
            ),
          )
              : CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) {
              return ColoredBox(
                color: const Color(0xFFF2F4F7),
                child: Icon(
                  Icons.business_rounded,
                  color: color,
                  size: 24,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TenantInfoBadge extends StatelessWidget {
  const _TenantInfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantDetailsPanel extends StatelessWidget {
  const _TenantDetailsPanel({
    required this.tenant,
    required this.linkedUsers,
  });

  final TenantData tenant;
  final List<UserData> linkedUsers;

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _catalogLine({
    required String title,
    required List<String> values,
  }) {
    final items = values.take(8).toList();
    final remaining = values.length - items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 138,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: values.isEmpty
                ? const Text(
              'Nenhum item cadastrado.',
              style: TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
                : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...items.map(_chip),
                if (remaining > 0) _chip('+$remaining'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(UserData user) {
    final name = '${user.name ?? ''} ${user.surname ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    final email = (user.email ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: user.statusLightColor,
            child: Icon(
              user.statusIcon,
              color: user.statusColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Usuário sem nome' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? 'E-mail não informado' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: user.statusLightColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: user.statusBorderColor,
              ),
            ),
            child: Center(
              child: Text(
                user.statusLabel,
                style: TextStyle(
                  color: user.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final wide = constraints.maxWidth >= 900;

        final usersSection = _section(
          title: 'Usuários com acesso',
          icon: Icons.people_alt_rounded,
          children: [
            if (linkedUsers.isEmpty)
              const Text(
                'Nenhum usuário vinculado a esta empresa.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...linkedUsers.map(_userTile),
          ],
        );

        final catalogsSection = _section(
          title: 'Resumo dos catálogos',
          icon: Icons.inventory_2_rounded,
          children: [
            _catalogLine(title: 'Unidades', values: tenant.units),
            _catalogLine(title: 'Rodovias', values: tenant.roads),
            _catalogLine(title: 'Regiões', values: tenant.regions),
            _catalogLine(title: 'Fontes', values: tenant.fundingSources),
            _catalogLine(title: 'Programas', values: tenant.programs),
            _catalogLine(title: 'Naturezas', values: tenant.expenseNatures),
            _catalogLine(title: 'Órgãos', values: tenant.companyBodies),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: usersSection),
              const SizedBox(width: 12),
              Expanded(child: catalogsSection),
            ],
          );
        }

        return Column(
          children: [
            usersSection,
            const SizedBox(height: 12),
            catalogsSection,
          ],
        );
      },
    );
  }
}

class _ManagerTenantsErrorPanel extends StatelessWidget {
  const _ManagerTenantsErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}