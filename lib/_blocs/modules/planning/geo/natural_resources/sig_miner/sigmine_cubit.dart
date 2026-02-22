import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sigmine_state.dart';
import 'sigmine_data.dart';
import 'sigmine_repository.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

class SigMineCubit extends Cubit<SigMineState> {
  final SigMineRepository _repo;

  SigMineCubit({
    SigMineRepository? repository,
    String? initialUF,
  })  : _repo = repository ?? SigMineRepository(),
        super(
        SigMineState.initial(
          initialUF: initialUF ?? (SetupData.selectedUF ?? 'AL'),
        ),
      );

  // Paleta base (estável) para alocação incremental
  static const List<Color> _basePalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
  ];

  /// Normaliza substância para chave estável (sem acento, upper, trim)
  String normalizeMinerio(String? s) {
    return removeDiacritics((s ?? 'INDEFINIDO'))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  /// Normaliza processo para comparação interna
  String _normalizeProcess(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();

  /// Exposto para UI (mesma paleta para mapa + gráfico).
  /// Aceita nome original ou já normalizado.
  Color getColorForMinerio(String nomeOriginalOuNormalizado) {
    final normalized = normalizeMinerio(nomeOriginalOuNormalizado);
    final existing = state.colorMap[normalized];
    if (existing != null) return existing;

    // fallback defensivo (se vier algo novo)
    final idx = state.colorMap.length % _basePalette.length;
    return _basePalette[idx];
  }

  /// Inicialização (pode ser chamada na Page)
  Future<void> warmup() async {
    // garante que carrega a UF inicial
    await loadUF(state.selectedUF);
  }

  Future<void> loadUF(String uf) async {
    emit(
      state.copyWith(
        status: SigMineStatus.loading,
        features: const [],
        mineriosAtivos: const {},
        colorMap: const {},
        minerioCounts: const {},
        clearSelectedFeature: true,
        selectedUF: uf,
        clearError: true,
      ),
    );

    // persiste UF global (se você quiser manter essa convenção)
    SetupData.selectedUF = uf;

    try {
      final feats = await _repo.fetchByUF(uf);

      // Set de minérios normalizados
      final ativos = feats
          .map((f) => normalizeMinerio(f.substancia))
          .toSet();

      // PRÉ-SEMEIA a paleta numa ordem determinística (alfabética)
      final ordered = ativos.toList()..sort();
      final colorMap = <String, Color>{};
      for (int i = 0; i < ordered.length; i++) {
        colorMap[ordered[i]] =
        _basePalette[i % _basePalette.length];
      }

      // Conta por minério (global da UF)
      final counts = <String, int>{};
      for (final f in feats) {
        final key = normalizeMinerio(f.substancia);
        counts[key] = (counts[key] ?? 0) + 1;
      }

      emit(
        state.copyWith(
          status: SigMineStatus.loaded,
          features: feats,
          mineriosAtivos: ativos, // todos ativos inicialmente
          colorMap: colorMap,
          minerioCounts: counts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SigMineStatus.error,
          errorMessage: 'Erro ao carregar $uf: $e',
        ),
      );
    }
  }

  void togglePanel() {
    emit(state.copyWith(showPanel: !state.showPanel));
  }

  /// Seleciona apenas 1 minério, ou volta para "todos" se clicar de novo.
  /// [nomeNormalizado] pode vir já normalizado do painel/mapa.
  void selectSingleMinerio(String nomeNormalizado) {
    if (state.features.isEmpty) return;

    final allMinerios = state.features
        .map((f) => normalizeMinerio(f.substancia))
        .toSet();

    final normalized = normalizeMinerio(nomeNormalizado);

    if (state.mineriosAtivos.length == 1 &&
        state.mineriosAtivos.contains(normalized)) {
      // se já está filtrando por um e clicar de novo -> mostra todos
      emit(
        state.copyWith(
          mineriosAtivos: allMinerios,
          clearSelectedFeature: true,
        ),
      );
    } else {
      // filtra por apenas 1
      emit(
        state.copyWith(
          mineriosAtivos: {normalized},
          clearSelectedFeature: true,
        ),
      );
    }
  }

  /// Abre detalhes diretamente pela feature (Mapa)
  void openDetailsByFeature(SigMineData feature) {
    emit(state.copyWith(selectedFeature: feature));
  }

  /// Abre detalhes pela string de processo (tooltip, painel, etc.)
  void openDetailsByProcess(String processoRaw) {
    if (state.features.isEmpty) return;

    final key = _normalizeProcess(processoRaw);

    SigMineData? candidate;

    // match exato
    for (final f in state.features) {
      final p = _normalizeProcess(f.processo);
      if (p == key) {
        candidate = f;
        break;
      }
    }

    // fallback startsWith
    candidate ??= state.features.firstWhere(
          (f) => _normalizeProcess(f.processo).startsWith(key),
      orElse: () => state.features.first,
    );

    emit(state.copyWith(selectedFeature: candidate));
  }

  void closeDetails() {
    emit(state.copyWith(clearSelectedFeature: true));
  }

  /// Calcula os dados derivados para painel + mapa.
  ///
  /// Toda lógica pesada de filtragem/contagem fica aqui,
  /// deixando as telas praticamente burras.
  SigMineDerived buildDerived({required bool sigmineAtivo}) {
    // 1) camada desligada => nada visível
    if (!sigmineAtivo || state.features.isEmpty) {
      return const SigMineDerived(
        visibleFeatures: [],
        mineriosOrdenados: [],
        contagensVisiveis: [],
        selectedMinerioIndex: null,
      );
    }

    // 2) aplica filtro por minério
    final List<SigMineData> visiveis;
    if (state.mineriosAtivos.isEmpty) {
      visiveis = state.features;
    } else {
      visiveis = state.features.where((f) {
        final chave = normalizeMinerio(f.substancia);
        return state.mineriosAtivos.contains(chave);
      }).toList();
    }

    // 3) recontagem com base nas features visíveis
    final counts = <String, int>{};
    for (final f in visiveis) {
      final key = normalizeMinerio(f.substancia);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final mineriosOrdenados = counts.keys.toList()..sort();
    final contagens =
    mineriosOrdenados.map((k) => counts[k] ?? 0).toList();

    // 4) índice de seleção (se tiver exatamente 1 minério ativo)
    int? selectedIndex;
    if (state.mineriosAtivos.length == 1) {
      final unico = state.mineriosAtivos.first;
      final i = mineriosOrdenados.indexOf(unico);
      if (i >= 0) selectedIndex = i;
    }

    return SigMineDerived(
      visibleFeatures: visiveis,
      mineriosOrdenados: mineriosOrdenados,
      contagensVisiveis: contagens,
      selectedMinerioIndex: selectedIndex,
    );
  }
}
