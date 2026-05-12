// lib/_widgets/.../alert_validity.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class AlertValidity extends StatefulWidget {
  final ContractData contract;

  /// Opcional.
  ///
  /// Use para evitar nova consulta de DFD quando a tela/listagem já carregou
  /// esse dado previamente.
  final DfdData? dfdData;

  /// Opcional.
  ///
  /// Use para evitar nova consulta de Publicação/Extrato quando a tela/listagem
  /// já carregou esse dado previamente.
  final PublicacaoExtratoData? publicacaoData;

  const AlertValidity({
    super.key,
    required this.contract,
    this.dfdData,
    this.publicacaoData,
  });

  static void clearCache() {
    _AlertValidityState.clearCache();
  }

  @override
  State<AlertValidity> createState() => _AlertValidityState();
}

class _AlertValidityState extends State<AlertValidity>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static final Map<String, Future<_ValidityAlertInfo?>> _futureCache =
  <String, Future<_ValidityAlertInfo?>>{};

  static final Map<String, _ValidityAlertInfo?> _resultCache =
  <String, _ValidityAlertInfo?>{};

  static final Map<String, DfdRepository> _dfdRepoByTenant =
  <String, DfdRepository>{};

  static final Map<String, PublicacaoExtratoRepository>
  _publicacaoRepoByTenant = <String, PublicacaoExtratoRepository>{};

  static final Map<String, TrRepository> _trRepoByTenant =
  <String, TrRepository>{};

  static final Map<String, AdditivesRepository> _additivesRepoByTenant =
  <String, AdditivesRepository>{};

  static void clearCache() {
    _futureCache.clear();
    _resultCache.clear();

    _dfdRepoByTenant.clear();
    _publicacaoRepoByTenant.clear();
    _trRepoByTenant.clear();
    _additivesRepoByTenant.clear();
  }

  final GlobalKey _buttonKey = GlobalKey();

  late Future<_ValidityAlertInfo?> _future;
  late final AnimationController _positionWatcher;

  final ValueNotifier<int> _balloonTick = ValueNotifier<int>(0);

  OverlayEntry? _entry;
  Offset? _initialAnchor;

  String? _activeTenantId;
  String? _activeContractId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final permissionState = context.read<PermissionCubit>().state;

    _activeTenantId = _cleanNullableTenantId(
      permissionState.activeTenantId,
    );

    _activeContractId = _cleanNullableContractId(
      widget.contract.id,
    );

    _future = _getCachedFuture(
      contract: widget.contract,
      tenantId: _activeTenantId,
      dfdData: widget.dfdData,
      publicacaoData: widget.publicacaoData,
    );

    _positionWatcher = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_watchAnchorPosition);
  }

  @override
  void didUpdateWidget(covariant AlertValidity oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextContractId = _cleanNullableContractId(widget.contract.id);

    final dfdChanged = oldWidget.dfdData != widget.dfdData;
    final publicacaoChanged = oldWidget.publicacaoData != widget.publicacaoData;
    final contractChanged = _activeContractId != nextContractId;

    if (!contractChanged && !dfdChanged && !publicacaoChanged) {
      return;
    }

    _removeOverlay();

    _activeContractId = nextContractId;

    _future = _getCachedFuture(
      contract: widget.contract,
      tenantId: _activeTenantId,
      dfdData: widget.dfdData,
      publicacaoData: widget.publicacaoData,
      preferProvidedData: true,
    );
  }

  @override
  void dispose() {
    _removeOverlay();

    _positionWatcher.removeListener(_watchAnchorPosition);
    _positionWatcher.dispose();

    _balloonTick.dispose();

    super.dispose();
  }

  String? _cleanNullableTenantId(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (cleanTenantId == null || cleanTenantId.isEmpty) {
      return null;
    }

    return cleanTenantId;
  }

  String? _cleanNullableContractId(String? contractId) {
    final cleanContractId = contractId?.trim();

    if (cleanContractId == null || cleanContractId.isEmpty) {
      return null;
    }

    return cleanContractId;
  }

  String? _cacheKey({
    required String? tenantId,
    required String? contractId,
  }) {
    final cleanTenantId = _cleanNullableTenantId(tenantId);
    final cleanContractId = _cleanNullableContractId(contractId);

    if (cleanTenantId == null || cleanContractId == null) {
      return null;
    }

    return '$cleanTenantId::$cleanContractId';
  }

  DfdRepository _dfdRepository(String tenantId) {
    return _dfdRepoByTenant.putIfAbsent(
      tenantId,
          () => DfdRepository(
        tenantId: tenantId,
      ),
    );
  }

  PublicacaoExtratoRepository _publicacaoRepository(String tenantId) {
    return _publicacaoRepoByTenant.putIfAbsent(
      tenantId,
          () => PublicacaoExtratoRepository(
        tenantId: tenantId,
      ),
    );
  }

  TrRepository _trRepository(String tenantId) {
    return _trRepoByTenant.putIfAbsent(
      tenantId,
          () => TrRepository(
        tenantId: tenantId,
      ),
    );
  }

  AdditivesRepository _additivesRepository(String tenantId) {
    return _additivesRepoByTenant.putIfAbsent(
      tenantId,
          () => AdditivesRepository(
        tenantId: tenantId,
      ),
    );
  }

  Future<_ValidityAlertInfo?> _getCachedFuture({
    required ContractData contract,
    required String? tenantId,
    DfdData? dfdData,
    PublicacaoExtratoData? publicacaoData,
    bool preferProvidedData = false,
  }) {
    final key = _cacheKey(
      tenantId: tenantId,
      contractId: contract.id,
    );

    if (key == null) {
      return Future<_ValidityAlertInfo?>.value(null);
    }

    if (!preferProvidedData && _resultCache.containsKey(key)) {
      return Future<_ValidityAlertInfo?>.value(_resultCache[key]);
    }

    if (!preferProvidedData) {
      final cachedFuture = _futureCache[key];

      if (cachedFuture != null) {
        return cachedFuture;
      }
    }

    final future = _loadInfo(
      contract: contract,
      tenantId: tenantId,
      dfdData: dfdData,
      publicacaoData: publicacaoData,
    ).then((result) {
      _resultCache[key] = result;
      return result;
    }).catchError((error) {
      debugPrint(
        '[AlertValidity] Erro ao carregar alerta '
            'key=$key error=$error',
      );

      _futureCache.remove(key);
      return null;
    });

    _futureCache[key] = future;

    return future;
  }

  Future<DfdData?> _loadDfdStatus({
    required String tenantId,
    required String contractId,
    DfdData? provided,
  }) async {
    if (provided != null) {
      return provided;
    }

    try {
      return await _dfdRepository(tenantId).readDataForContract(contractId);
    } catch (error) {
      debugPrint(
        '[AlertValidity] Erro ao carregar DFD '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return null;
    }
  }

  Future<PublicacaoExtratoData?> _loadPublicacao({
    required String tenantId,
    required String contractId,
    PublicacaoExtratoData? provided,
  }) async {
    if (provided != null) {
      return provided;
    }

    try {
      return await _publicacaoRepository(tenantId).readDataForContract(
        contractId,
      );
    } catch (error) {
      debugPrint(
        '[AlertValidity] Erro ao carregar PublicacaoExtrato '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return null;
    }
  }

  Future<TrData?> _loadTr({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _trRepository(tenantId).readDataForContract(contractId);
    } catch (error) {
      debugPrint(
        '[AlertValidity] Erro ao carregar TR '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return null;
    }
  }

  Future<List<AdditivesData>> _loadAdditives({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _additivesRepository(tenantId).ensureForContract(contractId);
    } catch (error) {
      debugPrint(
        '[AlertValidity] Erro ao carregar aditivos '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return const <AdditivesData>[];
    }
  }

  int _toIntFromText(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return 0;

    return int.tryParse(
      text.replaceAll(RegExp(r'[^\d-]'), ''),
    ) ??
        0;
  }

  bool _isEligibleStatus(String status) {
    final cleanStatus = status.trim().toUpperCase();

    return cleanStatus == 'EM ANDAMENTO' || cleanStatus == 'A INICIAR';
  }

  Future<_ValidityAlertInfo?> _loadInfo({
    required ContractData contract,
    required String? tenantId,
    DfdData? dfdData,
    PublicacaoExtratoData? publicacaoData,
  }) async {
    final cleanContractId = _cleanNullableContractId(contract.id);
    final cleanTenantId = _cleanNullableTenantId(tenantId);

    if (cleanContractId == null || cleanTenantId == null) {
      return null;
    }

    final dfd = await _loadDfdStatus(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      provided: dfdData,
    );

    final status = (dfd?.statusDemanda ?? '').trim().toUpperCase();

    if (!_isEligibleStatus(status)) {
      return null;
    }

    final results = await Future.wait<dynamic>([
      _loadPublicacao(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
        provided: publicacaoData,
      ),
      _loadTr(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadAdditives(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
    ]);

    final publicacao = results[0] as PublicacaoExtratoData?;
    final tr = results[1] as TrData?;
    final aditivos = results[2] as List<AdditivesData>;

    final dataPublicacao = publicacao?.dataPublicacao;
    final int vigenciaDias = _toIntFromText(tr?.vigenciaDias);

    if (dataPublicacao == null) {
      return _ValidityAlertInfo(
        contractId: cleanContractId,
        tenantId: cleanTenantId,
        status: status,
        dataPublicacao: null,
        vigenciaDias: vigenciaDias,
        additiveDays: 0,
        additivesCount: 0,
        finalDate: null,
        remainingDays: null,
      );
    }

    final int diasAditivos = aditivos.fold<int>(
      0,
          (totalAtual, aditivo) {
        return totalAtual + (aditivo.additiveValidityContractDays ?? 0);
      },
    );

    final int totalDiasContrato = vigenciaDias + diasAditivos;

    final DateTime dataFinal = dataPublicacao.add(
      Duration(days: totalDiasContrato),
    );

    final DateTime today = DateTime.now();

    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final DateTime normalizedFinalDate = DateTime(
      dataFinal.year,
      dataFinal.month,
      dataFinal.day,
    );

    final int diasRestantes = normalizedFinalDate
        .difference(
      normalizedToday,
    )
        .inDays;

    return _ValidityAlertInfo(
      contractId: cleanContractId,
      tenantId: cleanTenantId,
      status: status,
      dataPublicacao: dataPublicacao,
      vigenciaDias: vigenciaDias,
      additiveDays: diasAditivos,
      additivesCount: aditivos.length,
      finalDate: dataFinal,
      remainingDays: diasRestantes,
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';

    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString().padLeft(4, '0');

    return '$d/$m/$y';
  }

  String _tooltipMessage(_ValidityAlertInfo info) {
    final dias = info.remainingDays;

    if (dias == null) {
      return 'Vigência sem data de publicação definida';
    }

    if (dias < 0) {
      return 'Contrato vencido há ${-dias} dias';
    }

    if (dias <= 60) {
      return 'Faltam $dias dias para o vencimento';
    }

    return '$dias dias para o vencimento';
  }

  IconData _iconFor(_ValidityAlertInfo info) {
    final dias = info.remainingDays;

    if (dias == null) {
      return Icons.help_outline;
    }

    if (dias < 0) {
      return Icons.warning_amber_rounded;
    }

    if (dias <= 60) {
      return Icons.access_alarm;
    }

    return Icons.notifications_none_outlined;
  }

  Color _colorFor(_ValidityAlertInfo info) {
    final dias = info.remainingDays;

    if (dias == null) {
      return Colors.blueGrey;
    }

    if (dias < 0) {
      return Colors.redAccent;
    }

    if (dias <= 60) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  List<BalloonTileData> _itemsFor(_ValidityAlertInfo info) {
    final dias = info.remainingDays;

    final String situacao;
    final Color situacaoColor;
    final IconData situacaoIcon;

    if (dias == null) {
      situacao = 'Sem data final calculada';
      situacaoColor = Colors.blueGrey;
      situacaoIcon = Icons.help_outline;
    } else if (dias < 0) {
      situacao = 'Vencido há ${-dias} dias';
      situacaoColor = Colors.redAccent;
      situacaoIcon = Icons.warning_amber_rounded;
    } else if (dias <= 60) {
      situacao = 'Faltam $dias dias';
      situacaoColor = Colors.orange;
      situacaoIcon = Icons.access_alarm;
    } else {
      situacao = '$dias dias restantes';
      situacaoColor = Colors.grey;
      situacaoIcon = Icons.notifications_none_outlined;
    }

    return [
      BalloonTileData.simple(
        id: 'situacao',
        title: situacao,
        subtitle: 'Vigência contratual',
        icon: situacaoIcon,
        accentColor: situacaoColor,
        highlighted: true,
      ),
      BalloonTileData.simple(
        id: 'status',
        title: 'Status do contrato',
        subtitle: info.status.isEmpty ? '—' : info.status,
        icon: Icons.flag_outlined,
        accentColor: const Color(0xFF1B2031),
      ),
      BalloonTileData.simple(
        id: 'publicacao',
        title: 'Data de publicação',
        subtitle: _formatDate(info.dataPublicacao),
        icon: Icons.event_available_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'vigencia_inicial',
        title: 'Vigência inicial',
        subtitle: '${info.vigenciaDias} dia(s)',
        icon: Icons.timelapse_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'aditivos',
        title: 'Aditivos de prazo',
        subtitle:
        '${info.additiveDays} dias em ${info.additivesCount} aditivo(s)',
        icon: Icons.add_alarm_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'data_final',
        title: 'Data final calculada',
        subtitle: _formatDate(info.finalDate),
        icon: Icons.event_busy_outlined,
        accentColor: situacaoColor,
      ),
    ];
  }

  void _toggleOverlay(_ValidityAlertInfo info) {
    if (_entry != null) {
      _removeOverlay();
      return;
    }

    _showOverlay(info);
  }

  Offset? _resolveButtonCenterGlobal() {
    final currentContext = _buttonKey.currentContext;

    if (currentContext == null) return null;

    final render = currentContext.findRenderObject();

    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return null;
    }

    return render.localToGlobal(
      render.size.center(Offset.zero),
    );
  }

  bool _isAnchorStillValid(Offset anchor) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;

    const estimatedUpBarHeight = 64.0;
    final minVisibleY = safeTop + estimatedUpBarHeight;

    if (anchor.dy < minVisibleY) return false;
    if (anchor.dy > size.height - 24) return false;
    if (anchor.dx < 0) return false;
    if (anchor.dx > size.width) return false;

    return true;
  }

  void _watchAnchorPosition() {
    if (_entry == null) return;
    if (!_positionWatcher.isAnimating) return;

    final currentAnchor = _resolveButtonCenterGlobal();

    if (currentAnchor == null) {
      _removeOverlay();
      return;
    }

    if (!_isAnchorStillValid(currentAnchor)) {
      _removeOverlay();
      return;
    }

    final initialAnchor = _initialAnchor;

    if (initialAnchor == null) {
      _initialAnchor = currentAnchor;
      return;
    }

    final movedDistance = (currentAnchor - initialAnchor).distance;

    if (movedDistance > 4) {
      _removeOverlay();
      return;
    }

    _balloonTick.value++;
    _entry?.markNeedsBuild();
  }

  void _startPositionWatcher() {
    if (_positionWatcher.isAnimating) return;

    _positionWatcher.repeat();
  }

  void _stopPositionWatcher() {
    if (!_positionWatcher.isAnimating) return;

    _positionWatcher.stop();
    _positionWatcher.reset();
  }

  void _showOverlay(_ValidityAlertInfo info) {
    final overlay = Overlay.of(context);
    final overlayRender = overlay.context.findRenderObject();

    if (overlayRender is! RenderBox) {
      return;
    }

    final initialAnchor = _resolveButtonCenterGlobal();

    if (initialAnchor == null) {
      return;
    }

    if (!_isAnchorStillValid(initialAnchor)) {
      return;
    }

    _initialAnchor = initialAnchor;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              overlayBox: overlayRender,
              globalAnchorBuilder: _resolveButtonCenterGlobal,
              rebuildListenable: _balloonTick,
              width: 310,
              maxHeight: 360,
              tipSide: BalloonTipSide.top,
              topGap: 4,
              title: 'Alerta de vigência',
              headerIcon: Icons.access_alarm,
              emptyMessage: 'Nenhum alerta encontrado.',
              items: _itemsFor(info),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
    _startPositionWatcher();
  }

  void _removeOverlay() {
    _stopPositionWatcher();
    _initialAnchor = null;
    _entry?.remove();
    _entry = null;
  }

  Widget _buildButton(_ValidityAlertInfo info) {
    final color = _colorFor(info);
    final icon = _iconFor(info);

    return Tooltip(
      message: _tooltipMessage(info),
      child: SizedBox.square(
        dimension: 23,
        child: IconButton(
          key: _buttonKey,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          splashRadius: 18,
          icon: Icon(
            icon,
            color: color,
            size: 21,
          ),
          onPressed: () {
            _toggleOverlay(info);
          },
        ),
      ),
    );
  }

  Widget _buildEmptySpace() {
    return const SizedBox.square(
      dimension: 23,
    );
  }

  Widget _buildLoadingShimmer() {
    return const SizedBox.square(
      dimension: 23,
      child: Center(
        child: _AlertValidityShimmer(),
      ),
    );
  }

  void _reloadForPermissionState(PermissionState permissionState) {
    final nextTenantId = _cleanNullableTenantId(permissionState.activeTenantId);

    if (_activeTenantId == nextTenantId) return;

    _removeOverlay();

    setState(() {
      _activeTenantId = nextTenantId;

      _future = _getCachedFuture(
        contract: widget.contract,
        tenantId: _activeTenantId,
        dfdData: widget.dfdData,
        publicacaoData: widget.publicacaoData,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final contractId = _cleanNullableContractId(widget.contract.id);

    if (contractId == null) {
      return _buildEmptySpace();
    }

    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        _reloadForPermissionState(permissionState);
      },
      child: FutureBuilder<_ValidityAlertInfo?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          }

          final info = snapshot.data;

          if (info == null) {
            return _buildEmptySpace();
          }

          return _buildButton(info);
        },
      ),
    );
  }
}

class _AlertValidityShimmer extends StatefulWidget {
  const _AlertValidityShimmer();

  @override
  State<_AlertValidityShimmer> createState() => _AlertValidityShimmerState();
}

class _AlertValidityShimmerState extends State<_AlertValidityShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.grey.shade300;

    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (value * 2), 0),
              end: Alignment(1.0 + (value * 2), 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.20,
                0.50,
                0.80,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_none_outlined,
          size: 15,
          color: Colors.white.withValues(alpha: 0.36),
        ),
      ),
    );
  }
}

class _ValidityAlertInfo {
  final String contractId;
  final String tenantId;
  final String status;

  final DateTime? dataPublicacao;
  final int vigenciaDias;
  final int additiveDays;
  final int additivesCount;

  final DateTime? finalDate;
  final int? remainingDays;

  const _ValidityAlertInfo({
    required this.contractId,
    required this.tenantId,
    required this.status,
    required this.dataPublicacao,
    required this.vigenciaDias,
    required this.additiveDays,
    required this.additivesCount,
    required this.finalDate,
    required this.remainingDays,
  });
}