// lib/screens/modules/traffic/accidents/dashboard/accident_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

// ✅ IBGE polygons
import 'package:sipged/_blocs/system/location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';

import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';
import 'package:sipged/screens/modules/traffic/accidents/dashboard/accident_dashboard_map.dart';

// ✅ WindowDialog helper (PointerInterceptor + WindowDialog)
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

import 'accident_dashboard_panel.dart';
import 'legend_item.dart';
import 'mini_legend.dart';
import 'show_city_details.dart'; // ✅ onde está o ShowCityDetails

class AccidentDashboardPage extends StatefulWidget {
  const AccidentDashboardPage({super.key});

  @override
  State<AccidentDashboardPage> createState() => _AccidentDashboardPageState();
}

class _AccidentDashboardPageState extends State<AccidentDashboardPage> {
  final LatLng _fallbackCenter = const LatLng(-9.6498, -35.7089);
  static const int _ufCodeAL = 27;

  static const double _mobilePanelRatio = 0.65; // bottom (right)
  static const double _mobileBreakpoint = 980.0;

  bool _equalsNorm(String? a, String? b) =>
      (a ?? '').trim().toUpperCase() == (b ?? '').trim().toUpperCase();

  List<AccidentsData> _filterByCity(List<AccidentsData> list, String city) {
    final c = city.trim().toUpperCase();
    return list.where((e) {
      final candidate = (e.city ?? e.locality ?? '').trim().toUpperCase();
      return candidate == c;
    }).toList();
  }

  // ✅ Agora abre com WindowDialog (mac-style) + PointerInterceptor
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
        child: ShowCityDetails(dados: dados, region: region),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final moduleLabel = SetupData.defaultModuleLabel;
    final moduleGradient = SetupData.gradientForModule(moduleLabel);
    // ignore: unused_local_variable
    final _ = moduleGradient;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AccidentsCubit()..warmup()),
        BlocProvider(
          create: (_) => IBGELocationCubit(
            repository: IBGELocationRepository(),
          )..loadInitialAuto(fallbackUfCode: _ufCodeAL),
        ),
      ],
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: UpBar(),
        ),
        body: Stack(
          children: [
            const BackgroundChange(),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                final targetBottomPanelHeight =
                (h * _mobilePanelRatio).clamp(260.0, h * 0.90);

                final layoutKey = ValueKey(
                  'split_${w.round()}_${h.round()}_${targetBottomPanelHeight.round()}',
                );

                return BlocBuilder<AccidentsCubit, AccidentsState>(
                  builder: (context, accState) {
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
                          dividerBackgroundColor:
                          isDark ? const Color(0xFF0B0F17) : Colors.white,
                          dividerBorderColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                          gripColor: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.25),
                          stackedRightOnTop: false,
                          left: _buildLeftMap(
                            theme: theme,
                            accState: accState,
                            geoState: geoState, // ✅ novo
                            polygons: polygons,
                            isMobile: w < _mobileBreakpoint,
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
    required AccidentsState accState,
    required IBGELocationState geoState, // ✅ novo
    required List<PolygonChangedData> polygons,
    required bool isMobile,
  }) {
    final accidentsCubit = context.read<AccidentsCubit>();

    final selectedRegions =
    (accState.city != null && accState.city!.trim().isNotEmpty)
        ? <String>[accState.city!.trim()]
        : const <String>[];

    return Stack(
      children: [
        AccidentDashboardMap(
          center: _fallbackCenter,
          accidents: accState.view,
          polygonsChanged: polygons,
          selectedRegionNames: selectedRegions,
          onRegionTap: (region) async {
            final r = (region ?? '').trim();
            if (r.isEmpty) {
              await accidentsCubit.toggleCity(null);
              return;
            }

            final alreadySelected = _equalsNorm(accState.city, r);
            await accidentsCubit.toggleCity(r);

            if (!alreadySelected) {
              final dadosCidade = _filterByCity(accState.universe, r);
              await _openCityDetails(region: r, dados: dadosCidade);
            }
          },
          onTapMarker: (acc) async {
            final city = (acc.city ?? acc.locality ?? '').trim();
            if (city.isEmpty) {
              await _openCityDetails(region: 'Ocorrência', dados: [acc]);
              return;
            }

            final alreadySelected = _equalsNorm(accState.city, city);
            await accidentsCubit.toggleCity(city);

            if (!alreadySelected) {
              final dadosCidade = _filterByCity(accState.universe, city);
              await _openCityDetails(region: city, dados: dadosCidade);
            }
          },
        ),

        // ✅ DEBUG IBGE (sem acessar context)
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.90),
              border: Border.all(
                color: (theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                    .withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  geoState.isLoading ? Icons.autorenew : Icons.map_outlined,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('${geoState.cityPolygons.length} polígonos encontrados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (geoState.isLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ✅ ERRO IBGE
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
                border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
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

        // ✅ sua MiniLegend continua
        Positioned(
          right: 12,
          bottom: 12,
          child: const MiniLegend(
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
