// lib/screens/sectors/planning/projects/schedule_road_board.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// UI base
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/modals/type.dart';

// Domínio / dados
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';

// Widgets do Schedule
import 'package:siged/_widgets/schedule/linear/schedule_grid.dart';
// (removido) import 'package:siged/_widgets/schedule/linear/schedule_menu_buttons.dart';
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';

// Modal unificado
import 'package:siged/_widgets/modals/schedule_modal_square.dart';

// BLoC
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';

// Metadados por URL pro carrossel
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadBoard extends StatefulWidget {
  final ContractData? contractData;
  const ScheduleRoadBoard({super.key, this.contractData});

  @override
  State<ScheduleRoadBoard> createState() => _ScheduleRoadBoardState();
}

class _ScheduleRoadBoardState extends State<ScheduleRoadBoard> {
  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;
  static const double kHeaderHeight = 40.0;

  final _selectedKeys = <String>{};
  bool _isDragging = false;
  int? _anchorEstaca;
  int? _anchorFaixa;
  bool _modalOpen = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ===================== Helpers de formatação do nome =====================
  String _extractSide(String raw) {
    final m = RegExp(r'\b(LE|CE|LD)\b', caseSensitive: false)
        .firstMatch(raw.toUpperCase());
    return (m?.group(1) ?? '').toUpperCase();
  }

  String _cleanLaneName(String raw) {
    final up = raw.toUpperCase();
    if (up.contains('DUPLICA')) return 'DUPLICAÇÃO';
    if (up.contains('PISTA ATUAL')) return 'PISTA ATUAL';
    if (up.contains('CANTEIRO')) return 'CANTEIRO';

    var cleaned =
    raw.replaceAll(RegExp(r'\b(LE|CE|LD)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return cleaned.toUpperCase();
  }

  String _formatRoadName({required String laneLabel, required int estaca}) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    return side.isNotEmpty ? '$name - $side - E: $estaca' : '$name - E: $estaca';
  }

  String _formatRoadNameForMany({
    required String laneLabel,
    required Iterable<int> estacas,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    final seq = (estacas.toList()..sort()).join(', ');
    final base = side.isNotEmpty ? '$name - $side' : name;
    return '$base - E(s):$seq';
  }

  @override
  void initState() {
    super.initState();

    if (context.read<ScheduleRoadBloc?>() == null) {
      throw FlutterError(
        'ScheduleBloc não encontrado no contexto. '
            'Envolva ScheduleRoadPage com BlocProvider(create: (_) => ScheduleRoadBoardBloc()).',
      );
    }

    final km = widget.contractData?.contractExtKm ?? 0.0;
    final totalEstacas = ((km * 1000) / 20).ceil();
    final contractId = widget.contractData?.id ?? '';

    context.read<ScheduleRoadBloc>().add(
      ScheduleWarmupRequested(
        contractId: contractId,
        totalEstacas: totalEstacas,
        initialServiceKey: 'geral',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ScheduleRoadBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.contractData?.id ?? '';
    final newId = widget.contractData?.id ?? '';
    if (oldId != newId) {
      final km = widget.contractData?.contractExtKm ?? 0.0;
      final totalEstacas = ((km * 1000) / 20).ceil();
      final contractId = widget.contractData?.id ?? '';
      context.read<ScheduleRoadBloc>().add(
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
    return BlocConsumer<ScheduleRoadBloc, ScheduleRoadState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (ctx, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Erro: ${state.error}')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                      child: Container(
                        color: Colors.white,
                        child: _gridOrPlaceholder(state),
                      ),
                    ),
                  ),
                ],
              ),
              // 🔻 REMOVIDO: os botões de serviço agora ficam no Workspace (UpBar)
              // Positioned(
              //   bottom: 16,
              //   right: 14,
              //   child: ScheduleMenuButtons(...),
              // ),
            ],
          ),
        );
      },
    );
  }

  // ===================== Grid/Placeholder =====================
  Widget _gridOrPlaceholder(ScheduleRoadState state) {
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
      return const Center(
        child: Text(
          'Nenhuma faixa definida.\nAbra o painel "Editar" para configurar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }

    return ScheduleGrid(
      headerHeight: kHeaderHeight,
      totalEstacas: state.totalEstacas,
      faixas: state.lanes,
      execucoes: state.execucoes,
      execIndex: state.execIndex,
      servicoSelecionado: state.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: kEstacaWidth,
      getSquareColor: state.squareColor,
      onTapSquare: (ScheduleRoadData e) => _onTapSquare(e, state),
      onDragStart: (int e, int f) => _onDragStart(e, f),
      onDragUpdate: (int e, int f) => _onDragUpdate(e, f, state),
      onDragEnd: _onDragEnd,
      selectedKeys: _selectedKeys,
      highlightColor: Colors.blueAccent,
    );
  }

  // ===================== Interações (UI-only) =====================
  // (restante inalterado)
  Future<void> _onTapSquare(ScheduleRoadData e, ScheduleRoadState state) async {
    if (_isDragging || _modalOpen) return;
    if (!state.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }
    final cellKey = '${e.numero}_${e.faixaIndex}';
    setState(() => _selectedKeys..clear()..add(cellKey));

    try {
      _modalOpen = true;
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

      final initialStatus = _statusFromString(e.status);
      final laneLabel = state.lanes[e.faixaIndex].label;
      final initialNameForRoad =
      _formatRoadName(laneLabel: laneLabel, estaca: e.numero);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: BlocProvider.value(
                  value: context.read<ScheduleRoadBloc>(),
                  child: ScheduleModalSquare(
                    currentUserId: _uid,
                    tipoLabel: state.titleForHeader,
                    type: ScheduleType.rodoviario,
                    initialName: initialNameForRoad,
                    targets: [
                      ScheduleApplyTarget(
                        estaca: e.numero,
                        faixaIndex: e.faixaIndex,
                        existingUrls: e.fotos,
                        existingMetaByUrl: metaByUrl,
                      ),
                    ],
                    initialStatus: initialStatus,
                    initialTakenAt: e.takenAt,
                    initialComment: e.comentario,
                  ),
                ),
              ),
            ),
          );
        },
      );

      context
          .read<ScheduleRoadBloc>()
          .add(const ScheduleExecucoesReloadRequested());
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
    if (_modalOpen) return;
    _isDragging = true;
    setState(() {
      _anchorEstaca = estaca;
      _anchorFaixa = faixa;
      _selectedKeys
        ..clear()
        ..add('${estaca}_$faixa');
    });
  }

  void _onDragUpdate(int estaca, int faixa, ScheduleRoadState state) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) return;
    final sel =
    state.selectionBetween(_anchorEstaca!, _anchorFaixa!, estaca, faixa);
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
      _openBulkWithUnifiedModal();
    } else {
      setState(() => _selectedKeys.clear());
    }
  }

  Future<void> _openBulkWithUnifiedModal() async {
    final state = context.read<ScheduleRoadBloc>().state;
    if (!state.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }
    if (_selectedKeys.length <= 1 || _modalOpen) return;

    final List<ScheduleApplyTarget> targets = [];
    final estacasSelecionadas = <int>[];
    for (final key in _selectedKeys) {
      final parts = key.split('_');
      if (parts.length != 2) continue;
      final estaca = int.tryParse(parts[0]);
      final faixa = int.tryParse(parts[1]);
      if (estaca == null || faixa == null) continue;

      estacasSelecionadas.add(estaca);
      final fotosAtuais = state.fotosAtuaisFor(estaca, faixa);
      targets.add(ScheduleApplyTarget(
        estaca: estaca,
        faixaIndex: faixa,
        existingUrls: fotosAtuais,
        existingMetaByUrl: const {},
      ));
    }

    final laneLabel = state.lanes[_anchorFaixa ?? 0].label;
    final initialNameMany = _formatRoadNameForMany(
      laneLabel: laneLabel,
      estacas: estacasSelecionadas,
    );

    _modalOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: BlocProvider.value(
                  value: context.read<ScheduleRoadBloc>(),
                  child: ScheduleModalSquare(
                    currentUserId: _uid,
                    tipoLabel: state.titleForHeader,
                    type: ScheduleType.rodoviario,
                    initialName: initialNameMany,
                    targets: targets,
                  ),
                ),
              ),
            ),
          );
        },
      );

      context
          .read<ScheduleRoadBloc>()
          .add(const ScheduleExecucoesReloadRequested());
      _toast('Aplicado em lote: ${targets.length} célula(s).');
    } catch (e) {
      _toast('Falha no lote: $e');
    } finally {
      _modalOpen = false;
      if (mounted) setState(() => _selectedKeys.clear());
    }
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
            child: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}
