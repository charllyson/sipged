// lib/screens/modules/operation/schedule/linear/schedule_linear_board.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/buttons/slider_button.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/board/grid/schedule_grid.dart';

class ScheduleLinearBoard extends StatefulWidget {
  const ScheduleLinearBoard({
    super.key,
    this.contractData,
    required this.extensao,
  });

  final ContractData? contractData;
  final double extensao;

  @override
  State<ScheduleLinearBoard> createState() => _ScheduleLinearBoardState();
}

class _ScheduleLinearBoardState extends State<ScheduleLinearBoard>
    with AutomaticKeepAliveClientMixin {
  static const String _cellWidthPrefsKey = 'schedule_linear_board_cell_width';

  static const double _initialCellWidth = 22.5;
  static const double _minCellWidth = 3.0;
  static const double _maxCellWidth = 52.0;
  static const double _cellWidthStep = 0.5;

  final ValueNotifier<double> _cellWidthNotifier =
  ValueNotifier<double>(_initialCellWidth);

  Timer? _saveCellWidthDebounce;

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
      context.read<ScheduleLinearCubit>();
    } catch (_) {
      throw FlutterError(
        'ScheduleLinearCubit não encontrado no contexto. '
            'Envolva ScheduleLinearBoard com BlocProvider(create: (_) => ScheduleLinearCubit(...)).',
      );
    }

    _loadSavedCellWidth();
  }

  @override
  void dispose() {
    _saveCellWidthDebounce?.cancel();
    _cellWidthNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureUsersLoadedOnce();
  }

  String _cellKey({
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return '${serviceKey.trim()}_${faixaIndex}_$estaca';
  }

  Future<void> _loadSavedCellWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getDouble(_cellWidthPrefsKey);

      if (savedValue == null) return;

      final safeValue = savedValue.clamp(
        _minCellWidth,
        _maxCellWidth,
      ).toDouble();

      if (_cellWidthNotifier.value == safeValue) return;

      _cellWidthNotifier.value = safeValue;
    } catch (_) {
      // Mantém o valor padrão em caso de falha local.
    }
  }

  void _persistCellWidthDebounced(double value) {
    _saveCellWidthDebounce?.cancel();

    _saveCellWidthDebounce = Timer(
      const Duration(milliseconds: 350),
          () async {
        try {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setDouble(
            _cellWidthPrefsKey,
            value,
          );
        } catch (_) {
          // Não bloqueia a tela em caso de falha ao salvar preferência local.
        }
      },
    );
  }

  void _setCellWidth(double value) {
    final next = value.clamp(_minCellWidth, _maxCellWidth).toDouble();

    if (_cellWidthNotifier.value == next) return;

    _cellWidthNotifier.value = next;
    _persistCellWidthDebounced(next);
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

    final contract = widget.contractData ?? ContractData.empty();

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

  ScheduleStatus _scheduleStatusFromCellStatus(ScheduleLinearCellStatus status) {
    switch (status) {
      case ScheduleLinearCellStatus.concluido:
        return ScheduleStatus.concluido;

      case ScheduleLinearCellStatus.emAndamento:
        return ScheduleStatus.emAndamento;

      case ScheduleLinearCellStatus.aIniciar:
        return ScheduleStatus.aIniciar;
    }
  }

  Map<String, Map<String, dynamic>> _photoMetaByUrlFromCell(
      ScheduleLinearCellData cell,
      ) {
    final metaByUrl = <String, Map<String, dynamic>>{};

    for (final rawMeta in cell.fotosMeta) {
      final meta = Map<String, dynamic>.from(rawMeta);
      final url = meta['url']?.toString().trim() ?? '';

      if (url.isEmpty) continue;

      metaByUrl[url] = <String, dynamic>{
        ...meta,
        'id': meta['id']?.toString() ?? url,
        'url': url,
        'name': meta['name']?.toString() ?? url.split('/').last,
      };
    }

    for (final url in cell.fotos) {
      final cleanUrl = url.trim();

      if (cleanUrl.isEmpty) continue;
      if (metaByUrl.containsKey(cleanUrl)) continue;

      metaByUrl[cleanUrl] = <String, dynamic>{
        'id': cleanUrl,
        'url': cleanUrl,
        'name': cleanUrl.split('/').last,
        if (cell.primaryDate != null)
          'takenAtMs': cell.primaryDate!.millisecondsSinceEpoch,
      };
    }

    return metaByUrl;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userLabelResolver = context.select<UserCubit, String Function(String?)>(
          (cubit) => cubit.state.labelFor,
    );

    return BlocListener<ScheduleLinearCubit, ScheduleLinearState>(
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
      child: BlocSelector<ScheduleLinearCubit, ScheduleLinearState,
          _BoardGridVm>(
        selector: (state) => _BoardGridVm(
          initialized: state.initialized,
          loadingLanes: state.loadingLanes,
          totalEstacas: state.totalEstacas,
          lanes: state.lanes,
          services: state.services,
          execIndex: state.execIndex,
          currentServiceKey: state.currentServiceKey,
          canEditSingleCell: state.canEditSingleCell,
          canBulkApply: state.canBulkApply,
          titleForHeader: state.titleForHeader,
          dateFilterSignature: state.dateFilterSignature,
          dateFilterActive: state.dateFilterActive,
          dateFilterCellKeysHash: Object.hashAll(
            state.dateFilterCellKeys.toList()..sort(),
          ),
          execRevision: state.execRevision,//
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
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ValueListenableBuilder<double>(
                            valueListenable: _cellWidthNotifier,
                            builder: (context, cellWidth, _) {
                              return _ScheduleRoadBoardGridView(
                                vm: vm,
                                estacaWidth: cellWidth,
                                selectedByEstaca: _selectedByEstaca,
                                userLabelResolver: userLabelResolver,
                                onTapSquare: _onTapSquare,
                                onDragStart: _onDragStart,
                                onDragUpdate: _onDragUpdate,
                                onDragEnd: _onDragEnd,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: SliderButton(
                            zoomListenable: _cellWidthNotifier,
                            minZoom: _minCellWidth,
                            maxZoom: _maxCellWidth,
                            step: _cellWidthStep,
                            sliderHeight: 140,
                            buttonWidth: 34,
                            buttonHeight: 34,
                            borderRadius: 10,
                            backgroundColor:
                            Colors.black.withValues(alpha: 0.42),
                            onZoomChanged: _setCellWidth,
                          ),
                        ),
                      ],
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
      ScheduleLinearCellData cell,
      _BoardGridVm vm,
      ) async {
    if (_isDragging || _modalOpen) return;

    if (!vm.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final scheduleCubit = context.read<ScheduleLinearCubit>();
    final scaffoldContext = context;
    final state = scheduleCubit.state;

    if (cell.faixaIndex < 0 || cell.faixaIndex >= state.lanes.length) {
      _toast(
        'Faixa inválida para edição.',
        type: NotificationStatus.error,
      );
      return;
    }

    final cellSelectionKey = '${cell.numero}_${cell.faixaIndex}';

    final existedBefore = state.execIndex.containsKey(
      _cellKey(
        serviceKey: state.currentServiceKey,
        estaca: cell.numero,
        faixaIndex: cell.faixaIndex,
      ),
    );

    setState(() {
      _selectedByEstaca = _groupSelection({cellSelectionKey});
    });

    try {
      _modalOpen = true;

      final metaByUrl = _photoMetaByUrlFromCell(cell);

      final initialStatus = _scheduleStatusFromCellStatus(cell.status);
      final laneLabel = state.lanes[cell.faixaIndex].laneLabel;

      final initialNameForRoad = _formatRoadName(
        laneLabel: laneLabel,
        estaca: cell.numero,
      );

      final saved = await showModalBottomSheet<bool>(
        context: scaffoldContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: scheduleCubit,
              child: ScheduleModalWidget(
                currentUserId: _uid,
                tipoLabel: state.titleForHeader,
                type: ScheduleType.rodoviario,
                initialName: initialNameForRoad,
                targets: [
                  ScheduleApplyTarget(
                    estaca: cell.numero,
                    faixaIndex: cell.faixaIndex,
                    existingUrls: cell.fotos,
                    existingMetaByUrl: metaByUrl,
                  ),
                ],
                initialStatus: initialStatus,
                initialTakenAt: cell.takenAt,
                initialComment: cell.comentario,
              ),
            ),
          );
        },
      );

      if (saved != true) {
        return;
      }

      await scheduleCubit.reloadExecucoes();

      if (!mounted) return;

      final afterState = scheduleCubit.state;

      final existsAfter = afterState.execIndex.containsKey(
        _cellKey(
          serviceKey: afterState.currentServiceKey,
          estaca: cell.numero,
          faixaIndex: cell.faixaIndex,
        ),
      );

      final wasDeleted = existedBefore && !existsAfter;

      await _notifySchedule(
        title: state.titleForHeader,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action':
          wasDeleted ? 'schedule_stake_deleted' : 'schedule_stake_saved',
          'serviceKey': state.currentServiceKey,
          'serviceLabel': state.titleForHeader,
          'estaca': cell.numero,
          'faixaIndex': cell.faixaIndex,
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

    final sel = context.read<ScheduleLinearCubit>().state.selectionBetween(
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
    final scheduleCubit = context.read<ScheduleLinearCubit>();
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

      final cellIndexKey = _cellKey(
        serviceKey: state.currentServiceKey,
        estaca: estaca,
        faixaIndex: faixa,
      );

      if (state.execIndex[cellIndexKey] != null) {
        existingBefore.add('${estaca}_$faixa');
      }

      final fotosAtuais = state.fotosAtuaisFor(estaca, faixa);

      targets.add(
        ScheduleApplyTarget(
          estaca: estaca,
          faixaIndex: faixa,
          existingUrls: fotosAtuais,
          existingMetaByUrl: const <String, Map<String, dynamic>>{},
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
      final saved = await showModalBottomSheet<bool>(
        context: scaffoldContext,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: scheduleCubit,
              child: ScheduleModalWidget(
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

      if (saved != true) {
        return;
      }

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

        final afterKey = _cellKey(
          serviceKey: afterState.currentServiceKey,
          estaca: estaca,
          faixaIndex: faixa,
        );

        if (afterState.execIndex[afterKey] == null) {
          deletedCount++;
        }
      }

      final hasDeleted = deletedCount > 0;

      await _notifySchedule(
        title: state.titleForHeader,
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
    required this.estacaWidth,
    required this.selectedByEstaca,
    required this.userLabelResolver,
    required this.onTapSquare,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final _BoardGridVm vm;
  final double estacaWidth;
  final Map<int, Set<int>> selectedByEstaca;
  final String Function(String? uid) userLabelResolver;
  final Future<void> Function(ScheduleLinearCellData e, _BoardGridVm vm)
  onTapSquare;
  final void Function(int estaca, int faixa) onDragStart;
  final void Function(int estaca, int faixa, _BoardGridVm vm) onDragUpdate;
  final VoidCallback onDragEnd;

  static const double kLegendWidth = 100.0;
  static const double kHeaderHeight = 40.0;
  static const double kGhostWidth = 22.5;

  Color _resolveSquareColor({
    required ScheduleLinearState state,
    required ScheduleLinearCellData cell,
  }) {
    if (!state.hasActiveDateFilter) {
      if (state.isGeral) {
        final dominantCell = state.dominantCellForGeral(
          estaca: cell.numero,
          faixa: cell.faixaIndex,
        );

        return state.squareColor(dominantCell ?? cell);
      }

      final realCell = state.cellAt(
        serviceKey: state.currentServiceKey,
        estaca: cell.numero,
        faixa: cell.faixaIndex,
      );

      return state.squareColor(realCell ?? cell);
    }

    if (state.isGeral) {
      final dominantCell = state.dominantCellForGeral(
        estaca: cell.numero,
        faixa: cell.faixaIndex,
      );

      if (dominantCell == null) {
        return const Color(0xFFE0E0E0);
      }

      return state.squareColor(dominantCell);
    }

    final realCell = state.cellAt(
      serviceKey: state.currentServiceKey,
      estaca: cell.numero,
      faixa: cell.faixaIndex,
    );

    if (realCell == null) {
      return const Color(0xFFE0E0E0);
    }

    return state.squareColor(realCell);
  }

  @override
  Widget build(BuildContext context) {
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
      key: ValueKey<String>(
        'schedule-grid-'
            '${vm.currentServiceKey}-'
            '${vm.totalEstacas}-'
            '${vm.execRevision}-'
            '${vm.dateFilterSignature}-'
            '${vm.dateFilterActive}-'
            '${vm.dateFilterCellKeysHash}',
      ),
      headerHeight: kHeaderHeight,
      totalEstacas: vm.totalEstacas,
      faixas: vm.lanes,
      services: vm.services,
      execIndex: vm.execIndex,
      servicoSelecionado: vm.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: estacaWidth,
      ghostWidth: kGhostWidth,
      getSquareColor: (cell) {
        final state = context.read<ScheduleLinearCubit>().state;

        return _resolveSquareColor(
          state: state,
          cell: cell,
        );
      },
      onTapSquare: (cell) => onTapSquare(cell, vm),
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
  const _BoardGridVm({
    required this.initialized,
    required this.loadingLanes,
    required this.totalEstacas,
    required this.lanes,
    required this.services,
    required this.execIndex,
    required this.currentServiceKey,
    required this.canEditSingleCell,
    required this.canBulkApply,
    required this.titleForHeader,
    required this.dateFilterSignature,
    required this.dateFilterActive,
    required this.dateFilterCellKeysHash,
    required this.execRevision,
  });

  final bool initialized;
  final bool loadingLanes;
  final int totalEstacas;
  final List<ScheduleLinearLaneData> lanes;
  final List<ScheduleLinearServicesData> services;
  final Map<String, ScheduleLinearCellData> execIndex;
  final String currentServiceKey;
  final bool canEditSingleCell;
  final bool canBulkApply;
  final String titleForHeader;
  final int dateFilterSignature;
  final bool dateFilterActive;
  final int dateFilterCellKeysHash;
  final int execRevision;

  @override
  bool operator ==(Object other) {
    return other is _BoardGridVm &&
        other.initialized == initialized &&
        other.loadingLanes == loadingLanes &&
        other.totalEstacas == totalEstacas &&
        identical(other.lanes, lanes) &&
        identical(other.services, services) &&
        identical(other.execIndex, execIndex) &&
        other.currentServiceKey == currentServiceKey &&
        other.canEditSingleCell == canEditSingleCell &&
        other.canBulkApply == canBulkApply &&
        other.titleForHeader == titleForHeader &&
        other.dateFilterSignature == dateFilterSignature &&
        other.dateFilterActive == dateFilterActive &&
        other.dateFilterCellKeysHash == dateFilterCellKeysHash &&
        other.execRevision == execRevision;
  }

  @override
  int get hashCode => Object.hash(
    initialized,
    loadingLanes,
    totalEstacas,
    identityHashCode(lanes),
    identityHashCode(services),
    identityHashCode(execIndex),
    currentServiceKey,
    canEditSingleCell,
    canBulkApply,
    titleForHeader,
    dateFilterSignature,
    dateFilterActive,
    dateFilterCellKeysHash,
    execRevision,
  );
}