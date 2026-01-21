import 'package:flutter/material.dart';
import 'package:siged/screens/modules/planning/geo/layer/layers_geo.dart';

/// Drawer lateral direito com a lista de camadas.
///
/// - [layers]: lista de camadas/grupos em árvore.
/// - [activeLayerIds]: IDs das camadas atualmente ativas (checkbox marcado).
/// - [onToggleLayer]: callback chamado ao marcar/desmarcar um checkbox.
/// - [onConnectLayer]: callback chamado ao clicar no ícone de corrente
///   de uma camada folha (não pasta).
/// - [hasDbByLayer]: mapa {layerId: true/false} indicando se existe dado no banco
///   para pintar a correntinha verde.
class LayersDrawer extends StatefulWidget {
  final List<LayersGeo> layers;
  final Set<String> activeLayerIds;
  final void Function(String id, bool isActive) onToggleLayer;

  /// Callback disparado ao clicar no botão de corrente (camada folha).
  final void Function(String id)? onConnectLayer;

  /// ✅ Status vindo do Firestore: id -> tem dados
  final Map<String, bool> hasDbByLayer;

  /// (Opcional) se quiser esconder a correntinha em layers que não suportam import.
  /// Se null, mostra correntinha para todas as folhas quando onConnectLayer != null.
  final bool Function(String layerId)? supportsConnect;

  const LayersDrawer({
    super.key,
    required this.layers,
    required this.activeLayerIds,
    required this.onToggleLayer,
    this.onConnectLayer,
    this.hasDbByLayer = const {},
    this.supportsConnect,
  });

  @override
  State<LayersDrawer> createState() => _LayersDrawerState();
}

class _LayersDrawerState extends State<LayersDrawer> {
  /// Grupos/pastas atualmente expandidos.
  late Set<String> _expandedGroupIds;

  /// ID do item (camada ou pasta) selecionado visualmente.
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Começa com todos os grupos expandidos
    _expandedGroupIds = {
      for (final l in widget.layers)
        if (l.isGroup) l.id,
    };
  }

  @override
  void didUpdateWidget(covariant LayersDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedId != null) {
      final stillExists = _existsLayerWithId(widget.layers, _selectedId!);
      if (!stillExists) {
        _selectedId = null;
      }
    }
  }

  bool _existsLayerWithId(List<LayersGeo> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return true;
      if (n.isGroup && n.children.isNotEmpty) {
        if (_existsLayerWithId(n.children, id)) return true;
      }
    }
    return false;
  }

  void _toggleGroupExpand(String groupId) {
    setState(() {
      if (_expandedGroupIds.contains(groupId)) {
        _expandedGroupIds.remove(groupId);
      } else {
        _expandedGroupIds.add(groupId);
      }
    });
  }

  void _selectItem(String id) {
    setState(() {
      _selectedId = id;
    });
  }

  /// Retorna true se **todas** as camadas-filhas (folhas) do grupo estiverem ativas.
  bool _areAllChildrenActive(LayersGeo node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;
    for (final c in node.children) {
      if (!_areAllChildrenActive(c)) return false;
    }
    return true;
  }

  /// Retorna true se **alguma** camada-filha (folha) do grupo estiver ativa.
  bool _hasAnyChildActive(LayersGeo node) {
    if (!node.isGroup) {
      return widget.activeLayerIds.contains(node.id);
    }
    if (node.children.isEmpty) return false;
    for (final c in node.children) {
      if (_hasAnyChildActive(c)) return true;
    }
    return false;
  }

  /// Lista achatada com todas as camadas-folha de um grupo.
  List<LayersGeo> _flattenLeaves(LayersGeo node) {
    if (!node.isGroup) return [node];
    final list = <LayersGeo>[];
    for (final c in node.children) {
      list.addAll(_flattenLeaves(c));
    }
    return list;
  }

  bool _hasDb(String id) => widget.hasDbByLayer[id] == true;

  bool _supportsConnect(String layerId) {
    if (widget.onConnectLayer == null) return false;
    if (widget.supportsConnect != null) return widget.supportsConnect!(layerId);
    // padrão: se tem callback, permite para qualquer folha
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.layers),
              title: Text(
                'Camadas do mapa',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: _buildLayerList(
                  context,
                  widget.layers,
                  depth: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLayerList(
      BuildContext context,
      List<LayersGeo> entries, {
        required int depth,
      }) {
    final widgets = <Widget>[];

    for (final entry in entries) {
      if (entry.isGroup) {
        final isExpanded = _expandedGroupIds.contains(entry.id);
        widgets.add(_buildGroupRow(context, entry, depth, isExpanded));

        if (isExpanded && entry.children.isNotEmpty) {
          widgets.addAll(
            _buildLayerList(context, entry.children, depth: depth + 1),
          );
        }
      } else {
        widgets.add(_buildLayerRow(context, entry, depth));
      }
    }

    return widgets;
  }

  Widget _buildGroupRow(
      BuildContext context,
      LayersGeo group,
      int depth,
      bool isExpanded,
      ) {
    final isSelected = _selectedId == group.id;

    final allChildrenActive = _areAllChildrenActive(group);
    final anyChildActive = _hasAnyChildActive(group);

    // valor do checkbox:
    // true  -> todos filhos ativos
    // null  -> algum ativo, mas não todos (estado "-")
    // false -> nenhum ativo
    final bool? checkboxValue =
    allChildrenActive ? true : (anyChildActive ? null : false);

    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;
    final iconColor = isSelected ? Colors.white : Colors.grey.shade800;

    // Cor única para todos os checkboxes marcados
    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _selectItem(group.id), // só seleciona em azul
      child: Container(
        color: bgColor,
        height: 36,
        padding: EdgeInsets.only(
          left: 8.0 + depth * 16.0,
          right: 8.0,
        ),
        child: Row(
          children: [
            // Slot vazio para alinhar com o link dos itens folha
            const SizedBox(width: 40),

            // Checkbox do grupo → ativa/desativa TODAS as camadas filhas
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checkboxValue,
                tristate: true,
                onChanged: (v) {
                  // Regra: se clicar, define tudo ligado/desligado.
                  // - quando v == null, Flutter pode mandar null em alguns cenários,
                  //   então usamos o estado desejado:
                  final shouldEnable = !(allChildrenActive); // se já tá tudo ligado, desliga
                  final leaves = _flattenLeaves(group);
                  for (final leaf in leaves) {
                    widget.onToggleLayer(leaf.id, shouldEnable);
                  }
                },
                activeColor: primaryCheckboxColor,
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(width: 4),

            Icon(group.icon, size: 18, color: iconColor),
            const SizedBox(width: 8),

            Expanded(
              child: Text(
                group.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Setinha no final
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleGroupExpand(group.id),
              icon: Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerRow(
      BuildContext context,
      LayersGeo layer,
      int depth,
      ) {
    final isActive = widget.activeLayerIds.contains(layer.id);
    final isSelected = _selectedId == layer.id;

    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;

    final iconColor =
    isSelected ? Colors.white : (isActive ? layer.color : Colors.grey);

    final canConnect = _supportsConnect(layer.id);

    // ✅ cor da correntinha: verde se tem dado no banco
    final hasDb = _hasDb(layer.id);

    final linkIconColor = isSelected
        ? Colors.white
        : (hasDb ? Colors.blue : Colors.grey.shade300);

    // Cor única para todos os checkboxes marcados
    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _selectItem(layer.id),
      child: Container(
        color: bgColor,
        height: 36,
        padding: EdgeInsets.only(
          left: 8.0 + depth * 16.0,
          right: 8.0,
        ),
        child: Row(
          children: [
            // Slot para alinhar (grupo usa setinha; aqui é vazio)
            const SizedBox(width: 40),

            // Checkbox da camada (como era antes)
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isActive,
                onChanged: (v) => widget.onToggleLayer(layer.id, v ?? false),
                activeColor: primaryCheckboxColor,
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(width: 4),

            Icon(layer.icon, size: 18, color: iconColor),
            const SizedBox(width: 8),

            Expanded(
              child: Text(
                layer.title,
                style: TextStyle(color: textColor),
              ),
            ),

            // Botão de corrente (vínculo / serviço)
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: (!canConnect) ? null : () => widget.onConnectLayer!(layer.id),
              icon: Icon(hasDb ? Icons.table_view : Icons.link_off, color: linkIconColor),
              tooltip: hasDb ? 'Dados disponíveis no banco' : 'Sem dados no banco',
            ),
          ],
        ),
      ),
    );
  }
}
