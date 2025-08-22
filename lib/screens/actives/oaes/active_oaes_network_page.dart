import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_datas/actives/oaes/active_oaes_data.dart';
import 'package:sisged/_datas/actives/oaes/active_oaes_store.dart'; // ⬅️ store
import 'package:sisged/_datas/actives/oaes/active_oaes_style.dart';
import 'package:sisged/_widgets/map/markers/animated_cluster_marker_widget.dart';
import 'package:sisged/_widgets/map/map_interactive.dart';
import 'package:sisged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';

import 'active_oaes_controller.dart';

class ActiveOAEsNetworkPage extends StatefulWidget {
  final List<String>? selectedRegionNames;
  final void Function(String?)? onRegionTap;
  final double? height;

  const ActiveOAEsNetworkPage({
    super.key,
    this.selectedRegionNames,
    this.onRegionTap,
    this.height = 320,
  });

  @override
  State<ActiveOAEsNetworkPage> createState() => _ActiveOAEsNetworkPageState();
}

class _ActiveOAEsNetworkPageState extends State<ActiveOAEsNetworkPage> {
  bool _didInit = false; // evita init repetido

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActiveOaesController>(
      create: (ctx) => ActiveOaesController(
        store: ctx.read<ActiveOaesStore>(), // ✅ apenas o store (sem UserBloc)
        currentUser: context.read<UserProvider>().userData!, // ✅ apenas o Store (sem UserBloc)
      ),
      builder: (context, _) {
        final ctrl = context.watch<ActiveOaesController>();

        if (!_didInit) {
          _didInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final user = context.read<UserProvider>().userData;
            if (user != null) {
              await context.read<ActiveOaesController>().init(user);
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Column(
                  children: [
                    const UpBar(),
                    Expanded(
                      child: ctrl.loading
                          ? const MapLoadingShimmer()
                          : MapInteractivePage<ActiveOaesData>(
                        taggedMarkers: ctrl.markers,
                        clusterWidgetBuilder: (markers, selected, onSelect) {
                          return AnimatedClusterMarkerLayer<ActiveOaesData>(
                            taggedMarkers: markers,
                            selectedMarkerPosition: selected,
                            onMarkerSelected: onSelect,
                            markerBuilder: (context, tagged) {
                              final nota = tagged.data.score?.toDouble() ?? 0;
                              final order = tagged.data.order?.toString() ?? '';
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: OaesDataStyle.getColorByNota(nota),
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  order,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                            titleBuilder: (data) => data.identificationName ?? 'Sem nome',
                            subTitleBuilder: (data) => data.state ?? 'Não identificado',
                          );
                        },
                      ),
                    ),
                    const FootBar(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
