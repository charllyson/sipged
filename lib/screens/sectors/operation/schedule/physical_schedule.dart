import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/screens/sectors/operation/schedule/physical_schedule_controller.dart';
import '../../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/sectors/operation/calculationMemory/calculation_memory_data.dart';

import '../../../../_widgets/buttons/back_circle_button.dart';
import '../../../../_widgets/schedule/highway_class.dart';
import '../../../../_widgets/schedule/schedule_header.dart';
import '../../../../_widgets/schedule/schedule_malha_grid.dart';
import '../../../../_widgets/schedule/schedule_service_menu.dart';
import 'edit_lanes_dialog.dart';

class PhysicalSchedule extends StatefulWidget {
  final ContractData? contractData;
  final ContractsBloc? contractsBloc;

  const PhysicalSchedule({
    super.key,
    this.contractData,
    this.contractsBloc,
  });

  /// layout inicial: 3 faixas (laterais + central)
  static List<HighwayClass> faixas = [
    HighwayClass('FAIXA ATUAL LE', Colors.black12, 20),
    HighwayClass('CANTEIRO CENTRAL', Colors.yellow, 10),
    HighwayClass('FAIXA ATUAL LD', Colors.black12, 20),
  ];

  @override
  State<PhysicalSchedule> createState() => _PhysicalScheduleState();
}

class _PhysicalScheduleState extends State<PhysicalSchedule> {
  // Layout
  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;

  late final PhysicalScheduleController controller;

  // ===== Seleção por arrasto (edição em lote) =====
  int? _anchorEstaca;
  int? _anchorFaixa;
  Set<String> _selectedKeys = {};
  bool _isApplyingBulk = false;

  @override
  void initState() {
    super.initState();

    final km = widget.contractData?.contractExtKm ?? 0.0;

    controller = PhysicalScheduleController(
      firestore: FirebaseFirestore.instance,
      contractId: widget.contractData?.id ?? '',
      faixas: PhysicalSchedule.faixas,
      contractExtKm: km,
      initialServico: 'geral',
    );

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    // Carrega serviços e malha
    Future.microtask(() async {
      await controller.loadAvailableServicesFromBudget();
      await controller.load();
      await controller.loadSavedFaixas(); // tenta carregar labels salvos
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ===================== Helpers UI =====================
  void _toast(String msg) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 70,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  // ===================== Edição individual =====================
  Future<void> _abrirPopupServico(int estaca, int faixaIndex) async {
    final tipoLabel = controller.currentOption.label; // label exibido
    final exec = controller.execucoes.firstWhere(
          (e) => e.numero == estaca && e.faixaIndex == faixaIndex,
      orElse: () => CalculationMemoryData(
        numero: estaca,
        faixaIndex: faixaIndex,
        tipo: tipoLabel,
        status: '',
        comentario: '',
      ),
    );

    final comentarioCtrl = TextEditingController(text: exec.comentario ?? '');

    final escolha = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Atualizar "$tipoLabel" - Estaca $estaca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: comentarioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _DialogBtn(text: 'Concluído', value: 'concluido', icon: Icons.check, iconColor: Colors.green),
                _DialogBtn(text: 'Andamento', value: 'em andamento', icon: Icons.build, iconColor: Colors.orange),
                _DialogBtn(text: 'A iniciar', value: 'a iniciar', icon: Icons.refresh, iconColor: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );

    if (escolha != null) {
      await controller.updateSquare(
        estaca,
        faixaIndex,
        tipoLabel,
        escolha,
        comentarioCtrl.text.trim().isEmpty ? null : comentarioCtrl.text.trim(),
      );
    }
  }

  // Clique em um quadrado
  void _onTapSquare(CalculationMemoryData e) {
    if (controller.servicoSelecionado == 'geral') {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }
    _abrirPopupServico(e.numero!, e.faixaIndex!);
  }

  // ===================== Seleção por arrasto =====================
  void _dragStart(int estaca, int faixa) {
    setState(() {
      _anchorEstaca = estaca;
      _anchorFaixa = faixa;
      _selectedKeys = {'${estaca}_$faixa'};
    });
  }

  void _dragUpdate(int estaca, int faixa) {
    if (_anchorEstaca == null || _anchorFaixa == null) return;
    final aE = _anchorEstaca!, aF = _anchorFaixa!;
    final e0 = math.min(aE, estaca), e1 = math.max(aE, estaca);
    final f0 = math.min(aF, faixa),  f1 = math.max(aF, faixa);

    final sel = <String>{};
    for (int e = e0; e <= e1; e++) {
      for (int f = f0; f <= f1; f++) {
        sel.add('${e}_$f');
      }
    }
    setState(() => _selectedKeys = sel);
  }

  void _dragEnd() {
    if (_selectedKeys.isEmpty) return;
    _openBulkActionSheet();
  }

  Future<void> _openBulkActionSheet() async {
    if (controller.servicoSelecionado == 'geral') {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }

    final res = await showModalBottomSheet<_BulkResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BulkUpdateSheet(
        count: _selectedKeys.length,
        serviceLabel: controller.currentOption.label,
      ),
    );

    if (res == null) return;

    final tipoLabel = controller.currentOption.label;
    final ops = <Future>[];

    setState(() => _isApplyingBulk = true);

    try {
      for (final key in _selectedKeys) {
        final parts = key.split('_');
        if (parts.length != 2) continue;
        final estaca = int.tryParse(parts[0]);
        final faixa  = int.tryParse(parts[1]);
        if (estaca == null || faixa == null) continue;

        ops.add(controller.updateSquare(
          estaca,
          faixa,
          tipoLabel,
          res.status,
          (res.comment?.trim().isEmpty ?? true) ? null : res.comment!.trim(),
        ));
      }
      await Future.wait(ops);
      _toast('Atualizado em lote: ${_selectedKeys.length} célula(s).');
    } catch (e) {
      _toast('Falha ao aplicar em lote: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isApplyingBulk = false;
        _selectedKeys.clear();
        _anchorEstaca = _anchorFaixa = null;
      });
    }
  }

  // ===================== Editar nomes das faixas =====================
  Future<void> _editarNomesFaixas() async {
    final labels = await showDialog<List<String>>(
      context: context,
      builder: (_) => EditLanesDialog(initialLabels: controller.faixaLabels),
    );
    if (labels != null) {
      await controller.setFaixasByLabels(labels);
      _toast('Nomes das faixas atualizados.');
    }
  }

  // ===================== build =====================
  @override
  Widget build(BuildContext context) {
    final current = controller.currentOption;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho (full width) com “tracinho” na cor do serviço
                ScheduleHeader(
                  title: "CRONOGRAMA - ${current.label.toUpperCase()}",
                  isLoading: controller.isLoading || _isApplyingBulk,
                  colorStripe: current.color,
                  leftPadding: kLegendWidth,
                  pctConcluido: controller.pctConcluido,
                  pctAndamento: controller.pctAndamento,
                  pctAIniciar: controller.pctAIniciar,
                ),

                // Malha
                Expanded(
                  child: MalhaGrid(
                    totalEstacas: controller.totalEstacas,
                    faixas: controller.faixas,
                    execucoes: controller.execucoes,
                    servicoSelecionado: controller.servicoSelecionado,
                    legendWidth: kLegendWidth,
                    estacaWidth: kEstacaWidth,
                    getSquareColor: controller.squareColor,
                    onTapSquare: _onTapSquare,

                    // seleção múltipla por arrasto
                    selectedKeys: _selectedKeys,
                    onDragStart: _dragStart,
                    onDragUpdate: _dragUpdate,
                    onDragEnd: _dragEnd,
                    highlightColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),

          // Menu de serviços dinâmico (inclui GERAL)
          Positioned(
            bottom: 24,
            right: 24,
            child: ServiceMenu(
              options: controller.availableServices,
              current: controller.servicoSelecionado,
              onSelect: (key) async {
                await controller.selectServico(key);
                // limpar seleção se trocar de serviço
                setState(() {
                  _selectedKeys.clear();
                  _anchorEstaca = _anchorFaixa = null;
                });
              },
            ),
          ),

          // Botão para editar nomes das faixas
          Positioned(
            top: 18,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'editLanes',
              tooltip: 'Editar nomes das faixas',
              backgroundColor: Colors.white,
              onPressed: _editarNomesFaixas,
              child: const Icon(Icons.edit_note),
            ),
          ),

          const Positioned(top: 18, left: 20, child: BackCircleButton()),

          // Overlay opcional quando aplicando em lote
          if (_isApplyingBulk)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Widgets auxiliares (diálogo de célula única e bottom sheet)
// ============================================================
class _DialogBtn extends StatelessWidget {
  final String text;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _DialogBtn({
    super.key,
    required this.text,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Força o ícone a manter a cor indicada
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(color: iconColor),
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, value),
        icon: Icon(icon, color: iconColor),
        label: Text(text),
      ),
    );
  }
}

class _BulkResult {
  final String status;
  final String? comment;
  const _BulkResult(this.status, this.comment);
}

class _BulkUpdateSheet extends StatefulWidget {
  final int count;
  final String serviceLabel;
  const _BulkUpdateSheet({super.key, required this.count, required this.serviceLabel});

  @override
  State<_BulkUpdateSheet> createState() => _BulkUpdateSheetState();
}

class _BulkUpdateSheetState extends State<_BulkUpdateSheet> {
  String _status = 'concluido';
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Widget _statusChip(String value, String label, IconData icon, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _status = value),
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      backgroundColor: Colors.grey.shade200,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // título
                Row(
                  children: [
                    const Icon(Icons.select_all_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aplicar em lote (${widget.count}) — ${widget.serviceLabel}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // status
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('concluido', 'Concluído', Icons.check_circle, Colors.green),
                    _statusChip('em andamento', 'Em andamento', Icons.build, Colors.orange),
                    _statusChip('a iniciar', 'A iniciar', Icons.refresh, Colors.blue),
                  ],
                ),
                const SizedBox(height: 12),

                // comentário
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentário (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // aplicar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: Text('Aplicar em ${widget.count} célula(s)'),
                    onPressed: () {
                      Navigator.pop(context, _BulkResult(_status, _commentCtrl.text));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
