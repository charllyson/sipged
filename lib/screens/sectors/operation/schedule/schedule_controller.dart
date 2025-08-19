import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sisged/_datas/sectors/operation/schedule/schedule_data.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_style.dart';
import '../../../../_widgets/schedule/schedule_lane_class.dart';

/// Controller do cronograma físico (somente formato NOVO de faixas)
class PhysicalScheduleController extends ChangeNotifier {
  PhysicalScheduleController({
    required this.firestore,
    required this.contractId,
    required List<ScheduleLaneClass>? faixas, // pode vir null/[]
    required double contractExtKm,
    String initialServico = 'geral',
  })  : _faixas = List<ScheduleLaneClass>.from(faixas ?? []),
        _servicoSelecionado = initialServico.toLowerCase(),
        _totalEstacas = ((contractExtKm * 1000) / 20).ceil(),
        _isLoadingFaixas = (faixas == null || faixas.isEmpty) {
    // Sempre adiciona “GERAL” como opção fixa
    _availableServices.add(
      ScheduleData(
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ScheduleStyle.buttonColor('GERAL'),
      ),
    );
  }

  // --- deps / ids
  final FirebaseFirestore firestore;
  final String contractId;

  // --- malha / faixas
  List<ScheduleLaneClass> _faixas;
  int _totalEstacas;

  // --- execuções (pintura da grade)
  List<ScheduleData> _execucoes = [];
  bool _isLoading = false;
  bool _isLoadingFaixas;

  // --- serviços (menu dinâmico)
  final List<ScheduleData> _availableServices = [];
  String _servicoSelecionado; // chave (lowercase) — 'geral' é especial

  // -------------------- getters --------------------
  bool get isLoading => _isLoading;
  bool get isLoadingFaixas => _isLoadingFaixas;

  List<ScheduleData> get execucoes => _execucoes;
  int get totalEstacas => _totalEstacas;

  /// getter de labels combinados (para compatibilidade pontual)
  List<String> get faixaLabels => _faixas.map((f) => f.label).toList();
  List<ScheduleLaneClass> get faixas => List.unmodifiable(_faixas);

  List<ScheduleData> get availableServices => List.unmodifiable(_availableServices);

  String get servicoSelecionado => _servicoSelecionado;

  ScheduleData get currentOption {
    if (_availableServices.isEmpty) {
      return ScheduleData(
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ScheduleStyle.buttonColor('GERAL'),
      );
    }
    return _availableServices.firstWhere(
          (o) => o.key == _servicoSelecionado,
      orElse: () => _availableServices.first,
    );
  }

  // -------------------- percentuais --------------------
  int get _totalEsperado => totalEstacas * _faixas.length;
  int get _concluidos => _execucoes.where((e) => e.status == 'concluido').length;
  int get _andamento  => _execucoes.where((e) => e.status == 'em andamento').length;
  int get _iniciados  => _concluidos + _andamento;
  int get _aIniciar   => math.max(0, _totalEsperado - _iniciados);

  double get pctConcluido => _totalEsperado == 0 ? 0 : _concluidos / _totalEsperado * 100.0;
  double get pctAndamento => _totalEsperado == 0 ? 0 : _andamento  / _totalEsperado * 100.0;
  double get pctAIniciar  => _totalEsperado == 0 ? 0 : _aIniciar   / _totalEsperado * 100.0;

  // -------------------- utils --------------------
  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  String _collectionForService(String key) => 'schedules_${_slug(key)}';
  CollectionReference<Map<String, dynamic>> _col(String collection) =>
      firestore.collection('contracts').doc(contractId).collection(collection);

  IconData _pickIconForTitle(String title) {
    final t = title.toUpperCase();
    if (t.contains('ASFALT') || t.contains('PAVIMENTA')) return Icons.directions_car;
    if (t.contains('BASE')) return Icons.recycling;
    if (t.contains('TERRAPLEN')) return Icons.terrain;
    return Icons.layers_outlined;
  }

  // -------------------- serviços (menu dinâmico) --------------------
  Future<void> loadAvailableServicesFromBudget() async {
    _availableServices.clear();

    // “GERAL” fixo
    _availableServices.add(ScheduleData(
      key: 'geral',
      label: 'GERAL',
      icon: Icons.clear_all,
      color: ScheduleStyle.buttonColor('GERAL'),
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

        final key = _slug(rawTitle);
        if (_availableServices.any((o) => o.key == key)) continue;

        _availableServices.add(ScheduleData(
          key: key,
          label: rawTitle.toUpperCase(),
          icon: _pickIconForTitle(rawTitle),
          color: ScheduleStyle.buttonColor(rawTitle),
        ));
      }
    } catch (_) {
      // mantém só o “GERAL”
    }

    if (_availableServices.where((o) => o.key == _servicoSelecionado).isEmpty) {
      _servicoSelecionado = 'geral';
    }

    notifyListeners();
  }

  Future<void> selectServico(String key) async {
    if (_servicoSelecionado == key) return;
    _servicoSelecionado = key;
    notifyListeners();
    await load(); // recarrega execuções do serviço atual
  }

  // -------------------- faixas (NOVO formato apenas) --------------------
  /// Define faixas (pos/nome/altura) e persiste no Firestore.
  Future<void> setFaixasStructured(List<ScheduleLaneClass> rows) async {
    _isLoadingFaixas = true; notifyListeners();
    try {
      _faixas = List.of(rows);
      notifyListeners();
      await _saveFaixasToFirestore(rows);
    } finally {
      _isLoadingFaixas = false; notifyListeners();
    }
  }

  /// Salva arrays separados no Firestore (sem legado).
  Future<void> _saveFaixasToFirestore(List<ScheduleLaneClass> rows) async {
    final positions = rows.map((r) => r.pos).toList();
    final names     = rows.map((r) => r.nome).toList();
    final alturas   = rows.map((r) => r.altura).toList();

    await firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({
      'lane_positions': positions,
      'lane_names'    : names,
      'lane_alturas'  : alturas,
      'updatedAt'     : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Carrega faixas salvas no formato novo. Se inválido, mantém vazio.
  Future<void> loadSavedFaixas() async {
    _isLoadingFaixas = true; notifyListeners();
    try {
      final doc = await firestore
          .collection('contracts')
          .doc(contractId)
          .collection('schedule_meta')
          .doc('lanes')
          .get();

      if (!doc.exists) { _faixas = []; notifyListeners(); return; }

      final data      = doc.data()!;
      final positions = (data['lane_positions'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? <String>[];
      final names     = (data['lane_names']     as List?)?.map((e) => e?.toString() ?? '').toList() ?? <String>[];
      final alturas   = (data['lane_alturas']   as List?)?.map((e) => (e is num) ? e.toDouble() : 20.0).toList() ?? <double>[];

      if (positions.isEmpty || names.isEmpty || positions.length != names.length) {
        _faixas = [];
        notifyListeners();
        return;
      }

      final rows = <ScheduleLaneClass>[];
      for (var i = 0; i < names.length; i++) {
        final alt = i < alturas.length ? alturas[i] : 20.0;
        rows.add(ScheduleLaneClass(pos: positions[i], nome: names[i], altura: alt));
      }
      _faixas = rows;
      notifyListeners();
    } finally {
      _isLoadingFaixas = false; notifyListeners();
    }
  }

  // -------------------- execuções --------------------
  Future<void> load() async {
    if (contractId.isEmpty) return;
    _isLoading = true; notifyListeners();

    try {
      final results = <ScheduleData>[];

      if (_servicoSelecionado == 'geral') {
        // Agrega todas as coleções conhecidas (exceto 'geral')
        final keys = _availableServices.where((o) => o.key != 'geral').map((o) => o.key).toList();
        if (keys.isNotEmpty) {
          final snaps = await Future.wait([for (final k in keys) _col(_collectionForService(k)).get()]);
          for (final s in snaps) {
            for (final d in s.docs) {
              final m = d.data();
              results.add(
                ScheduleData(
                  numero    : m['numero'] as int?,
                  faixaIndex: m['faixa_index'] as int?,
                  tipo      : (m['tipo'] as String?)?.trim(),
                  status    : (m['status'] as String?)?.trim(),
                  timestamp : (m['timestamp'] as Timestamp?)?.toDate(),
                  comentario: (m['comentario'] as String?)?.trim(),
                  // metadados do "GERAL"
                  key  : 'geral',
                  label: 'GERAL',
                  icon : Icons.clear_all,
                  color: Colors.black54,
                ),
              );
            }
          }
        }
      } else {
        // Serviço específico
        final snap = await _col(_collectionForService(_servicoSelecionado)).get();
        final opt  = currentOption;
        for (final d in snap.docs) {
          final m = d.data();
          results.add(
            ScheduleData(
              numero    : m['numero'] as int?,
              faixaIndex: m['faixa_index'] as int?,
              tipo      : (m['tipo'] as String?)?.trim(),
              status    : (m['status'] as String?)?.trim(),
              timestamp : (m['timestamp'] as Timestamp?)?.toDate(),
              comentario: (m['comentario'] as String?)?.trim(),
              // metadados do serviço escolhido
              key  : opt.key,
              label: opt.label,
              icon : opt.icon,
              color: opt.color,
            ),
          );
        }
      }

      // Dedup por (numero, faixaIndex) mantendo o timestamp mais recente
      final map = <String, ScheduleData>{};
      for (final e in results) {
        final k = '${e.numero}_${e.faixaIndex}';
        final cur = map[k];
        if (cur == null ||
            (e.timestamp != null &&
                (cur.timestamp == null || e.timestamp!.isAfter(cur.timestamp!)))) {
          map[k] = e;
        }
      }

      _execucoes = map.values.toList();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  /// Atualiza / remove um quadrado (não altera no modo “GERAL”).
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
      'numero'     : estaca,
      'faixa_index': faixaIndex,
      'tipo'       : tipoLabel,
      'status'     : status,
      'timestamp'  : FieldValue.serverTimestamp(),
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

    // Aplica localmente (snappy)
    final key = '${estaca}_$faixaIndex';
    final idx = _execucoes.indexWhere((e) => '${e.numero}_${e.faixaIndex}' == key);
    final opt = currentOption;

    if (status == 'a iniciar') {
      if (idx != -1) _execucoes.removeAt(idx);
    } else {
      final updated = ScheduleData(
        numero    : estaca,
        faixaIndex: faixaIndex,
        tipo      : tipoLabel,
        status    : status,
        comentario: (comentario?.trim().isEmpty ?? true) ? null : comentario!.trim(),
        timestamp : DateTime.now(),
        key  : opt.key,
        label: opt.label,
        icon : opt.icon,
        color: opt.color,
      );
      if (idx == -1) {
        _execucoes.add(updated);
      } else {
        _execucoes[idx] = updated;
      }
    }

    notifyListeners();
  }

  // -------------------- cores dos quadrados --------------------
  Color squareColor(ScheduleData e) {
    if (_servicoSelecionado == 'geral') {
      if (e.status == 'concluido' || e.status == 'em andamento') {
        return ScheduleStyle.buttonColor(e.tipo ?? '');
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
