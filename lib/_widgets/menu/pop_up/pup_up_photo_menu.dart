// lib/_widgets/menu/upBar/pop_up_photo_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/images/avatar/photo_circle.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';

import 'package:sipged/admPanel/system_hub_page.dart';
import 'package:sipged/screens/common/profile/user_profile_page.dart';

class PopUpPhotoMenu extends StatefulWidget {
  const PopUpPhotoMenu({
    super.key,
    this.photoSize = 40,
    this.menuWidth = 270,
    this.maxMenuHeight = 390,
    this.tooltip = 'Conta',
  });

  final double photoSize;
  final double menuWidth;
  final double maxMenuHeight;
  final String tooltip;

  @override
  State<PopUpPhotoMenu> createState() => _PopUpPhotoMenuState();
}

class _PopUpPhotoMenuState extends State<PopUpPhotoMenu>
    with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;

  final ValueNotifier<int> _positionTick = ValueNotifier<int>(0);

  ScrollPosition? _scrollPosition;

  static const double _menuTopGap = 0;
  static const double _screenMargin = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachToNearestScrollPosition();
  }

  @override
  void didUpdateWidget(covariant PopUpPhotoMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changedLayout = oldWidget.photoSize != widget.photoSize ||
        oldWidget.menuWidth != widget.menuWidth ||
        oldWidget.maxMenuHeight != widget.maxMenuHeight;

    if (changedLayout) {
      _removeOverlay();
    }

    _attachToNearestScrollPosition();
  }

  @override
  void didChangeMetrics() {
    _requestBalloonPositionUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachFromScrollPosition();
    _removeOverlay();
    _positionTick.dispose();
    super.dispose();
  }

  void _attachToNearestScrollPosition() {
    final scrollableState = Scrollable.maybeOf(context);
    final nextPosition = scrollableState?.position;

    if (identical(_scrollPosition, nextPosition)) return;

    _detachFromScrollPosition();

    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_requestBalloonPositionUpdate);
  }

  void _detachFromScrollPosition() {
    _scrollPosition?.removeListener(_requestBalloonPositionUpdate);
    _scrollPosition = null;
  }

  void _requestBalloonPositionUpdate() {
    if (_overlayEntry == null) return;
    _positionTick.value++;
  }

  void _toggleMenu(UserData userData) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _openOverlay(userData);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  perm.UserPermissionData _fallbackPermissionFromUser(UserData userData) {
    final uid = (userData.uid ?? '').trim();
    final raw = userData.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return perm.UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return perm.UserPermissionData(
      uid: uid,
    );
  }

  String _companyNameFromTenant(TenantData? tenant) {
    if (tenant == null) return '';

    final companyName = (tenant.companyName ?? '').trim();
    if (companyName.isNotEmpty) return companyName;

    final fantasyName = (tenant.fantasyName ?? '').trim();
    if (fantasyName.isNotEmpty) return fantasyName;

    return tenant.label.trim();
  }

  Widget _buildTenantLogo(TenantData tenant) {
    final logoUrl = (tenant.logoUrl ?? '').trim();

    if (logoUrl.isEmpty) {
      return _buildTenantLogoFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        color: Colors.white,
        child: Image.network(
          logoUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _buildTenantLogoFallback();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Center(
              child: SizedBox.square(
                dimension: 16,
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

  Widget _buildTenantLogoFallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.teal.shade700.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.business_rounded,
        color: Colors.teal.shade700,
        size: 21,
      ),
    );
  }

  Future<void> _switchTenant() async {
    final tenantCubit = context.read<TenantCubit>();

    _removeOverlay();

    await tenantCubit.prepareTenantSwitch(
      clearPersistedSelection: true,
      reloadAvailableTenants: true,
    );

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openOverlay(UserData userData) {
    final targetObject = context.findRenderObject();

    if (targetObject is! RenderBox) return;
    if (!targetObject.attached) return;

    final overlayState = Overlay.of(context);
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;
    if (!overlayObject.attached) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              targetBox: targetObject,
              overlayBox: overlayObject,
              rebuildListenable: _positionTick,
              width: widget.menuWidth,
              maxHeight: widget.maxMenuHeight,
              topGap: _menuTopGap,
              screenMargin: _screenMargin,
              title: 'Minha conta',
              headerIcon: Icons.account_circle_outlined,
              emptyMessage: 'Nenhuma opção encontrada.',
              items: _buildItems(userData),
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBalloonPositionUpdate();
    });
  }

  List<BalloonTileData> _buildItems(UserData userData) {
    final permissionState = context.read<PermissionCubit>().state;
    final tenantState = context.read<TenantCubit>().state;

    final currentPermissions =
        permissionState.current ?? _fallbackPermissionFromUser(userData);

    final activeTenantId =
        permissionState.activeTenantId ?? tenantState.selectedTenantId;

    final role = currentPermissions.roleForTenant(activeTenantId);
    final isSuper = currentPermissions.isSuperUserForTenant(activeTenantId);

    final name = (userData.name ?? '').trim();
    final roleLabel = perm.SystemRoleCodec.label(role);

    final tenant = tenantState.selectedTenant ?? tenantState.tenantProfile;
    final companyName = _companyNameFromTenant(tenant);

    return [
      if (tenant != null && companyName.isNotEmpty)
        BalloonTileData(
          id: 'empresa_logada',
          title: Row(
            children: [
              const Text('Logado: '),
              Expanded(
                child: Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: const Text('Clique para trocar de empresa'),
          leading: _buildTenantLogo(tenant),
          accentColor: Colors.teal.shade700,
          onTap: _switchTenant,
        ),
      BalloonTileData(
        id: 'perfil',
        title: Text(name.isNotEmpty ? 'Olá, $name' : 'Meu perfil'),
        subtitle: Text(
          roleLabel.isNotEmpty ? roleLabel : 'Visualizar dados da conta',
        ),
        icon: Icons.person_outline_rounded,
        accentColor: Colors.blue.shade800,
        onTap: () {
          _removeOverlay();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const UserProfilePage(),
            ),
          );
        },
      ),
      if (isSuper)
        BalloonTileData(
          id: 'administrador',
          title: const Text('Administrador'),
          subtitle: const Text('Acessar painel administrativo'),
          icon: Icons.admin_panel_settings_outlined,
          accentColor: Colors.indigo.shade700,
          onTap: () {
            _removeOverlay();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SystemHubPage(),
              ),
            );
          },
        ),
      BalloonTileData(
        id: 'sair',
        title: const Text('Sair'),
        subtitle: const Text('Encerrar sessão atual'),
        icon: Icons.logout_rounded,
        accentColor: Colors.red.shade700,
        onTap: () async {
          final loginCubit = context.read<LoginCubit>();
          final userCubit = context.read<UserCubit>();

          _removeOverlay();

          userCubit.clearCurrentUser();

          await loginCubit.signOut();

          if (!mounted) return;

          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.select<UserCubit, UserData?>(
          (c) => c.state.initialized ? c.state.current : null,
    );

    if (userData == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: LoadingTreeDots(
          size: 20,
          strokeWidth: 2,
          centered: false,
        ),
      );
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _toggleMenu(userData),
        child: SizedBox.square(
          dimension: widget.photoSize,
          child: PhotoCircle(
            userData: userData,
            size: widget.photoSize,
          ),
        ),
      ),
    );
  }
}