import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/cards/action/action_item.dart';
import 'package:sipged/_widgets/cards/glass/glass_card.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:sipged/screens/common/home/section_spec.dart';

class ThemedActionsGrid extends StatelessWidget {
  const ThemedActionsGrid({
    super.key,
    this.onSelect,
    required this.user,
  });

  final void Function(ModuleItem item)? onSelect;
  final UserData? user;

  bool _can(UserData? u, String module) {
    if (u == null) return false;
    return perms.userCanModule(user: u, module: module, action: 'read');
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final sections = ModuleData.homeGroups
        .map((group) => _fromGroup(group, user!))
        .where((s) => s.items.isNotEmpty)
        .toList();

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

  SectionSpec _fromGroup(MenuDrawerItemModule group, UserData user) {
    final items = <ActionItem>[];

    for (final sub in group.subItems) {
      if (!_can(user, sub.permissionModule)) continue;

      items.add(
        ActionItem(
          icon: sub.homeIcon ?? group.icon,
          title: sub.label,
          subtitle: sub.homeSubtitle ?? 'Acesso autorizado',
          color: sub.homeColor ?? _fallbackColor(sub.permissionModule),
          item: sub.menuItem,
          moduleKey: sub.permissionModule,
        ),
      );
    }

    return SectionSpec(title: group.label, items: items);
  }

  Color _fallbackColor(String module) {
    final hash = module.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.50, 0.50).toColor();
  }
}