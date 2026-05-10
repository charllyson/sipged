// lib/screens/modules/actives/roads/records/list_roads_page.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';

import 'list_roads_acronym.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);
typedef RoadExpandedGetter = bool Function(String key);
typedef RoadExpansionCallback = void Function(String key, bool open);
typedef RoadSortCallback = void Function(int columnIndex, bool ascending);

class ListRoadsPage extends StatelessWidget {
  const ListRoadsPage({
    super.key,
    required this.roads,
    required this.onTapItem,
    required this.onDelete,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onSort,
    this.sortColumnIndex,
    this.isAscending = true,
  });

  final List<ActiveRoadsData> roads;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;

  final RoadExpandedGetter isExpanded;
  final RoadExpansionCallback onExpansionChanged;

  final RoadSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

  @override
  Widget build(BuildContext context) {
    if (roads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 42,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma rodovia disponível',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Não há rodovias cadastradas ou compatíveis com a busca atual.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final grouped = ActiveRoadsData.groupByAcronym(roads);
    final keys = grouped.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final acronymKey = keys[index];
            final items = grouped[acronymKey] ?? const <ActiveRoadsData>[];

            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            return ListRoadAcronym(
              title: acronymKey,
              items: items,
              constraints: constraints,
              onTapItem: onTapItem,
              onDelete: onDelete,
              initiallyExpanded: isExpanded(acronymKey),
              onExpansionChanged: (open) {
                onExpansionChanged(acronymKey, open);
              },
              sortColumnIndex: sortColumnIndex,
              isAscending: isAscending,
              onSort: onSort,
            );
          },
        );
      },
    );
  }
}