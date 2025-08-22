// lib/screens/sectors/operation/schedule/schedule_page.dart
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// UI base
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';

// Domínio / dados
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_data.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_lane_class.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_modal_result_class.dart';

// Widgets do Schedule
import 'package:sisged/_widgets/schedule/schedule_header.dart';
import 'package:sisged/_widgets/schedule/schedule_grid.dart';
import 'package:sisged/_widgets/schedule/schedule_menu_buttons.dart';
import 'package:sisged/_widgets/schedule/schedule_sub_header.dart';

// Editor de faixas e Modal de resultado
import 'package:sisged/screens/sectors/operation/schedule/schedule_lanes_edit.dart';
import 'package:sisged/screens/sectors/operation/schedule/schedule_modal_result.dart';

// Bloc + Repo
import 'package:sisged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_event.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_state.dart';
import 'package:sisged/_repository/sectors/operation/schedule_repository.dart';

// Controller ÚNICO de UI
import 'package:sisged/_widgets/schedule/schedule_status.dart';
import 'package:sisged/screens/sectors/operation/schedule/schedule_ui_controller.dart';

class SchedulePage extends StatefulWidget {
  final ContractData? contractData;

  const SchedulePage({super.key, this.contractData});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ===== Constantes de layout =====
  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;
  static const double kHeaderHeight = 40.0;

  // ===== Estado puramente de UI =====
  final _selectedKeys = <String>{};
  bool _isDragging = false;
  int? _anchorEstaca;
  int? _anchorFaixa;
  bool _modalOpen = false;
  bool _bulkApplying = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();

    // Garantias (injete Repository/Bloc acima desta página)
    if (context.read<ScheduleRepository?>() == null) {
      throw FlutterError(
        'ScheduleRepository não encontrado no contexto. '
            'Envolva SchedulePage com RepositoryProvider(create: (_) => ScheduleRepository()).',
      );
    }
    if (context.read<ScheduleBloc?>() == null) {
      throw FlutterError(
        'ScheduleBloc não encontrado no contexto. '
            'Envolva SchedulePage com BlocProvider(create: (ctx) => ScheduleBloc(ctx.read<ScheduleRepository>())).',
      );
    }

    // Warmup
    final km = widget.contractData?.contractExtKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    final contractId = widget.contractData?.id ?? '';

    context.read<ScheduleBloc>().add(
      ScheduleWarmupRequested(
        contractId: contractId,
        totalEstacas: totalEstacas,
        initialServiceKey: 'geral',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.contractData?.id ?? '';
    final newId = widget.contractData?.id ?? '';
    if (oldId != newId) {
      final km = widget.contractData?.contractExtKm ?? 0.0;
      final totalEstacas = ((km * 1000) / 20).ceil();
      final contractId = widget.contractData?.id ?? '';
      context.read<ScheduleBloc>().add(
        ScheduleWarmupRequested(
          contractId: contractId,
          totalEstacas: totalEstacas,
          initialServiceKey: 'geral',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (ctx, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Erro: ${state.error}')),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.loadingServices || state.loadingLanes || state.loadingExecucoes;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UpBar(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScheduleHeader(
                          title: _titleForHeader(state),
                          colorStripe: _colorForHeader(state),
                          leftPadding: 80,
                        ),
                        const SizedBox(height: 6),
                        ScheduleSubHeader(
                          isLoading: isLoading || _bulkApplying,
                          pctConcluido: state.pctConcluido,
                          pctAndamento: state.pctAndamento,
                          pctAIniciar: state.pctAIniciar,
                          leftPadding: 80,
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 75.0, top: 12.0),
                      child: Container(
                        color: Colors.white,
                        child: _gridOrPlaceholder(state),
                      ),
                    ),
                  ),

                  const FootBar(),
                ],
              ),

              // Menu de serviços dinâmico
              Positioned(
                bottom: 16,
                right: 14,
                child: ScheduleMenuButtons(
                  options: state.services,
                  current: state.currentServiceKey,
                  onSelect: (key) =>
                      context.read<ScheduleBloc>().add(ScheduleServiceSelected(key)),
                ),
              ),

              // Botão voltar
              const Positioned(top: 12, left: 20, child: BackButton()),

              // Overlay durante bulk update
              if (_bulkApplying)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===================== Grid/Placeholder =====================
  Widget _gridOrPlaceholder(ScheduleState state) {
    if (state.loadingLanes) {
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

    if (state.lanes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhuma faixa definida', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Definir faixas'),
              onPressed: () => _editLanes(state.lanes),
            ),
          ],
        ),
      );
    }

    return ScheduleGrid(
      headerHeight: kHeaderHeight,
      totalEstacas: state.totalEstacas,
      faixas: state.lanes,
      execucoes: state.execucoes,
      servicoSelecionado: state.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: kEstacaWidth,

      // Cor calculada pelo próprio estado
      getSquareColor: state.squareColor,

      // Interações
      onTapSquare: (ScheduleData e) => _onTapSquare(e, state),
      onDragStart: (int e, int f) => _onDragStart(e, f),
      onDragUpdate: (int e, int f) => _onDragUpdate(e, f),
      onDragEnd: _onDragEnd,

      selectedKeys: _selectedKeys,
      highlightColor: Colors.blueAccent,

      onEditLanes: () => _editLanes(state.lanes),
    );
  }

  // ===================== Interações =====================

  Future<void> _onTapSquare(ScheduleData e, ScheduleState state) async {
    if (_isDragging || _modalOpen || _bulkApplying) return;

    if (state.currentServiceKey == 'geral') {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final cellKey = '${e.numero}_${e.faixaIndex}';
    setState(() => _selectedKeys..clear()..add(cellKey));

    try {
      _modalOpen = true;

      // Controller do modal — TODA a lógica fica nele
      final ctrl = ScheduleUiController(
        initialStatus: ScheduleStatusX.fromString(e.status),
        initialComment: e.comentario,
        initialDate: DateTime.now(),
        existingPhotoUrls: e.fotos,
        // Se você tiver o mapa de metadados por URL, passe aqui:
        // existingMetaByUrl: {...},
      );

      final res = await showModalBottomSheet<ScheduleModalResultClass>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ScheduleModalResult(
          title: _titleForHeader(state),
          count: 1,
          controller: ctrl, // UI boba + controller com a lógica
        ),
      );

      if (res != null) {
        // 1) status/comentário
        context.read<ScheduleBloc>().add(
          ScheduleSquareUpsertRequested(
            estaca: e.numero,
            faixaIndex: e.faixaIndex,
            tipoLabel: _titleForHeader(state),
            status: res.statusKey,
            comentario: (res.comment?.trim().isEmpty ?? true)
                ? null
                : res.comment!.trim(),
            currentUserId: _uid,
          ),
        );

        // 2) fotos (se houver)
        if (res.hasPhotos) {
          context.read<ScheduleBloc>().add(
            ScheduleSquareUploadPhotosRequested(
              estaca: e.numero,
              faixaIndex: e.faixaIndex,
              filesBytes: res.photosBytes,
              fileNames: res.photoNames,
              currentUserId: _uid,
              takenAt: res.date,
            ),
          );
        }

        _toast('Célula atualizada com sucesso!');
      }
    } catch (err) {
      _toast('Falha ao salvar a célula: $err');
    } finally {
      _modalOpen = false;
      if (mounted) setState(() => _selectedKeys.clear());
    }
  }

  void _onDragStart(int estaca, int faixa) {
    if (_modalOpen || _bulkApplying) return;
    _isDragging = true;
    setState(() {
      _anchorEstaca = estaca;
      _anchorFaixa = faixa;
      _selectedKeys
        ..clear()
        ..add('${estaca}_$faixa');
    });
  }

  void _onDragUpdate(int estaca, int faixa) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) return;
    final aE = _anchorEstaca!, aF = _anchorFaixa!;
    final e0 = math.min(aE, estaca), e1 = math.max(aE, estaca);
    final f0 = math.min(aF, faixa), f1 = math.max(aF, faixa);

    final sel = <String>{};
    for (int e = e0; e <= e1; e++) {
      for (int f = f0; f <= f1; f++) {
        sel.add('${e}_$f');
      }
    }
    setState(() {
      _selectedKeys
        ..clear()
        ..addAll(sel);
    });
  }

  void _onDragEnd() {
    if (!_isDragging) return;
    _isDragging = false;

    if (_selectedKeys.length > 1) {
      _openBulkActionSheet();
    } else {
      setState(() => _selectedKeys.clear());
    }
  }

  Future<void> _openBulkActionSheet() async {
    final state = context.read<ScheduleBloc>().state;

    if (_modalOpen || _bulkApplying) return;
    if (state.currentServiceKey == 'geral') {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }
    if (_selectedKeys.length <= 1) return;

    _modalOpen = true;

    // Controller do modal (batch)
    final ctrl = ScheduleUiController(
      initialStatus: ScheduleStatus.aIniciar,
      initialComment: '',
      initialDate: DateTime.now(),
    );

    final res = await showModalBottomSheet<ScheduleModalResultClass>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ScheduleModalResult(
        title: _titleForHeader(state),
        count: _selectedKeys.length,
        controller: ctrl,
      ),
    );

    _modalOpen = false;

    if (res == null) {
      setState(() => _selectedKeys.clear());
      return;
    }

    setState(() => _bulkApplying = true);
    try {
      for (final key in _selectedKeys) {
        final parts = key.split('_');
        if (parts.length != 2) continue;
        final estaca = int.tryParse(parts[0]);
        final faixa = int.tryParse(parts[1]);
        if (estaca == null || faixa == null) continue;

        // 1) status/comentário
        context.read<ScheduleBloc>().add(
          ScheduleSquareUpsertRequested(
            estaca: estaca,
            faixaIndex: faixa,
            tipoLabel: _titleForHeader(state),
            status: res.statusKey,
            comentario: (res.comment?.trim().isEmpty ?? true)
                ? null
                : res.comment!.trim(),
            currentUserId: _uid,
          ),
        );

        // 2) fotos (se houver)
        if (res.hasPhotos) {
          context.read<ScheduleBloc>().add(
            ScheduleSquareUploadPhotosRequested(
              estaca: estaca,
              faixaIndex: faixa,
              filesBytes: res.photosBytes,
              fileNames: res.photoNames,
              currentUserId: _uid,
              takenAt: res.date,
            ),
          );
        }
      }
      _toast('Atualizado em lote: ${_selectedKeys.length} célula(s).');
    } catch (e) {
      _toast('Falha ao aplicar em lote: $e');
    } finally {
      if (mounted) {
        setState(() {
          _bulkApplying = false;
          _selectedKeys.clear();
          _anchorEstaca = _anchorFaixa = null;
        });
      }
    }
  }

  Future<void> _editLanes(List<ScheduleLaneClass> current) async {
    final rows = await showDialog<List<ScheduleLaneClass>>(
      context: context,
      builder: (_) => ScheduleLanesEdit(initialRows: current),
    );

    if (rows != null) {
      context.read<ScheduleBloc>().add(ScheduleLanesSaveRequested(rows));
      _toast('Faixas atualizadas.');
    }
  }

  // ===================== Helpers de UI =====================
  String _titleForHeader(ScheduleState state) {
    final meta = _metaForService(state);
    return meta.label.isNotEmpty ? meta.label.toUpperCase() : meta.key.toUpperCase();
    // meta é um ScheduleData dentro de state.services
  }

  Color _colorForHeader(ScheduleState state) {
    final meta = _metaForService(state);
    return meta.color;
  }

  ScheduleData _metaForService(ScheduleState state) {
    final services = state.services;
    if (services.isEmpty) {
      return const ScheduleData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: Colors.grey,
      );
    }
    return services.firstWhere(
          (o) => o.key == state.currentServiceKey,
      orElse: () => services.first,
    );
  }

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
}
