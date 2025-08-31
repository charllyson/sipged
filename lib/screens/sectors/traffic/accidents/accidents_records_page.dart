// lib/screens/sectors/traffic/accidents/accidents_records_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_controller.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/map/map_interactive.dart';

// SEÇÕES
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

// OVERLAY MODULAR (toolbox vertical integrada)
import 'package:siged/_widgets/paint/paint_overlay.dart';

class AccidentsRecordsPage extends StatefulWidget {
  const AccidentsRecordsPage({super.key});

  @override
  State<AccidentsRecordsPage> createState() => _AccidentsRecordsPageState();
}

class _AccidentsRecordsPageState extends State<AccidentsRecordsPage> {
  bool _inited = false;

  // Altura medida do formulário (desktop) para igualar o mapa dinamicamente
  double? _formHeight;
  static const double _minDeskHeight = 420; // altura mínima do mapa no desktop
  // static const double _maxDeskHeight = 900; // (opcional) teto

  @override
  void initState() {
    super.initState();
    // Se já chamou no MenuListPage, isto é redundante e inofensivo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;
      context.read<AccidentsController>().postFrameInit(context);
      _inited = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AccidentsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundClean(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UpBar(),
                      const SizedBox(height: 12),
                      const DividerText(title: 'Cadastrar acidentes'),

                      // ======= FORM + MAPA com largura responsiva =======
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final isSmall = maxW <= 900;

                            final double leftWidth  = isSmall ? maxW : (maxW - 12) / 2;
                            final double rightWidth = isSmall ? maxW : (maxW - 12) / 2;

                            if (isSmall) {
                              // ===== MOBILE =====
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AccidentsFormSection(
                                    itemsPerLineOverride: 1,
                                    isEditable: ctrl.isEditable,
                                    formValidated: ctrl.formValidated,
                                    currentAccidentId: ctrl.currentAccidentId,
                                    orderCtrl: ctrl.orderCtrl,
                                    dateCtrl: ctrl.dateCtrl,
                                    highwayCtrl: ctrl.highwayCtrl,
                                    cityCtrl: ctrl.cityCtrl,
                                    typeOfAccidentCtrl: ctrl.typeOfAccidentCtrl,
                                    deathCtrl: ctrl.deathCtrl,
                                    scoresVictimsCtrl: ctrl.scoresVictimsCtrl,
                                    transportInvolvedCtrl: ctrl.transportInvolvedCtrl,
                                    latitudeCtrl: ctrl.latitudeCtrl,
                                    longitudeCtrl: ctrl.longitudeCtrl,
                                    postalCodeCtrl: ctrl.postalCodeCtrl,
                                    streetCtrl: ctrl.streetCtrl,
                                    city2Ctrl: ctrl.city2Ctrl,
                                    subLocalityCtrl: ctrl.subLocalityCtrl,
                                    administrativeAreaCtrl: ctrl.administrativeAreaCtrl,
                                    countryCtrl: ctrl.countryCtrl,
                                    isoCountryCodeCtrl: ctrl.isoCountryCodeCtrl,
                                    onSave: () async {
                                      final ok = await ctrl.confirm(context, 'Deseja salvar este acidente?');
                                      if (ok) await ctrl.saveOrUpdate(context);
                                    },
                                    onClear: ctrl.createNew,
                                    onGetLocation: () => ctrl.fillFromUserLocation(context),
                                  ),
                                  const SizedBox(height: 12),

                                  // Mapa com altura fixa confortável no mobile
                                  SizedBox(
                                    width: double.infinity,
                                    height: 380,
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: MapInteractivePage(
                                        initialZoom: 9,
                                        activeMap: true,
                                        showLegend: true,
                                        overlayBuilder: (mapController, _) => PaintOverlay(
                                          mapController: mapController,
                                          onStrokesChanged: (_) {},
                                          onExportPng: (_) async {},
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            // ===== DESKTOP =====
                            double mapH = _formHeight ?? _minDeskHeight;
                            // mapH = mapH.clamp(_minDeskHeight, _maxDeskHeight); // (opcional)

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // COLUNA ESQUERDA: FORM (altura natural)
                                SizedBox(
                                  width: leftWidth,
                                  child: _SizeReporter(
                                    onSize: (size) {
                                      final h = size.height;
                                      if (_formHeight != h) {
                                        setState(() => _formHeight = h);
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AccidentsFormSection(
                                        itemsPerLineOverride: 2,
                                        isEditable: ctrl.isEditable,
                                        formValidated: ctrl.formValidated,
                                        currentAccidentId: ctrl.currentAccidentId,
                                        orderCtrl: ctrl.orderCtrl,
                                        dateCtrl: ctrl.dateCtrl,
                                        highwayCtrl: ctrl.highwayCtrl,
                                        cityCtrl: ctrl.cityCtrl,
                                        typeOfAccidentCtrl: ctrl.typeOfAccidentCtrl,
                                        deathCtrl: ctrl.deathCtrl,
                                        scoresVictimsCtrl: ctrl.scoresVictimsCtrl,
                                        transportInvolvedCtrl: ctrl.transportInvolvedCtrl,
                                        latitudeCtrl: ctrl.latitudeCtrl,
                                        longitudeCtrl: ctrl.longitudeCtrl,
                                        postalCodeCtrl: ctrl.postalCodeCtrl,
                                        streetCtrl: ctrl.streetCtrl,
                                        city2Ctrl: ctrl.city2Ctrl,
                                        subLocalityCtrl: ctrl.subLocalityCtrl,
                                        administrativeAreaCtrl: ctrl.administrativeAreaCtrl,
                                        countryCtrl: ctrl.countryCtrl,
                                        isoCountryCodeCtrl: ctrl.isoCountryCodeCtrl,
                                        onSave: () async {
                                          final ok = await ctrl.confirm(context, 'Deseja salvar este acidente?');
                                          if (ok) await ctrl.saveOrUpdate(context);
                                        },
                                        onClear: ctrl.createNew,
                                        onGetLocation: () => ctrl.fillFromUserLocation(context),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // COLUNA DIREITA: MAPA (segue altura do form, com mínimo)
                                SizedBox(
                                  width: rightWidth,
                                  height: mapH < _minDeskHeight ? _minDeskHeight : mapH,
                                  child: MapInteractivePage(
                                    initialZoom: 9,
                                    activeMap: true,
                                    showLegend: true,
                                    overlayBuilder: (mapController, _) => PaintOverlay(
                                      mapController: mapController,
                                      onStrokesChanged: (_) {},
                                      onExportPng: (_) async {},
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const DividerText(title: 'Filtrar por datas'),

                      // ======= SELECTOR DE DATAS =======
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: AccidentsSelectorDatesSection(
                          allAccidents: ctrl.selectorUniverse,
                          initialYear: ctrl.yearFilter,
                          initialMonth: ctrl.monthFilter,
                          onSelectionChanged: (res) async {
                            final y = res.selectedYear, m = res.selectedMonth;
                            if (y == ctrl.yearFilter && m == ctrl.monthFilter) return;
                            await ctrl.onSelectorChanged(year: y, month: m);
                          },
                        ),
                      ),

                      // ======= TABELA =======
                      if (ctrl.pageItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhum acidente encontrado'),
                        )
                      else ...[
                        const DividerText(title: 'Acidentes cadastrados no sistema'),
                        AccidentsTableSection(
                          listData: ctrl.pageItems,
                          selectedItem: ctrl.selectedAccident,
                          currentPage: ctrl.currentPage,
                          totalPages: ctrl.totalPages,
                          onPageChange: ctrl.loadPage,
                          onTapItem: (item) {
                            final idx = ctrl.pageItems.indexOf(item);
                            if (idx != -1) ctrl.selectFromTable(item, idx);
                          },
                          onDelete: (id) async {
                            final ok = await ctrl.confirm(context, 'Deseja apagar este acidente?');
                            if (ok) await ctrl.deleteAccident(context, id);
                          },
                        ),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const FootBar(),
            ],
          ),

          // Overlay de "salvando..."
          if (ctrl.isSaving)
            Stack(
              children: [
                ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
        ],
      ),
    );
  }
}

/// Widget auxiliar para medir o tamanho do filho após o layout
class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.child, required this.onSize, super.key});
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
      final s = context.size;
      if (s != null && s != _old) {
        _old = s;
        widget.onSize(s);
      }
    });
    return widget.child;
  }
}
