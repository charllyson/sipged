import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// UI base
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/modals/type.dart';
import 'package:siged/_widgets/schedule/linear/schedule_header.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

// Domínio / dados
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_data.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';

// Widgets do Schedule
import 'package:siged/_widgets/schedule/linear/schedule_grid.dart';
import 'package:siged/_widgets/schedule/linear/schedule_menu_buttons.dart';
import 'package:siged/_widgets/schedule/linear/schedule_sub_header.dart';

// Modal unificado
import 'package:siged/_widgets/modals/schedule_modal_square.dart';

// Editor de faixas
import 'package:siged/_widgets/schedule/linear/schedule_lane_edit_section.dart';

// BLoC
import 'package:siged/_blocs/sectors/operation/road/schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_state.dart';

// Status enum
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';

// Metadados por URL pro carrossel
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadPage extends StatefulWidget {
  final ContractData? contractData;
  const ScheduleRoadPage({super.key, this.contractData});

  @override
  State<ScheduleRoadPage> createState() => _ScheduleRoadPageState();
}

class _ScheduleRoadPageState extends State<ScheduleRoadPage> {
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
    return (m?.group(1) ?? '').toUpperCase(); // "LE" | "CE" | "LD" | ""
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

    if (context.read<ScheduleBloc?>() == null) {
      throw FlutterError(
        'ScheduleBloc não encontrado no contexto. '
            'Envolva ScheduleRoadPage com BlocProvider(create: (_) => ScheduleBloc()).',
      );
    }

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
  void didUpdateWidget(covariant ScheduleRoadPage oldWidget) {
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
        final isLoading =
            state.loadingServices || state.loadingLanes || state.loadingExecucoes;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UpBar(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,            // ⬅️ shrink-wrap
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 12),
                        const BackCircleButton(),
                        const SizedBox(width: 12),
                        Flexible(                                // ⬅️ nada de Expanded aqui
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,      // ⬅️ shrink-wrap na coluna também
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScheduleHeader(
                                title: state.titleForHeader,
                                colorStripe: state.colorForHeader,
                                leftPadding: 0,
                              ),
                              const SizedBox(height: 6),
                              ScheduleSubHeader(
                                isLoading: isLoading,
                                pctConcluido: state.pctConcluido,
                                pctAndamento: state.pctAndamento,
                                pctAIniciar: state.pctAIniciar,
                                leftPadding: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


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
      execIndex: state.execIndex,
      servicoSelecionado: state.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: kEstacaWidth,
      getSquareColor: state.squareColor,
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
    if (_isDragging || _modalOpen) return;

    if (!state.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final cellKey = '${e.numero}_${e.faixaIndex}';
    setState(() => _selectedKeys..clear()..add(cellKey));

    try {
      _modalOpen = true;

      // Metadados por URL (carrossel)
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

      // >>> nome da faixa + lado + estaca
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
                  value: context.read<ScheduleBloc>(),
                  child: ScheduleModalSquare(
                    currentUserId: _uid,
                    tipoLabel: state.titleForHeader,
                    type: ScheduleType.rodoviario,

                    // Nome conforme padrão solicitado
                    initialName: initialNameForRoad,

                    // Unitário: 1 alvo
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

  void _onDragUpdate(int estaca, int faixa, ScheduleState state) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) return;
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
      _openBulkWithUnifiedModal();
    } else {
      setState(() => _selectedKeys.clear());
    }
  }

  Future<void> _openBulkWithUnifiedModal() async {
    final state = context.read<ScheduleBloc>().state;

    if (!state.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }
    if (_selectedKeys.length <= 1 || _modalOpen) return;

    // Monta os alvos do lote
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
      targets.add(
        ScheduleApplyTarget(
          estaca: estaca,
          faixaIndex: faixa,
          existingUrls: fotosAtuais,
          existingMetaByUrl: const {},
        ),
      );
    }

    // Nome para múltiplas estacas
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
                  value: context.read<ScheduleBloc>(),
                  child: ScheduleModalSquare(
                    currentUserId: _uid,
                    tipoLabel: state.titleForHeader,
                    type: ScheduleType.rodoviario,

                    // Nome com sequência de estacas
                    initialName: initialNameMany,

                    // Lote
                    targets: targets,
                  ),
                ),
              ),
            ),
          );
        },
      );

      context.read<ScheduleBloc>().add(const ScheduleExecucoesReloadRequested());
      _toast('Aplicado em lote: ${targets.length} célula(s).');
    } catch (e) {
      _toast('Falha no lote: $e');
    } finally {
      _modalOpen = false;
      if (mounted) setState(() => _selectedKeys.clear());
    }
  }

  Future<void> _editLanes(List<ScheduleLaneClass> current) async {
    final st = context.read<ScheduleBloc>().state;

    final rows = await showDialog<List<ScheduleLaneClass>>(
      context: context,
      builder: (_) => ScheduleLaneEdit(
        initialRows: current,
        selectedServiceKey: st.currentServiceKey,
        selectedServiceLabel: st.titleForHeader,
      ),
    );

    if (rows != null) {
      context.read<ScheduleBloc>().add(ScheduleLanesSaveRequested(rows));
      _toast('Faixas atualizadas.');
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
            child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}
