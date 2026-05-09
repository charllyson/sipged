// lib/screens/common/tenant/tenant_selection_page.dart
// ou:
// lib/screens/common/login/sign_in/tenant_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class TenantSelectionPage extends StatefulWidget {
  const TenantSelectionPage({
    super.key,
    required this.userData,
    required this.tenants,
    required this.permissionData,
    required this.onTenantSelected,
  });

  final UserData userData;
  final List<TenantData> tenants;
  final UserPermissionData permissionData;
  final Future<void> Function(String tenantId) onTenantSelected;

  @override
  State<TenantSelectionPage> createState() => _TenantSelectionPageState();
}

class _TenantSelectionPageState extends State<TenantSelectionPage> {
  bool _isSelecting = false;
  String? _error;

  String _tenantTitle(TenantData tenant) {
    final companyName = tenant.companyName?.trim();
    final fantasyName = tenant.fantasyName?.trim();
    final label = tenant.label.trim();

    if (companyName != null && companyName.isNotEmpty) {
      return companyName;
    }

    if (fantasyName != null && fantasyName.isNotEmpty) {
      return fantasyName;
    }

    if (label.isNotEmpty) {
      return label;
    }

    return 'Empresa sem nome';
  }

  String _tenantSubtitle(TenantData tenant) {
    final title = _tenantTitle(tenant);
    final items = <String>[];

    final fantasyName = tenant.fantasyName?.trim();
    final label = tenant.label.trim();

    if (fantasyName != null &&
        fantasyName.isNotEmpty &&
        fantasyName != title) {
      items.add(fantasyName);
    }

    if (label.isNotEmpty && label != title) {
      items.add(label);
    }

    if (items.isEmpty) {
      return 'Empresa disponível para acesso';
    }

    return items.join(' • ');
  }

  SystemUserRole _roleForTenant(String tenantId) {
    return widget.permissionData.roleForTenant(tenantId);
  }

  Future<void> _selectTenant(String tenantId) async {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty || _isSelecting) return;

    setState(() {
      _isSelecting = true;
      _error = null;
    });

    try {
      await widget.onTenantSelected(cleanTenantId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isSelecting = false;
      });
    }
  }

  Future<void> _signOut() async {
    await context.read<LoginCubit>().signOut();
  }

  Widget _buildTenantLogo(TenantData tenant, {double size = 46}) {
    final logoUrl = (tenant.logoUrl ?? '').trim();

    if (logoUrl.isEmpty) {
      return _buildTenantLogoFallback(size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _buildTenantLogoFallback(size: size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Center(
              child: SizedBox.square(
                dimension: size * 0.38,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.teal.shade700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTenantLogoFallback({double size = 46}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.teal.shade700.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.business_rounded,
        color: Colors.teal.shade700,
        size: size * 0.48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenants = [...widget.tenants]
      ..sort(
            (a, b) => _tenantTitle(a)
            .toLowerCase()
            .compareTo(_tenantTitle(b).toLowerCase()),
      );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B2033),
              Colors.blue.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = MediaQuery.of(context).size.width;
                  final compact = width < 520;

                  final horizontalPagePadding = compact ? 14.0 : 18.0;
                  final topPadding = compact ? 14.0 : 16.0;
                  final bottomPadding = compact ? 14.0 : 16.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 560,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: horizontalPagePadding,
                          right: horizontalPagePadding,
                          top: topPadding,
                          bottom: bottomPadding +
                              MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight -
                                topPadding -
                                bottomPadding,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: compact ? 0 : 4),
                              Align(
                                alignment: Alignment.center,
                                child: Transform.scale(
                                  scale: compact ? 0.92 : 1.0,
                                  child: const SipgedLogo(),
                                ),
                              ),
                              SizedBox(height: compact ? 14 : 16),
                              _buildTenantCardArea(
                                context: context,
                                compact: compact,
                                tenants: tenants,
                              ),
                              SizedBox(height: compact ? 8 : 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isSelecting)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: LoadingTreeDots(
                      message: Text(
                        'Carregando empresa...',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCardArea({
    required BuildContext context,
    required bool compact,
    required List<TenantData> tenants,
  }) {
    return BasicCard(
      isDark: false,
      backgroundColor: Colors.white,
      gradient: null,
      borderColor: Colors.white.withValues(alpha: 0.92),
      borderRadius: 24,
      enableShadow: true,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: compact ? 0.14 : 0.16,
          ),
          blurRadius: compact ? 22 : 26,
          offset: Offset(0, compact ? 10 : 12),
        ),
      ],
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          if (_error != null && _error!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.red.shade100,
                  ),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),
          if (tenants.isEmpty)
            _NoTenantAccessCard(
              onSignOut: _signOut,
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < tenants.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final tenant = tenants[index];
                      final role = _roleForTenant(tenant.id);
                      final roleLabel = SystemRoleCodec.label(role);

                      return _TenantCard(
                        title: _tenantTitle(tenant),
                        subtitle: _tenantSubtitle(tenant),
                        roleLabel: roleLabel,
                        enabled: !_isSelecting,
                        leading: _buildTenantLogo(tenant),
                        onTap: () => _selectTenant(tenant.id),
                      );
                    },
                  ),
                  if (index < tenants.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2033).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: Color(0xFF1B2033),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecione a empresa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha o perfil de acesso que deseja utilizar nesta sessão.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sair',
          onPressed: _isSelecting ? null : _signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.enabled,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String roleLabel;
  final bool enabled;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedRoleLabel =
    roleLabel.trim().isEmpty ? 'Perfil não definido' : roleLabel.trim();

    return SizedBox(
      width: double.infinity,
      height: 142,
      child: Material(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2033).withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            resolvedRoleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B2033),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoTenantAccessCard extends StatelessWidget {
  const _NoTenantAccessCard({
    required this.onSignOut,
  });

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma empresa vinculada',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seu usuário foi autenticado, mas ainda não possui acesso a nenhuma empresa. Solicite ao administrador o vínculo com uma empresa/tenant.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}