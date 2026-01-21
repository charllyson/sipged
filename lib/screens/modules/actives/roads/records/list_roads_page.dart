import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/actives/roads/active_roads_data.dart';
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

  Map<String, List<ActiveRoadsData>> _groupByAcronym(
      List<ActiveRoadsData> list) {
    final map = <String, List<ActiveRoadsData>>{};
    for (final r in list) {
      final key = (r.acronym ?? 'SEM SIGLA').trim().toUpperCase();
      map.putIfAbsent(key, () => <ActiveRoadsData>[]).add(r);
    }

    // ordena internamente por UF + código
    for (final e in map.entries) {
      e.value.sort(
            (a, b) =>
            ('${a.uf ?? ''}${a.roadCode ?? ''}')
                .toUpperCase()
                .compareTo(
              ('${b.uf ?? ''}${b.roadCode ?? ''}').toUpperCase(),
            ),
      );
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (roads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma rodovia cadastrada.'),
      );
    }

    final grouped = _groupByAcronym(roads);
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
