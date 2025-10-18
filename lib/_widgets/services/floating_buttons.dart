// lib/_widgets/map/geo_json_actions_buttons.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/buttons/button_flutuante_hover.dart';

import '../../_services/geoJson/fix_jumps_between_points.dart';

// 🔔 Notificações centralizadas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class GeoJsonActionsButtons extends StatefulWidget {
  const GeoJsonActionsButtons({
    super.key,
    required this.onImportGeoJson,
    required this.onDeleteCollection,
    required this.onCheckDistances,
    required this.collectionPath,
    this.spacing = 12,
    this.initiallyExpanded = true,
    this.position = const GeoJsonActionsPosition.bottomLeft(),
  });

  /// Abrir seletor e importar GeoJSON (LineString/MultiLineString)
  final void Function(BuildContext context) onImportGeoJson;

  /// Apagar a coleção (confirmar do lado de fora, se quiser)
  final VoidCallback onDeleteCollection;

  /// Checar saltos sem corrigir
  final VoidCallback onCheckDistances;

  /// Caminho da coleção (ex.: 'actives_railways' ou 'actives_roads')
  final String collectionPath;

  /// Espaçamento vertical entre botões
  final double spacing;

  /// Começa aberto/fechado
  final bool initiallyExpanded;

  /// Onde ancorar (bottomLeft, bottomRight, topLeft, topRight)
  final GeoJsonActionsPosition position;

  @override
  State<GeoJsonActionsButtons> createState() => _GeoJsonActionsButtonsState();
}

class _GeoJsonActionsButtonsState extends State<GeoJsonActionsButtons>
    with TickerProviderStateMixin {
  late bool _expanded;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final buttonsExpanded = <Widget>[
      ActionButton(
        icon: Icons.upload,
        label: 'Enviar Polylines',
        background: Colors.blue.withOpacity(0.18),
        borderColor: Colors.blue,
        highlightColor: Colors.blue,
        onTap: () => widget.onImportGeoJson(context),
      ),
      ActionButton(
        icon: Icons.restore_from_trash_rounded,
        label: 'Deletar Polylines',
        background: Colors.red.withOpacity(0.18),
        borderColor: Colors.red,
        highlightColor: Colors.red,
        onTap: widget.onDeleteCollection,
      ),
      ActionButton(
        icon: Icons.alt_route,
        label: 'Verificar Saltos',
        background: Colors.orange.withOpacity(0.18),
        borderColor: Colors.orange,
        highlightColor: Colors.orange,
        onTap: widget.onCheckDistances,
      ),
      ActionButton(
        icon: Icons.auto_fix_high,
        label: _busy ? 'Processando…' : 'Verificar & Corrigir',
        background: Colors.green.withOpacity(0.18),
        borderColor: Colors.green,
        highlightColor: Colors.green,
        onTap: _busy ? (){} : () async {
          setState(() => _busy = true);
          _notify('Verificando e corrigindo saltos…', type: AppNotificationType.info);
          try {
            await fixJumpsBetweenPoints(
              collectionPath: widget.collectionPath,
              maxJumpKm: 2.0,
            );
            _notify('Verificação & correção concluídas.', type: AppNotificationType.success);
          } catch (e) {
            _notify('Falha ao verificar/corrigir', subtitle: '$e', type: AppNotificationType.error);
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        },
      ),
    ];

    final toggle = ToggleButton(expanded: _expanded, onTap: _toggle);

    final children = _expanded
        ? [
      ..._withSpacing(buttonsExpanded, widget.spacing),
      SizedBox(height: widget.spacing),
      toggle,
    ]
        : [
      // quando recolhido, mostra só o toggle
      toggle,
    ];

    final pos = widget.position;

    return Positioned(
      left: pos.left,
      right: pos.right,
      top: pos.top,
      bottom: pos.bottom,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: pos.alignment,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: pos.crossAxis,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }

  void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        type: type,
      ),
    );
  }
}

/// Botão de ação com o mesmo “look & feel” do ScheduleMenuButtons
class ActionButton extends StatelessWidget {
  const ActionButton({super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.borderColor,
    required this.highlightColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color borderColor;
  final Color highlightColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: highlightColor.withOpacity(0.20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BotaoFlutuanteHover(
          icon: icon,
          label: label,
          color: background,
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// Toggle (abrir/fechar), mesmo componente visual do menu de serviços
class ToggleButton extends StatelessWidget {
  const ToggleButton({super.key, required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BotaoFlutuanteHover(
      icon: expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
      label: expanded ? 'Recolher' : 'Ações',
      color: Colors.black.withOpacity(0.12),
      onPressed: onTap,
    );
  }
}

/// Helper para posicionamento flexível (cantos)
class GeoJsonActionsPosition {
  final double? left, right, top, bottom;
  final Alignment alignment;
  final CrossAxisAlignment crossAxis;

  const GeoJsonActionsPosition({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.alignment,
    required this.crossAxis,
  });

  const GeoJsonActionsPosition.bottomLeft({
    double left = 30,
    double bottom = 30,
  })  : left = left,
        right = null,
        top = null,
        bottom = bottom,
        alignment = Alignment.bottomLeft,
        crossAxis = CrossAxisAlignment.start;

  const GeoJsonActionsPosition.bottomRight({
    double right = 30,
    double bottom = 30,
  })  : left = null,
        right = right,
        top = null,
        bottom = bottom,
        alignment = Alignment.bottomRight,
        crossAxis = CrossAxisAlignment.end;

  const GeoJsonActionsPosition.topLeft({
    double left = 30,
    double top = 30,
  })  : left = left,
        right = null,
        top = top,
        bottom = null,
        alignment = Alignment.topLeft,
        crossAxis = CrossAxisAlignment.start;

  const GeoJsonActionsPosition.topRight({
    double right = 30,
    double top = 30,
  })  : left = null,
        right = right,
        top = top,
        bottom = null,
        alignment = Alignment.topRight,
        crossAxis = CrossAxisAlignment.end;
}
