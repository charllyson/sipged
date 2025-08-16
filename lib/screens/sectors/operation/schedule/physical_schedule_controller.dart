import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../_datas/sectors/operation/calculationMemory/calculation_memory_data.dart';
import 'dart:math' as math;
import '../../../../_utils/service_colors.dart';
import '../../../../_widgets/schedule/highway_class.dart';

/// Representa uma opção de serviço no menu
class ServiceOption {
  final String key;     // chave técnica (ex.: 'asfalto', 'base-sub-base', 'terraplenagem', 'geral' ...)
  final String label;   // rótulo mostrado (ex.: 'ASFALTO', 'BASE | SUB-BASE')
  final IconData icon;  // ícone para o botão
  final Color color;    // cor do botão / tarja

  const ServiceOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Controller do cronograma físico
class PhysicalScheduleController extends ChangeNotifier {
  PhysicalScheduleController({
    required this.firestore,
    required this.contractId,
    required List<HighwayClass> faixas,
    required double contractExtKm,
    String initialServico = 'geral',
  })  : _faixas = List<HighwayClass>.from(faixas),
        _servicoSelecionado = initialServico.toLowerCase(),
        _totalEstacas = ((contractExtKm * 1000) / 20).ceil() {

    // <-- garante que a lista NUNCA está vazia
    _availableServices.add(
      ServiceOption(
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ServiceColors.buttonColor('GERAL'),
      ),
    );
  }


  // --- deps / ids
  final FirebaseFirestore firestore;
  final String contractId;

  // --- malha
  List<HighwayClass> _faixas;
  int _totalEstacas;

  // --- dados de execução
  List<CalculationMemoryData> _execucoes = [];
  bool _isLoading = false;

  // --- serviços
  final List<ServiceOption> _availableServices = [];
  String _servicoSelecionado; // chave (lowercase) – 'geral' é especial

  // -------------------- getters --------------------
  bool get isLoading => _isLoading;
  List<CalculationMemoryData> get execucoes => _execucoes;
  int get totalEstacas => _totalEstacas;

  List<String> get faixaLabels => _faixas.map((f) => f.label).toList();
  List<HighwayClass> get faixas => List.unmodifiable(_faixas);

  List<ServiceOption> get availableServices => List.unmodifiable(_availableServices);

  String get servicoSelecionado => _servicoSelecionado;
  ServiceOption get currentOption {
    if (_availableServices.isEmpty) {
      return ServiceOption(
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ServiceColors.buttonColor('GERAL'),
      );
    }
    return _availableServices.firstWhere(
          (o) => o.key == _servicoSelecionado,
      orElse: () => _availableServices.first,
    );
  }


  // Percentuais (consideram a malha atual)
  int get _totalEsperado => totalEstacas * _faixas.length;
  int get _concluidos => _execucoes.where((e) => e.status == 'concluido').length;
  int get _andamento  => _execucoes.where((e) => e.status == 'em andamento').length;
  int get _iniciados  => _concluidos + _andamento;
  int get _aIniciar   => math.max(0, _totalEsperado - _iniciados);

  double get pctConcluido  => _totalEsperado == 0 ? 0 : _concluidos  / _totalEsperado * 100.0;
  double get pctAndamento  => _totalEsperado == 0 ? 0 : _andamento   / _totalEsperado * 100.0;
  double get pctAIniciar   => _totalEsperado == 0 ? 0 : _aIniciar    / _totalEsperado * 100.0;

  // -------------------- util --------------------
  /// slug para usar no nome da coleção do serviço
  String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  /// nome da coleção no contrato p/ um serviço (exceto ‘geral’)
  String _collectionForService(String key) => 'schedules_${_slug(key)}';

  CollectionReference<Map<String, dynamic>> _col(String collection) =>
      firestore.collection('contracts').doc(contractId).collection(collection);

  // -------------------- serviços (menu dinâmico) --------------------
  /// Carrega serviços a partir do orçamento: `budget/meta/rows` (documentos
  /// de grupo com campo `title`). Sempre inclui o “GERAL” na primeira posição.
  Future<void> loadAvailableServicesFromBudget() async {
    _availableServices.clear();

    // Adiciona “GERAL” fixo
    _availableServices.add(ServiceOption(
      key: 'geral',
      label: 'GERAL',
      icon: Icons.clear_all,
      color: ServiceColors.buttonColor('GERAL'),
    ));

    try {
      final rowsCol = firestore
          .collection('contracts')
          .doc(contractId)
          .collection('budget')
          .doc('meta')
          .collection('rows');

      final groups = await rowsCol.orderBy('order').get();

      for (final g in groups.docs) {
        final data = g.data();
        final rawTitle = (data['title'] ?? '').toString().trim();
        if (rawTitle.isEmpty) continue;

        // chave técnica = slug do título
        final key = _slug(rawTitle);

        // evita duplicatas
        if (_availableServices.any((o) => o.key == key)) continue;

        _availableServices.add(ServiceOption(
          key: key,
          label: rawTitle.toUpperCase(),
          icon: _pickIconForTitle(rawTitle),
          color: ServiceColors.buttonColor(rawTitle),
        ));
      }
    } catch (_) {
      // se der erro, mantém só o “GERAL”
    }

    // garante que o selecionado exista
    if (_availableServices.where((o) => o.key == _servicoSelecionado).isEmpty) {
      _servicoSelecionado = 'geral';
    }

    notifyListeners();
  }

  IconData _pickIconForTitle(String title) {
    final t = title.toUpperCase();
    if (t.contains('ASFALT') || t.contains('PAVIMENTA')) return Icons.directions_car;
    if (t.contains('BASE')) return Icons.recycling;
    if (t.contains('TERRAPLEN')) return Icons.terrain;
    return Icons.layers_outlined;
  }

  Future<void> selectServico(String key) async {
    if (_servicoSelecionado == key) return;
    _servicoSelecionado = key;
    notifyListeners();
    await load(); // recarrega execuções conforme o serviço
  }

  // -------------------- malha / faixas --------------------
  /// Recarrega execuções do serviço atual (ou soma todas no “GERAL”).
  Future<void> load() async {
    if (contractId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      List<QuerySnapshot<Map<String, dynamic>>> snaps = [];

      if (_servicoSelecionado == 'geral') {
        // geral = soma de todas as frentes conhecidas (exceto 'geral')
        final keys = _availableServices.where((o) => o.key != 'geral').map((o) => o.key);
        if (keys.isEmpty) {
          snaps = [];
        } else {
          snaps = await Future.wait([
            for (final k in keys) _col(_collectionForService(k)).get(),
          ]);
        }
      } else {
        snaps = [await _col(_collectionForService(_servicoSelecionado)).get()];
      }

      final execs = snaps.expand((s) => s.docs.map((d) => CalculationMemoryData.fromMap(d.data()))).toList();

      // dedup por (numero, faixaIndex) mantendo o timestamp mais recente
      final map = <String, CalculationMemoryData>{};
      for (final e in execs) {
        final key = '${e.numero}_${e.faixaIndex}';
        final cur = map[key];
        if (cur == null ||
            (e.timestamp != null &&
                (cur.timestamp == null || e.timestamp!.isAfter(cur.timestamp!)))) {
          map[key] = e;
        }
      }

      _execucoes = map.values.toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza / remove um quadrado. Só funciona fora do “GERAL”.
  Future<void> updateSquare(
      int estaca,
      int faixaIndex,
      String tipoLabel,
      String status, [
        String? comentario,
      ]) async {
    if (_servicoSelecionado == 'geral' || contractId.isEmpty) return;

    final col = _col(_collectionForService(_servicoSelecionado));
    final query = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .get();

    final dados = {
      'numero': estaca,
      'faixa_index': faixaIndex,
      'tipo': tipoLabel,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      if (comentario != null) 'comentario': comentario,
    };

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      if (status == 'a iniciar') {
        await doc.reference.delete();
      } else {
        await doc.reference.update(dados);
      }
    } else if (status != 'a iniciar') {
      await col.add(dados);
    }

    // aplica localmente (snappy)
    final key = '${estaca}_$faixaIndex';
    final idx = _execucoes.indexWhere((e) => '${e.numero}_${e.faixaIndex}' == key);

    if (status == 'a iniciar') {
      if (idx != -1) _execucoes.removeAt(idx);
    } else {
      final updated = CalculationMemoryData(
        numero: estaca,
        faixaIndex: faixaIndex,
        tipo: tipoLabel,
        status: status,
        comentario: (comentario?.trim().isEmpty ?? true) ? null : comentario,
        timestamp: DateTime.now(),
      );
      if (idx == -1) {
        _execucoes.add(updated);
      } else {
        _execucoes[idx] = updated;
      }
    }

    notifyListeners();
  }

  /// Define as faixas (labels) vindas do diálogo e atualiza a malha.
  /// - Mantém a faixa **central** com altura menor (10) se o label contiver “CANTEIRO”.
  /// - Demais faixas usam 20 de altura.
  /// - Salva as labels em `schedule_meta.lane_labels`.
  Future<void> setFaixasByLabels(List<String> labels) async {
    if (labels.isEmpty) return;

    final newFaixas = <HighwayClass>[];
    for (final l in labels) {
      final isCentral = l.toUpperCase().contains('CANTEIRO');
      newFaixas.add(HighwayClass(l, Colors.black12, isCentral ? 20 : 20));
    }

    _faixas = newFaixas;
    notifyListeners();

    // persiste os nomes das faixas
    await firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({'lane_labels': labels, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  /// Tenta carregar os nomes das faixas salvos em `schedule_meta/lanes`.
  Future<void> loadSavedFaixas() async {
    final doc = await firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .get();

    if (!doc.exists) return;
    final data = doc.data()!;
    final list = (data['lane_labels'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? <String>[];
    if (list.isEmpty) return;

    await setFaixasByLabels(list); // já notifica + salva altura central/laterais
  }

  // -------------------- cores / grid --------------------
  /// Cor do quadrado na malha (regras para GERAL x específico)
  Color squareColor(CalculationMemoryData e) {
    if (_servicoSelecionado == 'geral') {
      if (e.status == 'concluido' || e.status == 'em andamento') {
        return ServiceColors.buttonColor(e.tipo ?? '');
      }
      return Colors.grey.shade300;
    } else {
      switch (e.status) {
        case 'concluido':
          return Colors.green;
        case 'em andamento':
          return Colors.orange;
        default:
          return Colors.grey.shade300;
      }
    }
  }
}
