import 'package:flutter/material.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_data.dart';
import 'list_oaes_table.dart';

typedef OaeTapCallback = void Function(ActiveOaesData oae);
typedef OaeDeleteCallback = void Function(String oaeId);

class ListOaesStatus extends StatefulWidget {
  const ListOaesStatus({
    super.key,
    required this.title,
    required this.scoreKey,
    required this.color,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  /// Label do grupo (ex.: "Crítica", "Sem problemas"...)
  final String title;

  /// Nota normalizada (0..5, -1 para "sem nota")
  final int scoreKey;

  /// Cor do grupo (badge/chip)
  final Color color;

  /// Lista de OAEs desse grupo
  final List<ActiveOaesData> items;

  final BoxConstraints constraints;

  final OaeTapCallback onTapItem;
  final OaeDeleteCallback onDelete;

  /// Estado inicial (carregado do SharedPreferences)
  final bool initiallyExpanded;

  /// Callback para o pai (ListOaesPage) persistir no SharedPreferences
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ListOaesStatus> createState() => _ListOaesStatusState();
}

class _ListOaesStatusState extends State<ListOaesStatus> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _handleExpansionChanged(bool open) {
    setState(() {
      _isExpanded = open;
    });
    widget.onExpansionChanged?.call(open);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;

    return ExpansionTile(
      key: ValueKey('tile_score_${widget.scoreKey}'),
      initiallyExpanded: widget.initiallyExpanded,
      maintainState: true,
      onExpansionChanged: _handleExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.color.withOpacity(0.12),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
      children: [
        // 🔥 SÓ constrói a tabela quando estiver expandido
        if (_isExpanded)
          ListOaesTable(
            items: widget.items,
            constraints: widget.constraints,
            onTapItem: widget.onTapItem,
            onDelete: widget.onDelete,
          ),
      ],
    );
  }
}
