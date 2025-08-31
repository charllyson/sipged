// lib/screens/sectors/operation/schedule/schedule_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// UI base
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

// Domínio / dados
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_widgets/schedule/schedule_lane_class.dart';

// Widgets do Schedule
import 'package:siged/_widgets/schedule/schedule_header.dart';
import 'package:siged/_widgets/schedule/schedule_grid.dart';
import 'package:siged/_widgets/schedule/schedule_menu_buttons.dart';
import 'package:siged/_widgets/schedule/schedule_sub_header.dart';
import 'package:siged/screens/sectors/operation/schedule/schedule_modal_widget.dart';

// Editor de faixas
import 'package:siged/screens/sectors/operation/schedule/schedule_lanes_edit_section.dart';

// BLoC
import 'package:siged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/schedule_event.dart';
import 'package:siged/_blocs/sectors/operation/schedule_state.dart';

// Status enum
import 'package:siged/_widgets/schedule/schedule_status.dart';

// Modal (single cell)
import 'package:siged/screens/sectors/operation/schedule/schedule_modal_square.dart';

// (opcional) metadados por URL p/ carrossel
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

class SchedulePage extends StatefulWidget {
  final ContractData? contractData;
  const SchedulePage({super.key, this.contractData});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ===== Constantes de layout (UI-only) =====
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

    if (context.read<ScheduleBloc?>() == null) {
      throw FlutterError(
        'ScheduleBloc não encontrado no contexto. '
            'Envolva SchedulePage com BlocProvider(create: (_) => ScheduleBloc()).',
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
                        // Título e cor vêm do próprio State (getters)
                        ScheduleHeader(
                          title: state.titleForHeader,
                          colorStripe: state.colorForHeader,
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
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
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

      // Cor calculada pelo próprio estado (com shade por recência)
      getSquareColor: state.squareColor,

      // Interações (UI-only)
      onTapSquare: (ScheduleData e) => _onTapSquare(e, state),
      onDragStart: (int e, int f) => _onDragStart(e, f),
      onDragUpdate: (int e, int f) => _onDragUpdate(e, f, state),
      onDragEnd: _onDragEnd,

      selectedKeys: _selectedKeys,
      highlightColor: Colors.blueAccent,

      onEditLanes: () => _editLanes(state.lanes),
    );
  }

  // ===================== Interações (UI-only) =====================

  Future<void> _onTapSquare(ScheduleData e, ScheduleState state) async {
    if (_isDragging || _modalOpen || _bulkApplying) return;

    if (!state.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final cellKey = '${e.numero}_${e.faixaIndex}';
    setState(() => _selectedKeys..clear()..add(cellKey));

    try {
      _modalOpen = true;

      // ----- monta metadados por URL (para o carrossel) -----
      final metaByUrl = <String, pm.CarouselMetadata>{};
      for (final m in e.fotosMeta) {
        final url = m['url']?.toString() ?? '';
        if (url.isEmpty) continue;
        metaByUrl[url] = pm.CarouselMetadata(
          name: m['name']?.toString(),
          takenAt: (m['takenAtMs'] is num)
              ? DateTime.fromMillisecondsSinceEpoch((m['takenAtMs'] as num).toInt())
              : ((m['takenAt'] is num)
              ? DateTime.fromMillisecondsSinceEpoch((m['takenAt'] as num).toInt())
              : null),
          lat: (m['lat'] as num?)?.toDouble(),
          lng: (m['lng'] as num?)?.toDouble(),
          make: m['make']?.toString(),
          model: m['model']?.toString(),
          orientation: (m['orientation'] is num)
              ? (m['orientation'] as num).toInt()
              : int.tryParse(m['orientation']?.toString() ?? ''),
          url: url,
        );
      }

      // status inicial para o modal
      final initialStatus = _statusFromString(e.status);

      // Modal — usa o mesmo BLoC da página
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: ScheduleModalSquare(
            estaca: e.numero,
            trackIndex: e.faixaIndex,
            currentUserId: _uid,
            tipoLabel: state.titleForHeader,
            initialStatus: initialStatus,
            existingUrls: e.fotos,
            existingMetaByUrl: metaByUrl,
            initialTakenAt: e.takenAt,
          )
        ),
      );

      // Recarrega execuções após fechar o modal
      context.read<ScheduleBloc>().add(const ScheduleExecucoesReloadRequested());
      _toast('Célula atualizada com sucesso!');
    } catch (err) {
      _toast('Falha ao salvar a célula: $err');
    } finally {
      _modalOpen = false;
      if (mounted) setState(() => _selectedKeys.clear());
    }
  }

  ScheduleStatus _statusFromString(String? s) {
    final t = (s ?? '').toLowerCase();
    if (t.contains('conclu')) return ScheduleStatus.concluido;
    if (t.contains('andament') || t.contains('progress')) return ScheduleStatus.emAndamento;
    return ScheduleStatus.aIniciar;
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

  void _onDragUpdate(int estaca, int faixa, ScheduleState state) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) return;

    // Delega ao State o cálculo das keys selecionadas (parâmetros posicionais)
    final sel = state.selectionBetween(_anchorEstaca!, _anchorFaixa!, estaca, faixa);

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
    if (!state.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }
    if (_selectedKeys.length <= 1) return;

    _modalOpen = true;

    final res = await showModalBottomSheet<ScheduleModalWidget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BulkStatusCommentSheet(count: _selectedKeys.length),
    );

    _modalOpen = false;

    if (res == null) {
      setState(() => _selectedKeys.clear());
      return;
    }

    setState(() => _bulkApplying = true);
    try {
      for (final key in _selectedKeys) {
        // parse simples "e_f"
        final parts = key.split('_');
        if (parts.length != 2) continue;
        final estaca = int.tryParse(parts[0]);
        final faixa = int.tryParse(parts[1]);
        if (estaca == null || faixa == null) continue;

        // Fotos atuais: helper do State
        final fotosAtuais = state.fotosAtuaisFor(estaca, faixa);

        context.read<ScheduleBloc>().add(
          ScheduleSquareApplyRequested(
            estaca: estaca,
            faixaIndex: faixa,
            tipoLabel: state.titleForHeader,
            status: res.status.key,
            comentario: (res.comment?.trim().isEmpty ?? true) ? null : res.comment!.trim(),
            takenAt: res.takenAt,                // ⬅️ aplica a mesma data p/ todas
            finalPhotoUrls: fotosAtuais,         // preserva as fotos existentes
            newFilesBytes: const [],             // sem novos uploads
            newFileNames: const [],
            newPhotoMetas: const [],
            currentUserId: _uid,
          ),
        );
      }

      context.read<ScheduleBloc>().add(const ScheduleExecucoesReloadRequested());
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