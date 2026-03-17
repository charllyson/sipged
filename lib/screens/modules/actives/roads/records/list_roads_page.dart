import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'list_roads_acronym.dart';

typedef RoadTapCallback = void Function(ActiveRoadsData road);
typedef RoadDeleteCallback = void Function(String roadId);

class ListRoadsPage extends StatelessWidget {
  const ListRoadsPage({
    super.key,
    required this.roads,
    required this.onTapItem,
    required this.onDelete,
  });

  final List<ActiveRoadsData> roads;
  final RoadTapCallback onTapItem;
  final RoadDeleteCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (roads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma rodovia cadastrada.'),
      );
    }

    final grouped = ActiveRoadsData.groupByAcronym(roads);
    final keys = grouped.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: keys.map((acronymKey) {
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
            );
          }).toList(),
        );
      },
    );
  }
}