// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart'; // MenuItem
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/user/user_data.dart';

// Corpo reutilizável (é este que usamos dentro do MenuListPage)
class HomeBody extends StatelessWidget {
  const HomeBody({super.key, this.onSelect});
  final void Function(MenuItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEEF2FF).withOpacity(.9),
                  const Color(0xFFE0F2FE).withOpacity(.6),
                ],
              ),
            ),
          ),
        ),
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
                          SafeArea(
                              top: true,
                              child: _HeroHeader(user: user)),
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
                Text('SiGed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema Integrado de Georreferenciamento e Gestão de Dados',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

    final panels = <_ActionItem>[
      _ActionItem(Icons.area_chart, 'Painel Geral', 'Indicadores e resumos',
          const Color(0xFF2563EB), MenuItem.overviewDashboard, 'overview-overview-dashboard'),
      _ActionItem(Icons.dashboard_customize, 'Planejamento Específico', 'KPIs do contrato',
          const Color(0xFF1D4ED8), MenuItem.specificDashboard, 'specific-overview-dashboard'),
    ];

    final processos = <_ActionItem>[
      _ActionItem(Icons.list_alt, 'Contratação', 'Editais/Contratos',
          const Color(0xFF0EA5E9), MenuItem.processHiringRecords, 'process-hiring-records'),
      _ActionItem(Icons.note_add, 'Aditivos', 'Termos e prazos',
          const Color(0xFFF59E0B), MenuItem.processAdditiveRecords, 'process-additive-records'),
      _ActionItem(Icons.receipt_long, 'Medições', 'Relatórios e pagamentos',
          const Color(0xFFDB2777), MenuItem.processMeasurementsRecords, 'process-measurements-records'),
      _ActionItem(Icons.task_alt, 'Vigências', 'Ordens e prazos',
          const Color(0xFF10B981), MenuItem.processValidityRecords, 'process-validity-records'),
      _ActionItem(Icons.bookmark_added_outlined, 'Apostilamentos', 'Registros complementares',
          const Color(0xFF8B5CF6), MenuItem.processApostillesRecords, 'process-apostilles-records'),
      _ActionItem(Icons.layers_outlined, 'Regularização de Terrenos', 'Processos fundiários',
          const Color(0xFF7C3AED), MenuItem.processLandRegularizationRecords, 'process-land-regularization-records'),
    ];

    final setores = <_ActionItem>[
      _ActionItem(Icons.timeline, 'Cronograma Físico', 'Obras rodoviárias',
          const Color(0xFF059669), MenuItem.operationMonitoringWork, 'operation-work-timeline'),
      _ActionItem(Icons.local_florist_outlined, 'Meio Ambiente', 'Gestão ambiental',
          const Color(0xFF16A34A), MenuItem.planningEnvironmentRecords, 'planning-environment-records'),
      _ActionItem(Icons.signpost_outlined, 'Faixa de Domínio', 'Direito de passagem',
          const Color(0xFF1E40AF), MenuItem.planningRightOfWayRecords, 'planning-rightWay-records'),
      _ActionItem(Icons.traffic, 'Trânsito', 'Sinistros e infrações',
          const Color(0xFFEA580C), MenuItem.trafficAccidentsDashboard, 'traffic-accidents-overview-dashboard'),
    ];

    final ativos = <_ActionItem>[
      _ActionItem(Icons.alt_route, 'Rodovias', 'Malha e cadastro',
          const Color(0xFF334155), MenuItem.activeRoadNetwork, 'active-road-network'),
      _ActionItem(Icons.car_repair, 'OAEs', 'Pontes e viadutos',
          const Color(0xFF64748B), MenuItem.activesOAEsNetwork, 'active-oaes-network'),
      _ActionItem(Icons.local_airport, 'Aeroportos', 'Malha aeroportuária',
          const Color(0xFF0D9488), MenuItem.activeAirportsNetwork, 'active-airports-network'),
      _ActionItem(Icons.train, 'Ferrovias', 'Malha ferroviária',
          const Color(0xFF1E293B), MenuItem.activeRailwaysNetwork, 'active-railways-network'),
      _ActionItem(Icons.directions_boat, 'Portos e Balsas', 'Malha portuária',
          const Color(0xFF0369A1), MenuItem.activePortsNetwork, 'active-ports-network'),
    ];

    List<_ActionItem> filter(List<_ActionItem> list) =>
        list.where((e) => _can(user, e.moduleKey)).toList();

    final panelsAllowed    = filter(panels);
    final processosAllowed = filter(processos);
    final setoresAllowed   = filter(setores);
    final ativosAllowed    = filter(ativos);

    final nothing = panelsAllowed.isEmpty &&
        processosAllowed.isEmpty &&
        setoresAllowed.isEmpty &&
        ativosAllowed.isEmpty;

    if (nothing) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (panelsAllowed.isNotEmpty)
          _SectionGrid(title: 'PAINÉIS', items: panelsAllowed, onSelect: onSelect),
        if (processosAllowed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionGrid(title: 'PROCESSOS', items: processosAllowed, onSelect: onSelect),
        ],
        if (setoresAllowed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionGrid(title: 'SETORES', items: setoresAllowed, onSelect: onSelect),
        ],
        if (ativosAllowed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionGrid(title: 'ATIVOS', items: ativosAllowed, onSelect: onSelect),
        ],
      ],
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.title, required this.items, required this.onSelect});
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
                fontWeight: FontWeight.w800, letterSpacing: .6, color: titleColor),
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
                  onTap: () {
                    if (onSelect != null) onSelect!(a.item); // navega
                  },
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
  _ActionItem(this.icon, this.title, this.subtitle, this.color, this.item, this.moduleKey);
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
                Text(item.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: .2, color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.subtitle,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black38),
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
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 22, offset: const Offset(0, 10)),
        ],
        backgroundBlendMode: BlendMode.screen,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: content),
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
          Positioned(top: -60, left: -40, child: _bubble(const Color(0xFF60A5FA).withOpacity(.18), 220)),
          Positioned(bottom: -50, right: -30, child: _bubble(const Color(0xFF34D399).withOpacity(.16), 200)),
          Positioned(top: 220, right: -60, child: _bubble(const Color(0xFFFBBF24).withOpacity(.14), 160)),
          Positioned(bottom: 180, left: -50, child: _bubble(const Color(0xFFF472B6).withOpacity(.14), 140)),
        ],
      ),
    );
  }
  Widget _bubble(Color color, double size) {
    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 60, spreadRadius: 10)],
      ),
    );
  }
}
