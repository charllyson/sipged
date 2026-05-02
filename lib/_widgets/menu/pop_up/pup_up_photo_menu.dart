import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_permission.dart' as roles;
import 'package:sipged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/admPanel/system_hub_page.dart';
import 'package:sipged/screens/common/profile/user_profile_page.dart';

class PopUpPhotoMenu extends StatefulWidget {
  const PopUpPhotoMenu({
    super.key,
    this.photoSize = 40,
    this.menuWidth = 250,
    this.maxMenuHeight = 360,
    this.tooltip = 'Conta',
  });

  final double photoSize;
  final double menuWidth;
  final double maxMenuHeight;
  final String tooltip;

  @override
  State<PopUpPhotoMenu> createState() => _PopUpPhotoMenuState();
}

class _PopUpPhotoMenuState extends State<PopUpPhotoMenu> {
  OverlayEntry? _overlayEntry;

  static const double _menuTopGap = 0;
  static const double _screenMargin = 8;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
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

  void _openOverlay(UserData userData) {
    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox) return;

    final overlayState = Overlay.of(context);
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;

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
              targetBox: renderObject,
              overlayBox: overlayObject,
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
  }

  List<BalloonTileData> _buildItems(UserData userData) {
    final base = roles.roleForUser(userData);

    final isAdmin = base == roles.UserProfile.administrador ||
        base == roles.UserProfile.desenvolvedor;

    final name = (userData.name ?? '').trim();
    final profile = (userData.baseProfile ?? '').trim();

    return [
      BalloonTileData(
        id: 'perfil',
        title: name.isNotEmpty ? 'Olá, $name' : 'Meu perfil',
        subtitle: profile.isNotEmpty ? profile : 'Visualizar dados da conta',
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
      if (isAdmin)
        BalloonTileData(
          id: 'administrador',
          title: 'Administrador',
          subtitle: 'Acessar painel administrativo',
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
        title: 'Sair',
        subtitle: 'Encerrar sessão atual',
        icon: Icons.logout_rounded,
        accentColor: Colors.red.shade700,
        onTap: () async {
          _removeOverlay();

          await context.read<LoginCubit>().signOut();
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