import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Domínio / dados
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';

// Widgets do Schedule
import 'package:sipged/_widgets/schedule/linear/schedule_grid.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_status.dart';
import 'package:sipged/_widgets/schedule/modal/type.dart';

// Modal unificado
import 'package:sipged/screens/modules/operation/schedule/physical/road/schedule_modal_square.dart';

// Cubit
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

// Usuários
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_event.dart';

// Metadados por URL pro carrossel
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

// Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

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
  static const double kLegendWidth = 100.0;
  static const double kEstacaWidth = 22.5;
  static const double kHeaderHeight = 40.0;

  final _selectedKeys = <String>{};
  bool _isDragging = false;
  int? _anchorEstaca;
  int? _anchorFaixa;
  bool _modalOpen = false;
  bool _requestedUsersLoad = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureUsersLoadedOnce();
  }

  void _ensureUsersLoadedOnce() {
    if (_requestedUsersLoad) return;

    final userBloc = context.read<UserBloc>();
    final userState = userBloc.state;

    if (!userState.initialized && userState.all.isEmpty) {
      _requestedUsersLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        userBloc.add(
          const UsersEnsureLoadedRequested(listenRealtime: true),
        );
      });
    }
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
  Widget build(BuildContext context) {
    super.build(context);

    final userLabelResolver = context.select<UserBloc, String Function(String?)>(
          (bloc) => bloc.state.labelFor,
    );

    return BlocConsumer<ScheduleRoadCubit, ScheduleRoadState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (ctx, state) {
        if (state.error != null) {
          NotificationCenter.instance.show(
            AppNotification(
              type: AppNotificationType.error,
              title: Text('Erro: ${state.error}'),
              leadingIcon: const Icon(
                Icons.error_outline,
                color: Color(0xFFD32F2F),
              ),
              leadingLabel: const Text('Cronograma'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: state.initialized
                    ? Container(
                  color: Colors.white,
                  child: _gridOrPlaceholder(
                    state,
                    userLabelResolver,
                  ),
                )
                    : const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _gridOrPlaceholder(
      ScheduleRoadState state,
      String Function(String? uid) userLabelResolver,
      ) {
    if (!state.initialized) {
      return const SizedBox.shrink();
    }

    if (state.loadingLanes) {
      return const SizedBox.shrink();
    }

    if (state.lanes.isEmpty) {
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
      totalEstacas: state.totalEstacas,
      faixas: state.lanes,
      execucoes: state.execucoes,
      execIndex: state.execIndex,
      servicoSelecionado: state.currentServiceKey,
      legendWidth: kLegendWidth,
      estacaWidth: kEstacaWidth,
      getSquareColor: state.squareColor,
      onTapSquare: (e) => _onTapSquare(e, state),
      onDragStart: _onDragStart,
      onDragUpdate: (e, f) => _onDragUpdate(e, f, state),
      onDragEnd: _onDragEnd,
      selectedKeys: _selectedKeys,
      highlightColor: Colors.blueAccent,
      userLabelResolver: userLabelResolver,
    );
  }

  Future<void> _onTapSquare(
      ScheduleRoadData e,
      ScheduleRoadState state,
      ) async {
    if (_isDragging || _modalOpen) return;

    if (!state.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    final scheduleCubit = context.read<ScheduleRoadCubit>();
    final scaffoldContext = context;

    final cellKey = '${e.numero}_${e.faixaIndex}';
    setState(() {
      _selectedKeys
        ..clear()
        ..add(cellKey);
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
              : ((m['takenAt'] is num)
              ? DateTime.fromMillisecondsSinceEpoch(
            (m['takenAt'] as num).toInt(),
          )
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
      _toast(
        'Célula atualizada com sucesso!',
        type: AppNotificationType.success,
      );
    } catch (err) {
      _toast(
        'Falha ao salvar a célula: $err',
        type: AppNotificationType.error,
      );
    } finally {
      _modalOpen = false;
      if (mounted) {
        setState(() => _selectedKeys.clear());
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
    setState(() {
      _anchorEstaca = estaca;
      _anchorFaixa = faixa;
      _selectedKeys
        ..clear()
        ..add('${estaca}_$faixa');
    });
  }

  void _onDragUpdate(
      int estaca,
      int faixa,
      ScheduleRoadState state,
      ) {
    if (!_isDragging || _anchorEstaca == null || _anchorFaixa == null) return;

    final sel = state.selectionBetween(
      _anchorEstaca!,
      _anchorFaixa!,
      estaca,
      faixa,
    );

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
    final scheduleCubit = context.read<ScheduleRoadCubit>();
    final scaffoldContext = context;
    final state = scheduleCubit.state;

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
      setState(() => _selectedKeys.clear());
      return;
    }

    final laneLabel = state.lanes[_anchorFaixa ?? 0].label;
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
      _toast(
        'Aplicado em lote: ${targets.length} célula(s).',
        type: AppNotificationType.success,
      );
    } catch (e) {
      _toast('Falha no lote: $e', type: AppNotificationType.error);
    } finally {
      _modalOpen = false;
      if (mounted) {
        setState(() => _selectedKeys.clear());
      }
    }
  }

  void _toast(
      String msg, {
        AppNotificationType type = AppNotificationType.info,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        type: type,
        title: Text(msg),
        leadingLabel: const Text('Aviso'),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}