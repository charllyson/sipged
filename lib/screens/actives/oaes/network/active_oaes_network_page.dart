import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

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

  _RightPanelMode _mode = _RightPanelMode.none;
  TaggedChangedMarker<ActiveOaesData>? _detailsMarker;

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

  void _toggleAnalyticsPanel() {
    setState(() {
      if (_mode == _RightPanelMode.analytics) {
        _mode = _RightPanelMode.none;
      } else {
        _mode = _RightPanelMode.analytics;
        _detailsMarker = null; // fecha detalhes se estiver aberto
      }
    });
  }

  void _openDetails(TaggedChangedMarker<ActiveOaesData> marker) {
    setState(() {
      _mode = _RightPanelMode.details;
      _detailsMarker = marker;
    });
  }

  void _closePanel() {
    setState(() {
      _mode = _RightPanelMode.none;
      _detailsMarker = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showRightPanel = _mode != _RightPanelMode.none;

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
                tooltip: showRightPanel ? 'Ocultar painel' : 'Mostrar painel (métricas)',
                icon: Icon(
                  showRightPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                  color: Colors.white,
                ),
                onPressed: _toggleAnalyticsPanel,
              ),
            ],
          ),
        ),

        bottomNavigationBar: const FootBar(),

        body: BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;

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
                    }
                    break;
                }

                if (isWide) {
                  // side-by-side
                  return Row(
                    children: [
                      Expanded(
                        child: ActiveOaesMap(
                          state: state,
                          onOpenDetails: _openDetails, // <<< vem do Map
                        ),
                      ),
                      if (rightPane != null) ...[
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 560, // ajuste conforme seu layout
                          child: rightPane,
                        ),
                      ],
                    ],
                  );
                } else {
                  // stacked (mobile/tablet)
                  return Column(
                    children: [
                      Expanded(
                        child: ActiveOaesMap(
                          state: state,
                          onOpenDetails: _openDetails,
                        ),
                      ),
                      if (rightPane != null) ...[
                        const Divider(height: 1),
                        SizedBox(
                          height: 460,
                          child: rightPane,
                        ),
                      ],
                    ],
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
