import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/screens/modules/actives/roads/records/active_roads_table.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);

class ListRoadAcronym extends StatefulWidget {
  const ListRoadAcronym({
    super.key,
    required this.title,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<ActiveRoadsData> items;
  final BoxConstraints constraints;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;
  final bool initiallyExpanded;

  @override
  State<ListRoadAcronym> createState() => _ListRoadAcronymState();
}

class _ListRoadAcronymState extends State<ListRoadAcronym> {
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
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final totalKm = ActiveRoadsData.sumExtension(widget.items);

    return ExpansionTile(
      key: ValueKey('tile_road_${widget.title}'),
      initiallyExpanded: widget.initiallyExpanded,
      maintainState: true,
      onExpansionChanged: _handleExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Row(
        children: [
          Text(
            'Rodovia ${widget.title}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '• ${_fmtNum(totalKm, maxDecimals: 3)} km',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.12),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
      children: [
        if (_isExpanded)
          ListRoadsTable(
            items: widget.items,
            constraints: widget.constraints,
            onTapItem: widget.onTapItem,
            onDelete: widget.onDelete,
          ),
      ],
    );
  }
}

String _fmtNum(num? v, {int maxDecimals = 1}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}