// lib/screens/modules/actives/roads/records/list_roads_acronym.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/screens/modules/actives/roads/records/active_roads_table.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);
typedef RoadSortCallback = void Function(int columnIndex, bool ascending);

class ListRoadAcronym extends StatefulWidget {
  const ListRoadAcronym({
    super.key,
    required this.title,
    required this.items,
    required this.constraints,
    required this.onTapItem,
    required this.onDelete,
    required this.onExpansionChanged,
    required this.onSort,
    this.initiallyExpanded = false,
    this.sortColumnIndex,
    this.isAscending = true,
  });

  final String title;
  final List<ActiveRoadsData> items;
  final BoxConstraints constraints;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;
  final ValueChanged<bool> onExpansionChanged;

  final RoadSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

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

  @override
  void didUpdateWidget(covariant ListRoadAcronym oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  void _handleExpansionChanged(bool open) {
    setState(() {
      _isExpanded = open;
    });

    widget.onExpansionChanged(open);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final totalKm = ActiveRoadsData.sumExtension(widget.items);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey<String>('tile_road_${widget.title}'),
          initiallyExpanded: widget.initiallyExpanded,
          maintainState: true,
          onExpansionChanged: _handleExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF091D68).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFF091D68),
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  'Rodovia ${widget.title}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_fmtNum(totalKm, maxDecimals: 3)} km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '$total sub-trecho${total == 1 ? '' : 's'} encontrado${total == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF091D68).withValues(alpha: 0.12),
                ),
                child: Text(
                  '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF091D68),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
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
                sortColumnIndex: widget.sortColumnIndex,
                isAscending: widget.isAscending,
                onSort: widget.onSort,
              ),
          ],
        ),
      ),
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