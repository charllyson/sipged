import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'active_oaes_map.dart';
import 'active_oaes_panel.dart';
import 'active_oaes_details.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import '../../../../_blocs/actives/oaes/active_oaes_data.dart';

enum _RightPanelMode { none, analytics, details }

class ActiveOAEsNetworkPage extends StatefulWidget {
  const ActiveOAEsNetworkPage({super.key});

  @override
  State<ActiveOAEsNetworkPage> createState() => _ActiveOAEsNetworkPageState();
}

class _ActiveOAEsNetworkPageState extends State<ActiveOAEsNetworkPage> {
  late final ActiveOaesBloc _bloc;

  // 👉 Painel à direita/abaixo: inicia ATIVO em "analytics"
  _RightPanelMode _mode = _RightPanelMode.analytics;
  bool _showPanel = true;

  // 👉 Marker selecionado (detalhes)
  TaggedChangedMarker<ActiveOaesData>? _detailsMarker;

  // 👉 Split (tablet/mobile): fração da ALTURA alocada ao MAPA (resto é painel)
  double _splitVSmall = 0.5; // 50% mapa / 50% painel por padrão

  @override
  void initState() {
    super.initState();
    _bloc = ActiveOaesBloc()..add(const ActiveOaesWarmupRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearFilters() {
    _bloc.add(const ActiveOaesPieFilterChanged(null));
    _bloc.add(const ActiveOaesRegionFilterChanged(null));
  }

  void _togglePanelVisibility() {
    setState(() => _showPanel = !_showPanel);
  }

  void _openDetails(TaggedChangedMarker<ActiveOaesData> marker) {
    setState(() {
      _mode = _RightPanelMode.details;
      _detailsMarker = marker;
      _showPanel = true; // garantir que o painel abra
    });
  }

  void _openAnalytics() {
    setState(() {
      _mode = _RightPanelMode.analytics;
      _showPanel = true;
      _detailsMarker = null;
    });
  }

  void _closePanel() {
    setState(() {
      _showPanel = false;
      _mode = _RightPanelMode.analytics; // volta para analytics ao reabrir
      _detailsMarker = null;
    });
  }

  // ----- divisor arrastável (mobile/tablet) -----
  Widget _buildDraggableHorizontalDivider(double totalH) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) {
          final delta = details.delta.dy;
          setState(() {
            final currentMapH = _splitVSmall * totalH;
            final newMapH = (currentMapH + delta).clamp(220.0, totalH * 0.9);
            _splitVSmall = (newMapH / totalH).clamp(0.2, 0.9);
          });
        },
        child: Container(
          height: 10,
          color: Colors.white,
          child: Center(
            child: Container(width: double.infinity, height: 1, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: UpBar(
            showPhotoMenu: true,
            actions: [
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                onPressed: _clearFilters,
              ),
              IconButton(
                tooltip: _showPanel ? 'Ocultar painel' : 'Mostrar painel',
                icon: Icon(
                  _showPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _togglePanelVisibility,
              ),
            ],
          ),
        ),
        body: BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;

                // ==== painel de conteúdo (analytics/details) ====
                Widget? rightPane;
                switch (_mode) {
                  case _RightPanelMode.none:
                    rightPane = null;
                    break;
                  case _RightPanelMode.analytics:
                    rightPane = ActiveOaesPanel(onClose: _closePanel);
                    break;
                  case _RightPanelMode.details:
                    final marker = _detailsMarker;
                    if (marker != null) {
                      rightPane = ActiveOaesDetails(
                        marker: marker,
                        onClose: _closePanel,
                      );
                    } else {
                      rightPane = ActiveOaesPanel(onClose: _closePanel);
                    }
                    break;
                }

                if (isWide) {
                  // ===== WIDE: lado a lado (mapa | painel), ambos ativos inicialmente =====
                  return Row(
                    children: [
                      Expanded(
                        child: ActiveOaesMap(
                          state: state,
                          onOpenDetails: _openDetails,
                        ),
                      ),
                      if (_showPanel && rightPane != null) ...[
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 560,
                          child: rightPane,
                        ),
                      ],
                    ],
                  );
                }

                // ===== MOBILE/TABLET: split vertical (mapa em cima, painel embaixo) =====
                final double totalH = constraints.maxHeight;
                const double minMapH = 220.0;
                final double maxMapH = (totalH * 0.9).clamp(minMapH, totalH);
                double mapH = (_splitVSmall * totalH).clamp(minMapH, maxMapH);

                // painel de baixo
                final Widget bottomPanel = !_showPanel || rightPane == null
                    ? const SizedBox.shrink()
                    : rightPane;

                return Column(
                  children: [
                    // Mapa (topo)
                    SizedBox(
                      width: double.infinity,
                      height: mapH,
                      child: ActiveOaesMap(
                        state: state,
                        onOpenDetails: _openDetails,
                      ),
                    ),
                    // Divisor arrastável
                    _buildDraggableHorizontalDivider(totalH),
                    // Painel (base)
                    Expanded(child: bottomPanel),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
