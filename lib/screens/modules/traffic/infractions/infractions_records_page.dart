// lib/screens/modules/transit/infractions/infractions_records_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

import 'package:sipged/_blocs/modules/transit/infractions/infractions_cubit.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_repository.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_state.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'infractions_form_section.dart';
import 'infractions_selector_dates_section.dart';
import 'infractions_table_section.dart';

class InfractionsRecordsPage extends StatefulWidget {
  const InfractionsRecordsPage({super.key});

  @override
  State<InfractionsRecordsPage> createState() =>
      _InfractionsRecordsPageState();
}

class _InfractionsRecordsPageState extends State<InfractionsRecordsPage> {
  late final InfractionsCubit _cubit;

  double? _formHeight;

  static const double _minDeskHeight = 420;

  @override
  void initState() {
    super.initState();

    _cubit = InfractionsCubit(
      repository: InfractionsRepository(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.postFrameInit();
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _handleSave(InfractionsCubit cubit) async {
    final bool ok = await confirmDialog(
      context,
      'Deseja salvar esta infração?',
    );

    if (!mounted || !ok) return;

    await cubit.saveOrUpdate();
  }

  Future<void> _handleDelete(
      InfractionsCubit cubit,
      String id,
      ) async {
    final bool ok = await confirmDialog(
      context,
      'Deseja apagar esta infração?',
    );

    if (!mounted || !ok) return;

    await cubit.deleteInfraction(id);
  }

  Future<void> _handleApplyDateFilter(
      InfractionsCubit cubit, {
        required int? year,
        required int? month,
      }) async {
    await cubit.applyDateFilter(
      year: year,
      month: month,
      resetToFirstPage: true,
      source: 'selector',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InfractionsCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundChange(),
            Column(
              children: [
                Expanded(
                  child: BlocBuilder<InfractionsCubit, InfractionsState>(
                    builder: (context, state) {
                      final cubit = context.read<InfractionsCubit>();

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UpBar(),
                            const SectionTitle(
                              text: 'Cadastrar infrações de trânsito no sistema',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9.0,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double maxW = constraints.maxWidth;
                                  final bool isSmall = maxW <= 900;

                                  final double leftWidth =
                                  isSmall ? maxW : (maxW - 12) / 2;

                                  final double rightWidth =
                                  isSmall ? maxW : (maxW - 12) / 2;

                                  if (isSmall) {
                                    return Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                      children: [
                                        InfractionsFormSection(
                                          itemsPerLineOverride: 1,
                                          isEditable: state.isEditable,
                                          formValidated: state.formValidated,
                                          currentInfractionId:
                                          state.currentInfractionId,
                                          orderCtrl: cubit.orderCtrl,
                                          aitNumberCtrl: cubit.aitNumberCtrl,
                                          dateCtrl: cubit.dateCtrl,
                                          timeCtrl: cubit.timeCtrl,
                                          codeCtrl: cubit.codeCtrl,
                                          descriptionCtrl:
                                          cubit.descriptionCtrl,
                                          organCodeCtrl: cubit.organCodeCtrl,
                                          organAuthorityCtrl:
                                          cubit.organAuthorityCtrl,
                                          addressCtrl: cubit.addressCtrl,
                                          bairroCtrl: cubit.bairroCtrl,
                                          latitudeCtrl: cubit.latitudeCtrl,
                                          longitudeCtrl: cubit.longitudeCtrl,
                                          onSave: () => _handleSave(cubit),
                                          onClear: cubit.createNew,
                                          onGetLocation:
                                          cubit.fillFromUserLocation,
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 380,
                                          child: Card(
                                            elevation: 6,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(16),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child:
                                            const _InfractionsMapPreview(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  final double mapH =
                                      _formHeight ?? _minDeskHeight;

                                  return Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: leftWidth,
                                        child: _SizeReporter(
                                          onSize: (size) {
                                            final double height = size.height;

                                            if (_formHeight != height &&
                                                mounted) {
                                              setState(() {
                                                _formHeight = height;
                                              });
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            child: InfractionsFormSection(
                                              itemsPerLineOverride: 2,
                                              isEditable: state.isEditable,
                                              formValidated:
                                              state.formValidated,
                                              currentInfractionId:
                                              state.currentInfractionId,
                                              orderCtrl: cubit.orderCtrl,
                                              aitNumberCtrl:
                                              cubit.aitNumberCtrl,
                                              dateCtrl: cubit.dateCtrl,
                                              timeCtrl: cubit.timeCtrl,
                                              codeCtrl: cubit.codeCtrl,
                                              descriptionCtrl:
                                              cubit.descriptionCtrl,
                                              organCodeCtrl:
                                              cubit.organCodeCtrl,
                                              organAuthorityCtrl:
                                              cubit.organAuthorityCtrl,
                                              addressCtrl: cubit.addressCtrl,
                                              bairroCtrl: cubit.bairroCtrl,
                                              latitudeCtrl:
                                              cubit.latitudeCtrl,
                                              longitudeCtrl:
                                              cubit.longitudeCtrl,
                                              onSave: () =>
                                                  _handleSave(cubit),
                                              onClear: cubit.createNew,
                                              onGetLocation:
                                              cubit.fillFromUserLocation,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: rightWidth,
                                        height: mapH < _minDeskHeight
                                            ? _minDeskHeight
                                            : mapH,
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child:
                                          const _InfractionsMapPreview(),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SectionTitle(
                              text: 'Filtrar por data infrações de trânsito',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: InfractionsSelectorDatesSection(
                                allInfractions: state.selectorUniverseAll,
                                initialYear: state.selectedYear,
                                initialMonth: state.selectedMonth,
                                onSelectionChanged: (res) async {
                                  final int? year = res.selectedYear;
                                  final int? month = res.selectedMonth;

                                  if (year == state.selectedYear &&
                                      month == state.selectedMonth) {
                                    return;
                                  }

                                  await _handleApplyDateFilter(
                                    cubit,
                                    year: year,
                                    month: month,
                                  );
                                },
                              ),
                            ),
                            if (state.pageItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Nenhuma infração encontrada'),
                              )
                            else ...[
                              const SectionTitle(
                                text: 'Infrações cadastradas no sistema',
                              ),
                              InfractionsTableSection(
                                listData: state.pageItems,
                                selectedItem: state.selectedInfraction,
                                onTapItem: (item) {
                                  cubit.selectFromTable(item);
                                },
                                onDelete: (id) {
                                  _handleDelete(cubit, id);
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const FootBar(),
              ],
            ),
            BlocBuilder<InfractionsCubit, InfractionsState>(
              buildWhen: (previous, current) {
                return previous.isSaving != current.isSaving ||
                    previous.loading != current.loading;
              },
              builder: (context, state) {
                if (!state.isSaving && !state.loading) {
                  return const SizedBox.shrink();
                }

                return Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const Center(
                      child: LoadingTreeDots(size: 120),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfractionsMapPreview extends StatelessWidget {
  const _InfractionsMapPreview();

  @override
  Widget build(BuildContext context) {
    return MapChange(
      key: const ValueKey('infractions-map-preview'),
      features: const <FeatureData>[],
      layersById: const <String, LayerData>{},
      orderedActiveLayerIds: const <String>[],
      selectedFeatureKey: null,
      loading: false,
      visualDataSignature: 'infractions-map-preview',
      initialCenter: const LatLng(-9.6658, -35.7353),
      initialZoom: 9,
      minZoom: 4,
      maxZoom: 19,
      showSearch: false,
      showControls: true,
      onControllerReady: (_) {},
      onCameraChanged: (_, _) {},
      onFeatureTap: (_) {},
    );
  }
}

class _SizeReporter extends StatefulWidget {
  const _SizeReporter({
    required this.child,
    required this.onSize,
  });

  final Widget child;
  final ValueChanged<Size> onSize;

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  Size? _old;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final Size? size = context.size;

      if (size != null && size != _old) {
        _old = size;
        widget.onSize(size);
      }
    });

    return widget.child;
  }
}