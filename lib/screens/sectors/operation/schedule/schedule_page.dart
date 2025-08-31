// lib/screens/sectors/operation/schedule/schedule_page.dart
import 'dart:math' as math;
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

// Editor de faixas
import 'package:siged/screens/sectors/operation/schedule/schedule_lanes_edit_section.dart';

// BLoC
import 'package:siged/_blocs/sectors/operation/schedule_bloc.dart';
import 'package:siged/_blocs/sectors/operation/schedule_event.dart';
import 'package:siged/_blocs/sectors/operation/schedule_state.dart';

// Status enum
import 'package:siged/_widgets/schedule/schedule_status.dart';

// Modal (single cell)
import 'package:siged/screens/sectors/operation/schedule/schedule_square_modal.dart';

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
          child: ScheduleSquareModal(
            estaca: e.numero,
            faixaIndex: e.faixaIndex,
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

    final res = await showModalBottomSheet<_BulkResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BulkStatusCommentSheet(count: _selectedKeys.length),
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
    if (overlay == null) return;
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

/// ======= Modal simples p/ APLICAÇÃO EM LOTE (status + comentário + data) =======

class _BulkResult {
  final ScheduleStatus status;
  final String? comment;
  final DateTime? takenAt;     // ⬅️ novo
  const _BulkResult(this.status, this.comment, this.takenAt);
}

class _BulkStatusCommentSheet extends StatefulWidget {
  final int count;
  const _BulkStatusCommentSheet({required this.count});

  @override
  State<_BulkStatusCommentSheet> createState() => _BulkStatusCommentSheetState();
}

class _BulkStatusCommentSheetState extends State<_BulkStatusCommentSheet> {
  ScheduleStatus _status = ScheduleStatus.aIniciar;
  final _commentCtrl = TextEditingController();
  DateTime? _selectedDate;                      // ⬅️ novo
  bool _busy = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.count == 1;
    final buttonLabel = isSingle ? 'Aplicar' : 'Aplicar em ${widget.count} célula(s)';
    final buttonIcon = isSingle ? Icons.done : Icons.done_all;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(isSingle ? Icons.edit : Icons.select_all_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSingle ? 'Editar célula' : 'Aplicar em lote',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status chips
              _BulkStatusChips(
                selected: _status,
                onSelect: _busy ? null : (s) => setState(() => _status = s),
              ),

              const SizedBox(height: 12),

              // Data (opcional) — aplicada a TODAS as células selecionadas
              Row(
                children: [
                  const Text('Data do serviço:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_dateLabel(_selectedDate)),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                      final init = _selectedDate ?? DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: init,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    child: Text(_selectedDate == null ? 'Definir' : 'Alterar'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Comentário
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context, null),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                        Navigator.pop<_BulkResult>(
                          context,
                          _BulkResult(
                            _status,
                            _commentCtrl.text.trim().isEmpty
                                ? null
                                : _commentCtrl.text.trim(),
                            _selectedDate, // ⬅️ novo
                          ),
                        );
                      },
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkStatusChips extends StatelessWidget {
  final ScheduleStatus selected;
  final ValueChanged<ScheduleStatus>? onSelect;
  const _BulkStatusChips({required this.selected, required this.onSelect});

  Widget _chip(BuildContext _, ScheduleStatus s) {
    final sel = s == selected;
    return Material(
      color: sel ? s.color : Colors.grey.shade200,
      shape: StadiumBorder(side: BorderSide(color: sel ? s.color : Colors.grey.shade300)),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelect == null ? null : () => onSelect!(s),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: 18, color: sel ? Colors.white : s.color),
              const SizedBox(width: 8),
              Text(
                s.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _chip(context, ScheduleStatus.concluido),
            const SizedBox(width: 8),
            _chip(context, ScheduleStatus.emAndamento),
            const SizedBox(width: 8),
            _chip(context, ScheduleStatus.aIniciar),
          ],
        ),
      ),
    );
  }
}

