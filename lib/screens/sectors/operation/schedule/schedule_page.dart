import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';

import 'package:sisged/screens/sectors/operation/schedule/schedule_controller.dart';
import 'package:sisged/screens/sectors/operation/schedule/schedule_modal_result.dart';
import '../../../../_blocs/documents/contracts/contracts/contract_bloc.dart';
import '../../../../_blocs/system/user_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';

import '../../../../_datas/sectors/operation/schedule/schedule_data.dart';
import '../../../../_widgets/buttons/back_circle_button.dart';
import '../../../../_widgets/schedule/schedule_lane_class.dart';
import '../../../../_widgets/schedule/schedule_header.dart';
import '../../../../_widgets/schedule/schedule_grid.dart';
import '../../../../_widgets/schedule/schedule_menu_buttons.dart';
import '../../../../_widgets/schedule/schedule_sub_header.dart';
import '../../../commons/currentUser/user_greeting.dart';
import '../../../commons/popUpMenu/pup_up_photo_menu.dart';
import 'schedule_lanes_edit.dart';

class SchedulePage extends StatefulWidget {
  final ContractData? contractData;
  final ContractBloc? contractsBloc;

  const SchedulePage({
    super.key,
    this.contractData,
    this.contractsBloc,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ===== Layout =====
  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;
  static const double kHeaderHeight = 40.0;

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
      faixas: null, // será carregado do Firestore
      contractExtKm: km,
      initialServico: 'geral',
    );

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    // Carrega serviços, faixas e execuções
    Future.microtask(() async {
      await controller.loadAvailableServicesFromBudget();
      await controller.loadSavedFaixas();
      await controller.load();
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
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
            child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  // ===================== Clique simples na célula =====================
  void _onTapSquare(ScheduleData e) async {
    if (controller.servicoSelecionado == 'geral') {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final cellKey = '${e.numero}_${e.faixaIndex}';

    final prevSelected = _selectedKeys;
    setState(() {
      _selectedKeys = {cellKey}; // borda azul na célula clicada
    });

    try {
      final res = await showModalBottomSheet<ScheduleModalResultClass>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ScheduleModalResult(
          count: 1,
          serviceLabel: controller.currentOption.label,
          initialStatus: (e.status != null && e.status!.isNotEmpty) ? e.status : null,
          initialComment: e.comentario,
        ),
      );

      if (res != null) {
        await controller.updateSquare(
          e.numero!,
          e.faixaIndex!,
          controller.currentOption.label,
          res.status,
          (res.comment?.trim().isEmpty ?? true) ? null : res.comment!.trim(),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _selectedKeys = {};
        // Se quiser restaurar seleção anterior, troque pela linha abaixo:
        // _selectedKeys = prevSelected;
      });
    }
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
    final f0 = math.min(aF, faixa), f1 = math.max(aF, faixa);

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

  // ===================== Edição em lote =====================
  Future<void> _openBulkActionSheet() async {
    if (controller.servicoSelecionado == 'geral') {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }

    final res = await showModalBottomSheet<ScheduleModalResultClass>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ScheduleModalResult(
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
        final faixa = int.tryParse(parts[1]);
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
    final rows = await showDialog<List<ScheduleLaneClass>>(
      context: context,
      builder: (_) => ScheduleLanesEdit(initialRows: controller.faixas),
    );

    if (rows != null) {
      await controller.setFaixasStructured(rows);
      _toast('Faixas atualizadas.');
    }
  }

  // ===================== build =====================
  @override
  Widget build(BuildContext context) {
    Widget _gridOrPlaceholder() {
      if (controller.isLoadingFaixas) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Carregando faixas...', style: TextStyle(color: Colors.black54)),
            ],
          ),
        );
      }

      if (controller.faixas.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nenhuma faixa definida', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Definir faixas'),
                onPressed: _editarNomesFaixas,
              ),
            ],
          ),
        );
      }

      return ScheduleGrid(
        headerHeight: kHeaderHeight,
        totalEstacas: controller.totalEstacas,
        faixas: controller.faixas,
        execucoes: controller.execucoes,
        servicoSelecionado: controller.servicoSelecionado,
        legendWidth: kLegendWidth,
        estacaWidth: kEstacaWidth,
        getSquareColor: controller.squareColor,
        onTapSquare: _onTapSquare,
        onDragStart: _dragStart,
        onDragUpdate: _dragUpdate,
        onDragEnd: _dragEnd,
        selectedKeys: _selectedKeys,
        highlightColor: Colors.blueAccent,
        onEditLanes: _editarNomesFaixas,
      );
    }
    final width = MediaQuery.of(context).size.width;
    final needsTwoRows = width < 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BackgroundClean(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UpBar(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduleHeader(
                      title: controller.currentOption.label.toUpperCase(),
                      colorStripe: controller.currentOption.color,
                      leftPadding: 80, // se precisar alinhar com a grade
                    ),
                    const SizedBox(height: 6),
                    ScheduleSubHeader(
                      isLoading: controller.isLoading || controller.isLoadingFaixas || _isApplyingBulk,
                      pctConcluido: controller.pctConcluido,
                      pctAndamento: controller.pctAndamento,
                      pctAIniciar: controller.pctAIniciar,
                      leftPadding: 80,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 75.0,
                    top: 12.0,
                  ),
                  child: Container(
                    color: Colors.white,
                    child: _gridOrPlaceholder(),
                  ),
                ),
              ),
              FootBar()
            ],
          ),

          // Menu de serviços dinâmico
          Positioned(
            bottom: 16,
            right: 14,
            child: ScheduleMenuButtons(
              options: controller.availableServices,
              current: controller.servicoSelecionado,
              onSelect: (key) async {
                await controller.selectServico(key);
                setState(() {
                  _selectedKeys.clear();
                  _anchorEstaca = _anchorFaixa = null;
                });
              },
            ),
          ),

          const Positioned(top: 12, left: 20, child: BackCircleButton()),

          // Overlay durante bulk update
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
