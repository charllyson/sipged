// lib/screens/modules/operation/schedule/physical/horizontal/schedule_road_board.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_grid.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_modal_square.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/schedule_road_debug.dart';
import 'package:sipged/screens/modules/operation/schedule/horizontal/type.dart';

class ScheduleRoadBoard extends StatefulWidget {
  final ProcessData? contractData;
  final double extensao;

  const ScheduleRoadBoard({
    super.key,
    this.contractData,
    required this.extensao,
  });

  @override
  State<ScheduleRoadBoard> createState() => _ScheduleRoadBoardState();
}

class _ScheduleRoadBoardState extends State<ScheduleRoadBoard>
    with AutomaticKeepAliveClientMixin {
  Map<int, Set<int>> _selectedByEstaca = <int, Set<int>>{};

  bool _isDragging = false;
  int? _anchorEstaca;
  int? _anchorFaixa;
  int? _lastDragEstaca;
  int? _lastDragFaixa;
  bool _modalOpen = false;
  bool _requestedUsersLoad = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    try {
      context.read<ScheduleRoadCubit>();
    } catch (_) {
      throw FlutterError(
        'ScheduleRoadCubit não encontrado no contexto. '
            'Envolva ScheduleRoadBoard com BlocProvider(create: (_) => ScheduleRoadCubit()).',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureUsersLoadedOnce();
  }

  void _ensureUsersLoadedOnce() {
    if (_requestedUsersLoad) return;

    final userCubit = context.read<UserCubit>();
    final userState = userCubit.state;

    if (!userState.initialized && userState.all.isEmpty) {
      _requestedUsersLoad = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        userCubit.warmup(
          listenRealtime: true,
          bindCurrentUser: true,
        );
      });
    }
  }

  void _toast(
      String msg, {
        NotificationStatus type = NotificationStatus.info,
        Duration duration = const Duration(seconds: 8),
      }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: msg,
        leadingLabel: 'Cronograma',
        type: type,
        duration: duration,
      ),
    );
  }

  String _actorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _notifySchedule({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = true,
    bool sendPush = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final actorId = currentUser?.uid.trim();
    final actorName = _actorName();

    final contract = widget.contractData ?? ProcessData.empty();

    await NotificationSchedule.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: 'Cronograma',
      module: 'operation_schedule_road',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: actorId,
      actorName: actorName,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'module': 'operation_schedule_road',
        'route': 'operation_schedule_road',
        'source': 'schedule_road_board',
        'actorId': actorId,
        'actorName': actorName,
        if ((contract.id ?? '').trim().isNotEmpty) 'contractId': contract.id,
        if (contract.displaySummary.trim().isNotEmpty)
          'contractSummary': contract.displaySummary,
        ...extra,
      },
    );
  }

  String _extractSide(String raw) {
    final m = RegExp(
      r'\b(LE|CE|LD)\b',
      caseSensitive: false,
    ).firstMatch(raw.toUpperCase());

    return (m?.group(1) ?? '').toUpperCase();
  }

  String _cleanLaneName(String raw) {
    final up = raw.toUpperCase();

    if (up.contains('DUPLICA')) return 'DUPLICAÇÃO';
    if (up.contains('PISTA ATUAL')) return 'PISTA ATUAL';
    if (up.contains('CANTEIRO')) return 'CANTEIRO';

    var cleaned = raw.replaceAll(
      RegExp(r'\b(LE|CE|LD)\b', caseSensitive: false),
      '',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return cleaned.toUpperCase();
  }

  String _formatRoadName({
    required String laneLabel,
    required int estaca,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);

    return side.isNotEmpty
        ? '$name - $side - E: $estaca'
        : '$name - E: $estaca';
  }

  String _formatRoadNameForMany({
    required String laneLabel,
    required Iterable<int> estacas,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    final seq = (estacas.toList()..sort()).join(', ');
    final base = side.isNotEmpty ? '$name - $side' : name;

    return '$base - E(s): $seq';
  }

  Map<int, Set<int>> _groupSelection(Set<String> keys) {
    final out = <int, Set<int>>{};

    for (final key in keys) {
      final parts = key.split('_');

      if (parts.length != 2) continue;

      final estaca = int.tryParse(parts[0]);
      final faixa = int.tryParse(parts[1]);

      if (estaca == null || faixa == null) continue;

      out.putIfAbsent(estaca, () => <int>{}).add(faixa);
    }

    return out;
  }

  Set<String> _flattenSelection(Map<int, Set<int>> grouped) {
    final out = <String>{};

    grouped.forEach((estaca, faixas) {
      for (final faixa in faixas) {
        out.add('${estaca}_$faixa');
      }
    });

    return out;
  }

  bool _sameGroupedSelection(
      Map<int, Set<int>> a,
      Map<int, Set<int>> b,
      ) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      final other = b[entry.key];

      if (other == null) return false;
      if (entry.value.length != other.length) return false;

      for (final v in entry.value) {
        if (!other.contains(v)) return false;
      }
    }

    return true;
  }

  void _clearSelection() {
    _selectedByEstaca = <int, Set<int>>{};
    _lastDragEstaca = null;
    _lastDragFaixa = null;
  }

  int get _selectedCount => _flattenSelection(_selectedByEstaca).length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userLabelResolver = context.select<UserCubit, String Function(String?)>(
          (cubit) => cubit.state.labelFor,
    );

    ScheduleRoadDebug.log(
      'Board',
      'rebuild => modalOpen=$_modalOpen, selected=$_selectedCount',
    );

    return BlocListener<ScheduleRoadCubit, ScheduleRoadState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (ctx, state) {
        if (state.error != null) {
          _toast(
            'Erro: ${state.error}',
            type: NotificationStatus.error,
            duration: const Duration(seconds: 5),
          );
        }
      },
      child: BlocSelector<ScheduleRoadCubit, ScheduleRoadState, _BoardGridVm>(
        selector: (state) => _BoardGridVm(
          initialized: state.initialized,
          loadingLanes: state.loadingLanes,
          totalEstacas: state.totalEstacas,
          lanes: state.lanes,
          execIndex: state.execIndex,
          currentServiceKey: state.currentServiceKey,
          canEditSingleCell: state.canEditSingleCell,
          canBulkApply: state.canBulkApply,
          titleForHeader: state.titleForHeader,
        ),
        builder: (context, vm) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: vm.initialized
                      ? Container(
                    color: Colors.white,
                    child: _ScheduleRoadBoardGridView(
                      vm: vm,
                      selectedByEstaca: _selectedByEstaca,
                      userLabelResolver: userLabelResolver,
                      onTapSquare: _onTapSquare,
                      onDragStart: _onDragStart,
                      onDragUpdate: _onDragUpdate,
                      onDragEnd: _onDragEnd,
                    ),
                  )
                      : const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onTapSquare(
      ScheduleRoadData e,
      _BoardGridVm vm,
      ) async {
    if (_isDragging || _modalOpen) return;

    if (!vm.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final scheduleCubit = context.read<ScheduleRoadCubit>();
    final scaffoldContext = context;
    final state = scheduleCubit.state;

    if (e.faixaIndex < 0 || e.faixaIndex >= state.lanes.length) {
      _toast(
        'Faixa inválida para edição.',
        type: NotificationStatus.error,
      );
      return;
    }

    final cellKey = '${e.numero}_${e.faixaIndex}';
    final existedBefore = state.execIndex[e.numero]?[e.faixaIndex] != null;

    setState(() {
      _selectedByEstaca = _groupSelection({cellKey});
    });

    try {
      _modalOpen = true;

      final metaByUrl = <String, pm.CarouselMetadata>{};

      for (final m in e.fotosMeta) {
        final url = m['url']?.toString() ?? '';

        if (url.isEmpty) continue;

        metaByUrl[url] = pm.CarouselMetadata(
          name: m['name']?.toString(),
          takenAt: (m['takenAtMs'] is num)
              ? DateTime.fromMillisecondsSinceEpoch(
            (m['takenAtMs'] as num).toInt(),
          )
              : (m['takenAt'] is num)
              ? DateTime.fromMillisecondsSinceEpoch(
            (m['takenAt'] as num).toInt(),
          )
              : null,
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
      final laneLabel = state.lanes[e.faixaIndex].laneLabel;

      final initialNameForRoad = _formatRoadName(
        laneLabel: laneLabel,
        estaca: e.numero,
      );

      await showModalBottomSheet<void>(
        context: scaffoldContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: scheduleCubit,
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
          );
        },
      );

      await scheduleCubit.reloadExecucoes();

      if (!mounted) return;

      final afterState = scheduleCubit.state;
      final existsAfter = afterState.execIndex[e.numero]?[e.faixaIndex] != null;
      final wasDeleted = existedBefore && !existsAfter;

      await _notifySchedule(
        title: state.titleForHeader,
        subtitle: null,
        details: null,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action':
          wasDeleted ? 'schedule_stake_deleted' : 'schedule_stake_saved',
          'serviceKey': state.currentServiceKey,
          'serviceLabel': state.titleForHeader,
          'estaca': e.numero,
          'faixaIndex': e.faixaIndex,
          'stakeName': initialNameForRoad,
          'cellName': initialNameForRoad,
          'source': 'schedule_road_board',
        },
      );
    } catch (err) {
      _toast(
        'Falha ao salvar a estaca: $err',
        type: NotificationStatus.error,
      );
    } finally {
      _modalOpen = false;

      if (mounted) {
        setState(_clearSelection);
      }
    }
  }

  ScheduleStatus _statusFromString(String? s) {
    final t = (s ?? '').toLowerCase();

    if (t.contains('conclu')) return ScheduleStatus.concluido;

    if (t.contains('andament') || t.contains('progress')) {
      return ScheduleStatus.emAndamento;
    }

    return ScheduleStatus.aIniciar;
  }

  void _onDragStart(int estaca, int faixa) {
    if (_modalOpen) return;

    _isDragging = true;
    _lastDragEstaca = estaca;
    _lastDragFaixa = faixa;

    setState(() {
      _anchorEstaca = estaca;
      _anchorFaixa = faixa;
      _selectedByEstaca = <int, Set<int>>{
        estaca: <int>{faixa},
      };
    });
  }

  void _onDragUpdate(
      int estaca,
      int faixa,
      _BoardGridVm vm,
      ) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) {
      return;
    }

    if (_lastDragEstaca == estaca && _lastDragFaixa == faixa) {
      return;
    }

    _lastDragEstaca = estaca;
    _lastDragFaixa = faixa;

    final sel = context.read<ScheduleRoadCubit>().state.selectionBetween(
      _anchorEstaca!,
      _anchorFaixa!,
      estaca,
      faixa,
    );

    final grouped = _groupSelection(sel);

    if (_sameGroupedSelection(_selectedByEstaca, grouped)) return;

    setState(() {
      _selectedByEstaca = grouped;
    });
  }

  void _onDragEnd() {
    if (!_isDragging) return;

    _isDragging = false;

    if (_selectedCount > 1) {
      _openBulkWithUnifiedModal();
    } else {
      setState(_clearSelection);
    }
  }

  Future<void> _openBulkWithUnifiedModal() async {
    final scheduleCubit = context.read<ScheduleRoadCubit>();
    final scaffoldContext = context;
    final state = scheduleCubit.state;

    if (!state.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }

    final selectedKeys = _flattenSelection(_selectedByEstaca);

    if (selectedKeys.length <= 1 || _modalOpen) return;

    final List<ScheduleApplyTarget> targets = [];
    final estacasSelecionadas = <int>[];
    final existingBefore = <String>{};

    for (final key in selectedKeys) {
      final parts = key.split('_');

      if (parts.length != 2) continue;

      final estaca = int.tryParse(parts[0]);
      final faixa = int.tryParse(parts[1]);

      if (estaca == null || faixa == null) continue;

      estacasSelecionadas.add(estaca);

      if (state.execIndex[estaca]?[faixa] != null) {
        existingBefore.add('${estaca}_$faixa');
      }

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

    if (targets.isEmpty) {
      setState(_clearSelection);
      return;
    }

    final laneIndex = _anchorFaixa ?? 0;

    if (laneIndex < 0 || laneIndex >= state.lanes.length) {
      _toast(
        'Faixa inválida para edição em lote.',
        type: NotificationStatus.error,
      );
      setState(_clearSelection);
      return;
    }

    final laneLabel = state.lanes[laneIndex].laneLabel;

    final initialNameMany = _formatRoadNameForMany(
      laneLabel: laneLabel,
      estacas: estacasSelecionadas,
    );

    _modalOpen = true;

    try {
      await showModalBottomSheet<void>(
        context: scaffoldContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: scheduleCubit,
              child: ScheduleModalSquare(
                currentUserId: _uid,
                tipoLabel: state.titleForHeader,
                type: ScheduleType.rodoviario,
                initialName: initialNameMany,
                targets: targets,
              ),
            ),
          );
        },
      );

      await scheduleCubit.reloadExecucoes();

      if (!mounted) return;

      final afterState = scheduleCubit.state;

      int deletedCount = 0;

      for (final key in existingBefore) {
        final parts = key.split('_');

        if (parts.length != 2) continue;

        final estaca = int.tryParse(parts[0]);
        final faixa = int.tryParse(parts[1]);

        if (estaca == null || faixa == null) continue;

        if (afterState.execIndex[estaca]?[faixa] == null) {
          deletedCount++;
        }
      }

      final hasDeleted = deletedCount > 0;

      await _notifySchedule(
        title: state.titleForHeader,
        subtitle: null,
        details: null,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': hasDeleted
              ? 'schedule_bulk_stakes_saved_with_deletions'
              : 'schedule_bulk_stakes_saved',
          'serviceKey': state.currentServiceKey,
          'serviceLabel': state.titleForHeader,
          'targetsCount': targets.length,
          'deletedCount': deletedCount,
          'stakeName': initialNameMany,
          'cellName': initialNameMany,
          'source': 'schedule_road_board',
        },
      );
    } catch (e) {
      _toast(
        'Falha no lote: $e',
        type: NotificationStatus.error,
      );
    } finally {
      _modalOpen = false;

      if (mounted) {
        setState(_clearSelection);
      }
    }
  }
}

class _ScheduleRoadBoardGridView extends StatelessWidget {
  const _ScheduleRoadBoardGridView({
    required this.vm,
    required this.selectedByEstaca,
    required this.userLabelResolver,
    required this.onTapSquare,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final _BoardGridVm vm;
  final Map<int, Set<int>> selectedByEstaca;
  final String Function(String? uid) userLabelResolver;
  final Future<void> Function(ScheduleRoadData e, _BoardGridVm vm) onTapSquare;
  final void Function(int estaca, int faixa) onDragStart;
  final void Function(int estaca, int faixa, _BoardGridVm vm) onDragUpdate;
  final void Function() onDragEnd;

  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;
  static const double kHeaderHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    ScheduleRoadDebug.log(
      'BoardGridView',
      'rebuild => lanes=${vm.lanes.length}, execRows=${vm.execIndex.length}, service=${vm.currentServiceKey}',
    );

    if (!vm.initialized) {
      return const SizedBox.shrink();
    }

    if (vm.loadingLanes) {
      return const SizedBox.shrink();
    }

    if (vm.lanes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma faixa definida.\nAbra o painel "Editar" para configurar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      );
    }

    return ScheduleGrid(
      headerHeight: kHeaderHeight,
      totalEstacas: vm.totalEstacas,
      faixas: vm.lanes,
      execIndex: vm.execIndex,
      servicoSelecionado: vm.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: kEstacaWidth,
      getSquareColor: (e) =>
          context.read<ScheduleRoadCubit>().state.squareColor(e),
      onTapSquare: (e) => onTapSquare(e, vm),
      onDragStart: onDragStart,
      onDragUpdate: (e, f) => onDragUpdate(e, f, vm),
      onDragEnd: onDragEnd,
      selectedByEstaca: selectedByEstaca,
      highlightColor: Colors.blueAccent,
      userLabelResolver: userLabelResolver,
    );
  }
}

class _BoardGridVm {
  final bool initialized;
  final bool loadingLanes;
  final int totalEstacas;
  final List<ScheduleRoadData> lanes;
  final Map<int, Map<int, ScheduleRoadData>> execIndex;
  final String currentServiceKey;
  final bool canEditSingleCell;
  final bool canBulkApply;
  final String titleForHeader;

  const _BoardGridVm({
    required this.initialized,
    required this.loadingLanes,
    required this.totalEstacas,
    required this.lanes,
    required this.execIndex,
    required this.currentServiceKey,
    required this.canEditSingleCell,
    required this.canBulkApply,
    required this.titleForHeader,
  });

  @override
  bool operator ==(Object other) {
    return other is _BoardGridVm &&
        other.initialized == initialized &&
        other.loadingLanes == loadingLanes &&
        other.totalEstacas == totalEstacas &&
        identical(other.lanes, lanes) &&
        identical(other.execIndex, execIndex) &&
        other.currentServiceKey == currentServiceKey &&
        other.canEditSingleCell == canEditSingleCell &&
        other.canBulkApply == canBulkApply &&
        other.titleForHeader == titleForHeader;
  }

  @override
  int get hashCode => Object.hash(
    initialized,
    loadingLanes,
    totalEstacas,
    identityHashCode(lanes),
    identityHashCode(execIndex),
    currentServiceKey,
    canEditSingleCell,
    canBulkApply,
    titleForHeader,
  );
}