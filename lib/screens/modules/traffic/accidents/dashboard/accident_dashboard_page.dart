import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';

import 'package:sipged/screens/modules/traffic/accidents/dashboard/accident_dashboard_map.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

import 'accident_dashboard_panel.dart';
import 'legend_item.dart';
import 'mini_legend.dart';
import 'show_city_details.dart';

class AccidentDashboardPage extends StatefulWidget {
  const AccidentDashboardPage({super.key});

  @override
  State<AccidentDashboardPage> createState() => _AccidentDashboardPageState();
}

class _AccidentDashboardPageState extends State<AccidentDashboardPage> {
  final LatLng _fallbackCenter = const LatLng(-9.6498, -35.7089);

  static const int _ufCodeAL = 27;

  static const double _mobilePanelRatio = 0.65;
  static const double _mobileBreakpoint = 980.0;

  bool _equalsNorm(String? a, String? b) {
    return (a ?? '').trim().toUpperCase() == (b ?? '').trim().toUpperCase();
  }

  List<AccidentsData> _filterByCity(
      List<AccidentsData> list,
      String city,
      ) {
    final normalizedCity = city.trim().toUpperCase();

    return list.where((item) {
      final candidate = (item.city ?? item.locality ?? '').trim().toUpperCase();

      return candidate == normalizedCity;
    }).toList();
  }

  Future<void> _openCityDetails({
    required String region,
    required List<AccidentsData> dados,
  }) async {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;

    await showWindowDialog<void>(
      context: context,
      title: 'Detalhes • $region',
      width: (size.width * 0.92).clamp(420.0, 980.0),
      barrierDismissible: true,
      usePointerInterceptor: true,
      contentPadding: EdgeInsets.zero,
      useSafeArea: true,
      child: SizedBox(
        height: (size.height * 0.78).clamp(420.0, 900.0),
        child: ShowCityDetails(
          dados: dados,
          region: region,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AccidentsCubit()..warmup(),
        ),
        BlocProvider(
          create: (_) => IBGELocationCubit(
            repository: IBGELocationRepository(),
          )..loadInitialAuto(fallbackUfCode: _ufCodeAL),
        ),
      ],
      child: Scaffold(
        appBar: UpBar(),
        body: Stack(
          children: [
            const BackgroundChange(),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final targetBottomPanelHeight = (height * _mobilePanelRatio)
                    .clamp(260.0, height * 0.90);

                final layoutKey = ValueKey(
                  'split_${width.round()}_${height.round()}_${targetBottomPanelHeight.round()}',
                );

                return BlocBuilder<AccidentsCubit, AccidentsState>(
                  builder: (context, accidentState) {
                    return BlocBuilder<IBGELocationCubit, IBGELocationState>(
                      builder: (context, geoState) {
                        final polygons = geoState.cityPolygons;

                        return SplitLayout(
                          key: layoutKey,
                          breakpoint: _mobileBreakpoint,
                          rightPanelWidth: 640,
                          bottomPanelHeight: targetBottomPanelHeight,
                          showRightPanel: true,
                          showDividers: true,
                          dividerThickness: 12,
                          dividerBackgroundColor: isDark
                              ? const Color(0xFF0B0F17)
                              : Colors.white,
                          dividerBorderColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                          gripColor: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.25),
                          stackedRightOnTop: false,
                          left: _buildLeftMap(
                            theme: theme,
                            accidentState: accidentState,
                            geoState: geoState,
                            polygons: polygons,
                          ),
                          right: const AccidentDashboardPanel(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftMap({
    required ThemeData theme,
    required AccidentsState accidentState,
    required IBGELocationState geoState,
    required List<Polygon<Map<String, dynamic>>> polygons,
  }) {
    final accidentsCubit = context.read<AccidentsCubit>();

    final selectedRegions =
    accidentState.city != null && accidentState.city!.trim().isNotEmpty
        ? <String>[accidentState.city!.trim()]
        : const <String>[];

    return Stack(
      children: [
        AccidentDashboardMap(
          center: _fallbackCenter,
          accidents: accidentState.view,
          polygonsChanged: polygons,
          selectedRegionNames: selectedRegions,
          onRegionTap: (region) async {
            final selectedRegion = (region ?? '').trim();

            if (selectedRegion.isEmpty) {
              await accidentsCubit.toggleCity(null);
              return;
            }

            final alreadySelected = _equalsNorm(
              accidentState.city,
              selectedRegion,
            );

            await accidentsCubit.toggleCity(selectedRegion);

            if (!alreadySelected) {
              final cityData = _filterByCity(
                accidentState.universe,
                selectedRegion,
              );

              await _openCityDetails(
                region: selectedRegion,
                dados: cityData,
              );
            }
          },
          onTapMarker: (accident) async {
            final city = (accident.city ?? accident.locality ?? '').trim();

            if (city.isEmpty) {
              await _openCityDetails(
                region: 'Ocorrência',
                dados: [accident],
              );
              return;
            }

            final alreadySelected = _equalsNorm(
              accidentState.city,
              city,
            );

            await accidentsCubit.toggleCity(city);

            if (!alreadySelected) {
              final cityData = _filterByCity(
                accidentState.universe,
                city,
              );

              await _openCityDetails(
                region: city,
                dados: cityData,
              );
            }
          },
        ),
        if (geoState.errorMessage != null &&
            geoState.errorMessage!.trim().isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            top: 58,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.withValues(alpha: 0.10),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                geoState.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        const Positioned(
          right: 60,
          bottom: 18,
          child: MiniLegend(
            items: [
              LegendItem(label: 'Leve', icon: Icons.circle),
              LegendItem(label: 'Moderado', icon: Icons.circle),
              LegendItem(label: 'Grave', icon: Icons.circle),
            ],
          ),
        ),
      ],
    );
  }
}