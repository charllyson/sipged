// lib/screens/sectors/actives/oaes/list_oaes_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_data.dart';
import 'list_oaes_status.dart';

/// Callback para clique em uma OAE.
typedef OaeTapCallback = void Function(ActiveOaesData oae);

/// Callback para exclusão de uma OAE (recebe apenas o id).
typedef OaeDeleteCallback = void Function(String oaeId);

/// Helper para mapear nota -> cor/label
class OaeScoreHelper {
  static const _prefsExpandedKey = 'oaes_expanded_score_keys';

  /// Normaliza o score double em int [0..5], ou -1 para "sem nota"
  static int normalizeScore(double? score) {
    if (score == null) return -1;
    final v = score.round();
    if (v < 0 || v > 5) return -1;
    return v;
  }

  /// Carrega do SharedPreferences quais grupos de nota estavam expandidos
  static Future<Set<int>> loadExpandedScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsExpandedKey) ?? const <String>[];
      return raw.map(int.parse).toSet();
    } catch (_) {
      return <int>{};
    }
  }

  /// Salva no SharedPreferences os grupos de nota expandidos
  static Future<void> saveExpandedScores(Set<int> scores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsExpandedKey,
        scores.map((e) => e.toString()).toList(),
      );
    } catch (_) {
      // silencioso
    }
  }
}

class ListOaesPage extends StatefulWidget {
  const ListOaesPage({
    super.key,
    required this.oaes,
    required this.onTapItem,
    required this.onDelete,
  });

  /// Lista completa de OAEs já carregadas do Cubit.
  final List<ActiveOaesData> oaes;

  /// Clique na linha (para selecionar no formulário, por exemplo).
  final OaeTapCallback onTapItem;

  /// Exclusão de OAE (recebe apenas o id).
  final OaeDeleteCallback onDelete;

  @override
  State<ListOaesPage> createState() => _ListOaesPageState();
}

class _ListOaesPageState extends State<ListOaesPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';

  /// Conjunto de notas expandidas (0..5, -1 para "sem nota").
  final Set<int> _expandedScores = <int>{};

  @override
  void initState() {
    super.initState();
    OaeScoreHelper.loadExpandedScores().then((set) {
      if (!mounted) return;
      setState(() {
        _expandedScores
          ..clear()
          ..addAll(set);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleExpanded(int scoreKey, bool open) {
    setState(() {
      if (open) {
        _expandedScores.add(scoreKey);
      } else {
        _expandedScores.remove(scoreKey);
      }
    });
    OaeScoreHelper.saveExpandedScores(_expandedScores);
  }

  /// Aplica filtro simples por texto (identificação, região, rodovia, empresa).
  List<ActiveOaesData> _applySearch(List<ActiveOaesData> base) {
    if (_search.isEmpty) return base;
    return base.where((o) {
      final id = (o.identificationName ?? '').toUpperCase();
      final region = (o.region ?? '').toUpperCase();
      final road = (o.road ?? '').toUpperCase();
      final company = (o.companyBuild ?? '').toUpperCase();
      return id.contains(_search) ||
          region.contains(_search) ||
          road.contains(_search) ||
          company.contains(_search);
    }).toList(growable: false);
  }

  /// Agrupa por nota normalizada.
  Map<int, List<ActiveOaesData>> _groupByScore(List<ActiveOaesData> list) {
    final map = <int, List<ActiveOaesData>>{};
    for (final o in list) {
      final scoreKey = OaeScoreHelper.normalizeScore(o.score);
      map.putIfAbsent(scoreKey, () => <ActiveOaesData>[]).add(o);
    }

    // ordena cada grupo por identificação
    for (final e in map.entries) {
      e.value.sort(
            (a, b) =>
            (a.identificationName ?? '')
                .toUpperCase()
                .compareTo((b.identificationName ?? '').toUpperCase()),
      );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applySearch(widget.oaes);
    final byScore = _groupByScore(filtered);
    const scoreOrder = <int>[1, 2, 3, 4, 5, 0, -1];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: scoreOrder.map((scoreKey) {
            final items = byScore[scoreKey] ?? const <ActiveOaesData>[];
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            final label = ActiveOaesData.getLabelByNota(scoreKey);
            final color = ActiveOaesData.getColorByNota(
              scoreKey >= 0 ? scoreKey.toDouble() : -1,
            );

            return ListOaesStatus(
              title: label,
              scoreKey: scoreKey,
              color: color,
              items: items,
              constraints: constraints,
              initiallyExpanded: _expandedScores.contains(scoreKey),
              onExpansionChanged: (open) => _toggleExpanded(scoreKey, open),
              onTapItem: widget.onTapItem,
              onDelete: widget.onDelete,
            );
          }).toList(),
        );
      },
    );
  }
}
