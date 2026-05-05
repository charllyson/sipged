import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/admPanel/system/users/manager_users.dart';
import 'package:sipged/screens/common/setup/initial_setup_page.dart';

import '../../_widgets/buttons/circle_button_change.dart';
import '../../_widgets/menu/upBar/up_bar.dart';

class ManagerSystemPage extends StatelessWidget {
  const ManagerSystemPage({super.key});

  void _notifyWarning(BuildContext context, String message) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Atenção',
        subtitle: message,
        type: NotificationStatus.warning,
        leadingLabel: 'Sistema',
      ),
    );
  }

  int _gridCountForWidth(double width) {
    if (width >= 1100) return 2;
    return 1;
  }

  double _aspectRatioForWidth(double width) {
    if (width >= 1100) return 2.2;
    if (width >= 760) return 2.6;
    return 1.65;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserCubit, UserData?>(
          (c) => c.state.initialized ? c.state.current : null,
    );

    final items = <_ManagerSystemItem>[
      _ManagerSystemItem(
        title: 'Gerenciar usuários',
        subtitle:
        'Controle perfis, permissões globais, permissões por empresa e acessos aos módulos.',
        icon: Icons.supervised_user_circle_rounded,
        color: const Color(0xFF2563EB),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ManagerUsers(),
            ),
          );
        },
      ),
      _ManagerSystemItem(
        title: 'Gerenciar empresas',
        subtitle:
        'Cadastre empresas, revise informações administrativas e configure o ambiente inicial.',
        icon: Icons.business_rounded,
        color: const Color(0xFF059669),
        onTap: () {
          if (user == null) {
            _notifyWarning(
              context,
              'Usuário não carregado. Tente novamente.',
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InitialSetupPage(
                user: user,
                presentationMode: InitialSetupPresentationMode.page,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: const [
          Text(
            'Sistema',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final cross = _gridCountForWidth(width);

                return SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: _aspectRatioForWidth(width),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return _ManagerSystemCard(item: item);
                  },
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: _SystemInfoPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerSystemItem {
  const _ManagerSystemItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ManagerSystemCard extends StatelessWidget {
  const _ManagerSystemCard({
    required this.item,
  });

  final _ManagerSystemItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 520;

                    final iconBox = Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 29,
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconBox,
                          const Spacer(),
                          _ManagerSystemCardText(item: item),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        iconBox,
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ManagerSystemCardText(item: item),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerSystemCardText extends StatelessWidget {
  const _ManagerSystemCardText({
    required this.item,
  });

  final _ManagerSystemItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          item.subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        _OpenBadge(color: item.color),
      ],
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Abrir',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _SystemInfoPanel extends StatelessWidget {
  const _SystemInfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Aqui você pode adicionar outras ferramentas específicas do sistema, como auditoria, logs, preferências, temas, dicionário de dados e parametrizações administrativas.',
              style: TextStyle(
                fontSize: 13,
                height: 1.38,
                color: Color(0xFF78350F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}