// lib/screens/modules/actives/oaes/records/list_oaes_page.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'list_oaes_status.dart';

typedef OaeTapCallback = void Function(ActiveOaesData oae);
typedef OaeDeleteCallback = void Function(String oaeId);
typedef OaeExpandedGetter = bool Function(String key);
typedef OaeExpansionCallback = void Function(String key, bool open);
typedef OaeSortCallback = void Function(int columnIndex, bool ascending);

class OaeScoreHelper {
  static int normalizeScore(double? score) {
    if (score == null) return -1;

    final value = score.round();

    if (value < 0 || value > 5) return -1;

    return value;
  }

  static String keyOf(int score) {
    return 'SCORE_$score';
  }

  static List<int> get scoreOrder {
    return const <int>[1, 2, 3, 4, 5, 0, -1];
  }
}

class ListOaesPage extends StatelessWidget {
  const ListOaesPage({
    super.key,
    required this.oaes,
    required this.onTapItem,
    required this.onDelete,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onSort,
    this.sortColumnIndex,
    this.isAscending = true,
  });

  final List<ActiveOaesData> oaes;
  final OaeTapCallback onTapItem;
  final OaeDeleteCallback onDelete;

  final OaeExpandedGetter isExpanded;
  final OaeExpansionCallback onExpansionChanged;

  final OaeSortCallback onSort;
  final int? sortColumnIndex;
  final bool isAscending;

  Map<int, List<ActiveOaesData>> _groupByScore(List<ActiveOaesData> list) {
    final map = <int, List<ActiveOaesData>>{};

    for (final oae in list) {
      final scoreKey = OaeScoreHelper.normalizeScore(oae.score);

      map.putIfAbsent(scoreKey, () => <ActiveOaesData>[]).add(oae);
    }

    return map;
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 42,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma OAE disponível',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Não há OAEs cadastradas ou compatíveis com a busca atual.',
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

  @override
  Widget build(BuildContext context) {
    if (oaes.isEmpty) {
      return _emptyState();
    }

    final grouped = _groupByScore(oaes);

    final visibleScoreKeys = OaeScoreHelper.scoreOrder.where((scoreKey) {
      final items = grouped[scoreKey] ?? const <ActiveOaesData>[];
      return items.isNotEmpty;
    }).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: visibleScoreKeys.length,
          itemBuilder: (context, index) {
            final scoreKey = visibleScoreKeys[index];
            final items = grouped[scoreKey] ?? const <ActiveOaesData>[];

            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            final label = ActiveOaesData.getLabelByNota(scoreKey);
            final color = ActiveOaesData.getColorByNota(
              scoreKey >= 0 ? scoreKey.toDouble() : -1,
            );

            final expansionKey = OaeScoreHelper.keyOf(scoreKey);

            return ListOaesStatus(
              title: label,
              scoreKey: scoreKey,
              expansionKey: expansionKey,
              color: color,
              items: items,
              constraints: constraints,
              initiallyExpanded: isExpanded(expansionKey),
              onExpansionChanged: (open) {
                onExpansionChanged(expansionKey, open);
              },
              onTapItem: onTapItem,
              onDelete: onDelete,
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