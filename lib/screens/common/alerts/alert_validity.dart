import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class AlertValidity extends StatefulWidget {
  final ContractData contract;

  const AlertValidity({
    super.key,
    required this.contract,
  });

  @override
  State<AlertValidity> createState() => _AlertValidityState();
}

class _AlertValidityState extends State<AlertValidity>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();

  late Future<_ValidityAlertInfo?> _future;
  late final AnimationController _positionWatcher;

  final ValueNotifier<int> _balloonTick = ValueNotifier<int>(0);

  OverlayEntry? _entry;
  Offset? _initialAnchor;

  @override
  void initState() {
    super.initState();

    _future = _loadInfo(widget.contract);

    _positionWatcher = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_watchAnchorPosition);
  }

  @override
  void didUpdateWidget(covariant AlertValidity oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.contract.id != widget.contract.id) {
      _removeOverlay();
      _future = _loadInfo(widget.contract);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _positionWatcher.removeListener(_watchAnchorPosition);
    _positionWatcher.dispose();
    _balloonTick.dispose();

    super.dispose();
  }

  Future<DfdData?> _loadDfdStatus(String contractId) async {
    final repo = DfdRepository();
    return repo.readDataForContract(contractId);
  }

  Future<PublicacaoExtratoData?> _loadPublicacao(String contractId) async {
    final repo = PublicacaoExtratoRepository();
    return repo.readDataForContract(contractId);
  }

  Future<TrData?> _loadTr(String contractId) async {
    final repo = TrRepository();
    return repo.readDataForContract(contractId);
  }

  Future<List<AdditivesData>> _loadAdditives(String contractId) async {
    final additivesRepo = AdditivesRepository();
    return additivesRepo.ensureForContract(contractId);
  }

  int _toIntFromText(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return 0;

    return int.tryParse(
      text.replaceAll(RegExp(r'[^\d-]'), ''),
    ) ??
        0;
  }

  Future<_ValidityAlertInfo?> _loadInfo(ContractData contract) async {
    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      return null;
    }

    final results = await Future.wait<dynamic>([
      _loadDfdStatus(contractId),
      _loadPublicacao(contractId),
      _loadTr(contractId),
      _loadAdditives(contractId),
    ]);

    final dfdData = results[0] as DfdData?;
    final publicacao = results[1] as PublicacaoExtratoData?;
    final tr = results[2] as TrData?;
    final aditivos = results[3] as List<AdditivesData>;

    final status = (dfdData?.statusDemanda ?? '').trim().toUpperCase();

    final elegivel = status == 'EM ANDAMENTO' || status == 'A INICIAR';

    if (!elegivel) {
      return null;
    }

    final dataPublicacao = publicacao?.dataPublicacao;
    final int vigenciaDias = _toIntFromText(tr?.vigenciaDias);

    if (dataPublicacao == null) {
      return _ValidityAlertInfo(
        contractId: contractId,
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
          (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final int totalDiasContrato = vigenciaDias + diasAditivos;

    final DateTime dataFinal = dataPublicacao.add(
      Duration(days: totalDiasContrato),
    );

    final int diasRestantes = dataFinal.difference(DateTime.now()).inDays;

    return _ValidityAlertInfo(
      contractId: contractId,
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
        dimension: 34,
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

  @override
  Widget build(BuildContext context) {
    final contractId = widget.contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<_ValidityAlertInfo?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        final info = snapshot.data;

        if (info == null) {
          return const SizedBox.shrink();
        }

        return _buildButton(info);
      },
    );
  }
}

class _ValidityAlertInfo {
  final String contractId;
  final String status;

  final DateTime? dataPublicacao;
  final int vigenciaDias;
  final int additiveDays;
  final int additivesCount;

  final DateTime? finalDate;
  final int? remainingDays;

  const _ValidityAlertInfo({
    required this.contractId,
    required this.status,
    required this.dataPublicacao,
    required this.vigenciaDias,
    required this.additiveDays,
    required this.additivesCount,
    required this.finalDate,
    required this.remainingDays,
  });
}