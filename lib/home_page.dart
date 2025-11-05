// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart'; // MenuItem + PagesData
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/drawer/menu_drawer_item.dart'; // tipos do drawer

// Corpo reutilizável (é este que usamos dentro do MenuListPage)
class HomeBody extends StatelessWidget {
  const HomeBody({super.key, this.onSelect});
  final void Function(MenuItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        const _SoftBubbles(),
        BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            final user = state.current;
            return LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final isWide = w >= 1080;
                final maxContentW = isWide ? 1080.0 : w;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentW),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SafeArea(top: true, child: _HeroHeader(user: user)),
                          const SizedBox(height: 24),
                          _ThemedActionsGrid(onSelect: onSelect, user: user),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user});
  final UserData? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Colors.blue.shade900;

    return Column(
      children: [
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logos/siged/siged.png',
                height: 88,
                width: 88,
                fit: BoxFit.contain,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SiGed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema Integrado de Planejamento e Gestão de Dados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent.withOpacity(.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (user?.name != null && user!.name!.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PopUpPhotoMenu(),
              const SizedBox(width: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Text(
                  'Olá, ${user!.name}!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ThemedActionsGrid extends StatelessWidget {
  const _ThemedActionsGrid({this.onSelect, required this.user});
  final void Function(MenuItem item)? onSelect;
  final UserData? user;

  bool _can(UserData? u, String module) {
    if (u == null) return false;
    return perms.userCanModule(user: u, module: module, action: 'read');
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    // ---- 1) Constrói seções dinâmicas a partir do PagesData ----
    final sections = <_SectionSpec>[
      _fromPagesGroup('PAINÉIS', PagesData.panelDashboard, user!, _can),
      _fromPagesGroup('PROCESSOS', PagesData.drawerDocuments, user!, _can),
      _fromPagesGroup('SETORES', PagesData.drawerDepartments, user!, _can),
      _fromPagesGroup('ATIVOS', PagesData.drawerActives, user!, _can),
      _fromPagesGroup('JURÍDICO', PagesData.crmLegal, user!, _can),
    ].where((s) => s.items.isNotEmpty).toList();

    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: _GlassCard(
          child: Column(
            children: const [
              Icon(Icons.lock_outline, size: 36, color: Colors.black54),
              SizedBox(height: 12),
              Text('Nenhum módulo disponível'),
              SizedBox(height: 6),
              Text(
                'Peça a um administrador para habilitar seus acessos.\nVocê verá aqui apenas os módulos permitidos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ---- 2) Renderiza seções ----
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _SectionGrid(
            title: sections[i].title,
            items: sections[i].items,
            onSelect: onSelect,
          ),
        ],
      ],
    );
  }

  // Constrói uma seção (_SectionSpec) a partir de um grupo de MenuDrawerItemModel do PagesData
  _SectionSpec _fromPagesGroup(
      String title,
      List<MenuDrawerItemModel> groups,
      UserData user,
      bool Function(UserData?, String) can,
      ) {
    final items = <_ActionItem>[];

    for (final group in groups) {
      for (final sub in group.subItems) {
        if (!can(user, sub.permissionModule)) continue;
        // usa ícone específico do card se existir; senão, herda do grupo
        final iconForCard = sub.homeIcon ?? group.icon;

        items.add(
          _ActionItem(
            icon: iconForCard,
            title: sub.label,
            subtitle: _subtitleForModule(sub.permissionModule),
            color: _colorForModule(sub.permissionModule),
            item: sub.menuItem,
            moduleKey: sub.permissionModule,
          ),
        );
      }
    }

    return _SectionSpec(title: title, items: items);
  }

  // Subtítulo opcional por prefixo do módulo (ajuste livre)
  String _subtitleForModule(String module) {
    if (module.startsWith('overview-')) return 'Indicadores e resumos';
    if (module.startsWith('specific-')) return 'KPIs e análises por contrato';
    if (module.startsWith('process-')) return 'Fluxos e registros de processo';
    if (module.startsWith('operation-')) return 'Execução e acompanhamento';
    if (module.startsWith('planning-')) return 'Planejamento e cadastros';
    if (module.startsWith('traffic-')) return 'Sinistros e infrações';
    if (module.startsWith('financial-')) return 'Pagamentos e empreendimentos';
    if (module.startsWith('active-')) return 'Malha e levantamentos';
    if (module.startsWith('crm-')) return 'Pipeline e relacionamento';
    return 'Acesso autorizado';
  }

  // Paleta por prefixo + fallback determinístico
  Color _colorForModule(String module) {
    const p = {
      'overview-': Color(0xFF2563EB),
      'specific-': Color(0xFF1D4ED8),
      'process-': Color(0xFF0EA5E9),
      'operation-': Color(0xFF059669),
      'planning-': Color(0xFF1E40AF),
      'traffic-': Color(0xFFEA580C),
      'financial-': Color(0xFF0D9488),
      'active-': Color(0xFF334155),
      'crm-': Color(0xFF800020), // jurídico (bordô)
    };

    for (final k in p.keys) {
      if (module.startsWith(k)) return p[k]!;
    }
    // Fallback: cor baseada em hash do módulo (estável)
    final hash = module.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.50, 0.50).toColor();
  }
}

class _SectionSpec {
  final String title;
  final List<_ActionItem> items;
  _SectionSpec({required this.title, required this.items});
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid(
      {required this.title, required this.items, required this.onSelect});
  final String title;
  final List<_ActionItem> items;
  final void Function(MenuItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.blueGrey.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
              color: titleColor,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            int cross = 1;
            if (w >= 1100) cross = 3;
            else if (w >= 740) cross = 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 16 / 7,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return _ActionCard(
                  item: a,
                  onTap: () => onSelect?.call(a.item),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final MenuItem item;
  final String moduleKey;
  _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.item,
    required this.moduleKey,
  });
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item, required this.onTap});
  final _ActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: item.color.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, size: 28, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.blueGrey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.black38),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
        backgroundBlendMode: BlendMode.screen,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

class _SoftBubbles extends StatelessWidget {
  const _SoftBubbles();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
              top: -60,
              left: -40,
              child: _bubble(const Color(0xFF60A5FA).withOpacity(.18), 220)),
          Positioned(
              bottom: -50,
              right: -30,
              child: _bubble(const Color(0xFF34D399).withOpacity(.16), 200)),
          Positioned(
              top: 220,
              right: -60,
              child: _bubble(const Color(0xFFFBBF24).withOpacity(.14), 160)),
          Positioned(
              bottom: 180,
              left: -50,
              child: _bubble(const Color(0xFFF472B6).withOpacity(.14), 140)),
        ],
      ),
    );
  }

  Widget _bubble(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.5), blurRadius: 60, spreadRadius: 10)
        ],
      ),
    );
  }
}
