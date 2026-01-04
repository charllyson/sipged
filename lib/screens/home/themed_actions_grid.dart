import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:siged/screens/home/action_card.dart';
import 'package:siged/screens/home/action_item.dart';
import 'package:siged/screens/home/section_spec.dart';

import 'glass_card.dart';


class ThemedActionsGrid extends StatelessWidget {
  const ThemedActionsGrid({super.key, this.onSelect, required this.user});
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
    final sections = <SectionSpec>[
      _fromPagesGroup('PAINÉIS', PagesData.panelDashboard, user!, _can),
      _fromPagesGroup('PROCESSOS', PagesData.drawerDocuments, user!, _can),
      _fromPagesGroup('SETORES', PagesData.drawerDepartments, user!, _can),
      _fromPagesGroup('ATIVOS', PagesData.drawerActives, user!, _can),
      _fromPagesGroup('JURÍDICO', PagesData.crmLegal, user!, _can),
    ].where((s) => s.items.isNotEmpty).toList();

    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: GlassCard(
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
          SectionGrid(
            title: sections[i].title,
            items: sections[i].items,
            onSelect: onSelect,
          ),
        ],
      ],
    );
  }

  // Constrói uma seção (_SectionSpec) a partir de um grupo de MenuDrawerItemModel do PagesData
  SectionSpec _fromPagesGroup(
      String title,
      List<MenuDrawerItemModel> groups,
      UserData user,
      bool Function(UserData?, String) can,
      ) {
    final items = <ActionItem>[];

    for (final group in groups) {
      for (final sub in group.subItems) {
        if (!can(user, sub.permissionModule)) continue;
        // usa ícone específico do card se existir; senão, herda do grupo
        final iconForCard = sub.homeIcon ?? group.icon;

        items.add(
          ActionItem(
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

    return SectionSpec(title: title, items: items);
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