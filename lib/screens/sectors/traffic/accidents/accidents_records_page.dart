// lib/screens/sectors/traffic/accidents/accidents_records_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/toolBox/tool_widget.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/map/map_interactive.dart';

import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';

import 'package:siged/_utils/formats/format_field.dart';
import 'package:latlong2/latlong.dart';

// SEÇÕES
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

class AccidentsRecordsPage extends StatefulWidget {
  const AccidentsRecordsPage({super.key});

  @override
  State<AccidentsRecordsPage> createState() => _AccidentsRecordsPageState();
}

class _AccidentsRecordsPageState extends State<AccidentsRecordsPage> {
  bool _inited = false;

  // ====== Form controllers (locais) ======
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final highwayCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final typeOfAccidentCtrl = TextEditingController();
  final deathCtrl = TextEditingController();
  final scoresVictimsCtrl = TextEditingController();
  final transportInvolvedCtrl = TextEditingController();

  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final city2Ctrl = TextEditingController();
  final subLocalityCtrl = TextEditingController();
  final administrativeAreaCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final isoCountryCodeCtrl = TextEditingController();

  bool formValidated = false;
  AccidentsData? selectedAccident;
  String? currentAccidentId;

  // Altura medida do formulário (desktop) para igualar o mapa dinamicamente
  double? _formHeight;
  static const double _minDeskHeight = 420;

  @override
  void initState() {
    super.initState();
    // validação simples do form
    for (final c in [cityCtrl, dateCtrl, highwayCtrl, typeOfAccidentCtrl]) {
      c.addListener(_validateForm);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;
      context.read<AccidentsBloc>().add(
        AccidentsWarmupRequested(initialYear: DateTime.now().year),
      );
      _inited = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      orderCtrl,
      dateCtrl,
      highwayCtrl,
      cityCtrl,
      typeOfAccidentCtrl,
      deathCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _validateForm() {
    final ok = cityCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty &&
        highwayCtrl.text.trim().isNotEmpty &&
        typeOfAccidentCtrl.text.trim().isNotEmpty;
    if (formValidated != ok) {
      setState(() => formValidated = ok);
    }
  }

  void _fillFields(AccidentsData data) {
    selectedAccident = data;
    currentAccidentId = data.id;

    cityCtrl.text = data.city ?? '';
    dateCtrl.text = data.date != null ? dateToString(data.date!) : '';
    deathCtrl.text = (data.death ?? 0).toString();
    highwayCtrl.text = data.highway ?? '';
    scoresVictimsCtrl.text = (data.scoresVictims ?? 0).toString();
    transportInvolvedCtrl.text = data.transportInvolved ?? '';
    typeOfAccidentCtrl.text = data.typeOfAccident ?? '';

    latitudeCtrl.text = data.latLng?.latitude.toString() ?? '';
    longitudeCtrl.text = data.latLng?.longitude.toString() ?? '';
    postalCodeCtrl.text = data.postalCode ?? '';
    streetCtrl.text = data.street ?? '';
    city2Ctrl.text = data.city ?? '';
    subLocalityCtrl.text = data.subLocality ?? '';
    administrativeAreaCtrl.text = data.administrativeArea ?? '';
    countryCtrl.text = data.country ?? '';
    isoCountryCodeCtrl.text = data.isoCountryCode ?? '';

    orderCtrl.text = (data.order ?? '').toString();

    _validateForm();
  }

  Future<void> _createNew(AccidentsState st) async {
    selectedAccident = null;
    currentAccidentId = null;

    // calcula próximo "order" com base na lista da página (ou view)
    final nextOrder = ((st.view.map((e) => e.order ?? 0).fold<int>(0, (a, b) => a > b ? a : b)) + 1);
    orderCtrl.text = nextOrder.toString();

    for (final c in [
      dateCtrl,
      deathCtrl,
      highwayCtrl,
      scoresVictimsCtrl,
      transportInvolvedCtrl,
      typeOfAccidentCtrl,
      latitudeCtrl,
      longitudeCtrl,
      postalCodeCtrl,
      streetCtrl,
      cityCtrl,
      city2Ctrl,
      subLocalityCtrl,
      administrativeAreaCtrl,
      countryCtrl,
      isoCountryCodeCtrl,
    ]) {
      c.clear();
    }
    dateCtrl.text = dateToString(DateTime.now());
    _validateForm();
    setState(() {});
  }

  Future<void> _save(AccidentsState st) async {
    final data = AccidentsData(
      id: currentAccidentId,
      date: stringToDate(dateCtrl.text),
      death: int.tryParse(deathCtrl.text),
      highway: highwayCtrl.text,
      scoresVictims: int.tryParse(scoresVictimsCtrl.text),
      transportInvolved: transportInvolvedCtrl.text,
      typeOfAccident: typeOfAccidentCtrl.text,
      latLng: LatLng(
        double.tryParse(latitudeCtrl.text) ?? 0,
        double.tryParse(longitudeCtrl.text) ?? 0,
      ),
      postalCode: postalCodeCtrl.text,
      street: streetCtrl.text,
      city: city2Ctrl.text.isNotEmpty ? city2Ctrl.text : cityCtrl.text,
      subLocality: subLocalityCtrl.text,
      administrativeArea: administrativeAreaCtrl.text,
      country: countryCtrl.text,
      isoCountryCode: isoCountryCodeCtrl.text,
      order: int.tryParse(orderCtrl.text),
    );

    context.read<AccidentsBloc>().add(AccidentsSaveRequested(data));
  }

  Future<void> _delete(String id, {int? yearHint}) async {
    context.read<AccidentsBloc>().add(
      AccidentsDeleteRequested(id: id, yearHint: yearHint),
    );
  }

  Future<bool> _confirm(BuildContext ctx, String msg) async {
    return await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccidentsBloc, AccidentsState>(
      listenWhen: (prev, curr) =>
      prev.error != curr.error || prev.success != curr.success,
      listener: (context, state) async {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }
        if (state.success != null && state.success!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.success!), backgroundColor: Colors.green),
          );
          // após salvar/apagar, “novo” limpo
          await _createNew(state);
        }
      },
      builder: (context, state) {
        final isSaving = state.saving;
        final pageItems = state.pageItems;
        final isSmall = MediaQuery.of(context).size.width <= 900;

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
                                final double leftWidth  = isSmall ? maxW : (maxW - 12) / 2;
                                final double rightWidth = isSmall ? maxW : (maxW - 12) / 2;

                                if (isSmall) {
                                  // ===== MOBILE =====
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      AccidentsFormSection(
                                        itemsPerLineOverride: 1,
                                        isEditable: true, // controle de permissão pode vir do seu UserBloc
                                        formValidated: formValidated,
                                        currentAccidentId: currentAccidentId,
                                        orderCtrl: orderCtrl,
                                        dateCtrl: dateCtrl,
                                        highwayCtrl: highwayCtrl,
                                        cityCtrl: cityCtrl,
                                        typeOfAccidentCtrl: typeOfAccidentCtrl,
                                        deathCtrl: deathCtrl,
                                        scoresVictimsCtrl: scoresVictimsCtrl,
                                        transportInvolvedCtrl: transportInvolvedCtrl,
                                        latitudeCtrl: latitudeCtrl,
                                        longitudeCtrl: longitudeCtrl,
                                        postalCodeCtrl: postalCodeCtrl,
                                        streetCtrl: streetCtrl,
                                        city2Ctrl: city2Ctrl,
                                        subLocalityCtrl: subLocalityCtrl,
                                        administrativeAreaCtrl: administrativeAreaCtrl,
                                        countryCtrl: countryCtrl,
                                        isoCountryCodeCtrl: isoCountryCodeCtrl,
                                        onSave: () async {
                                          final ok = await _confirm(context, 'Deseja salvar este acidente?');
                                          if (ok) await _save(state);
                                        },
                                        onClear: () => _createNew(state),
                                        onGetLocation: () async {
                                          // Se você usa SystemBloc, pode trazer coordenadas e preencher aqui
                                          // Exemplo (adapte ao seu projeto):
                                          // final sys = context.read<SystemBloc>();
                                          // final coords = await sys.getUserCurrentLocation();
                                          // if (coords != null) {
                                          //   latitudeCtrl.text  = coords.latitude.toStringAsFixed(6);
                                          //   longitudeCtrl.text = coords.longitude.toStringAsFixed(6);
                                          // }
                                        },
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
                                            overlayBuilder: (mapController, _) => ToolBoxWidget(
                                              mapController: mapController,
                                              onStrokesChanged: (_) { },
                                              onExportPng: (_) async { },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // ===== DESKTOP =====
                                double mapH = _formHeight ?? _minDeskHeight;

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
                                            isEditable: true,
                                            formValidated: formValidated,
                                            currentAccidentId: currentAccidentId,
                                            orderCtrl: orderCtrl,
                                            dateCtrl: dateCtrl,
                                            highwayCtrl: highwayCtrl,
                                            cityCtrl: cityCtrl,
                                            typeOfAccidentCtrl: typeOfAccidentCtrl,
                                            deathCtrl: deathCtrl,
                                            scoresVictimsCtrl: scoresVictimsCtrl,
                                            transportInvolvedCtrl: transportInvolvedCtrl,
                                            latitudeCtrl: latitudeCtrl,
                                            longitudeCtrl: longitudeCtrl,
                                            postalCodeCtrl: postalCodeCtrl,
                                            streetCtrl: streetCtrl,
                                            city2Ctrl: city2Ctrl,
                                            subLocalityCtrl: subLocalityCtrl,
                                            administrativeAreaCtrl: administrativeAreaCtrl,
                                            countryCtrl: countryCtrl,
                                            isoCountryCodeCtrl: isoCountryCodeCtrl,
                                            onSave: () async {
                                              final ok = await _confirm(context, 'Deseja salvar este acidente?');
                                              if (ok) await _save(state);
                                            },
                                            onClear: () => _createNew(state),
                                            onGetLocation: () async {/* idem ao mobile */},
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
                                        overlayBuilder: (mapController, _) => ToolBoxWidget(
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
                              allAccidents: state.universe, // usa o universo atual
                              initialYear: state.year,
                              initialMonth: state.month,
                              onSelectionChanged: (res) async {
                                final y = res.selectedYear, m = res.selectedMonth;
                                if (y == state.year && m == state.month) return;
                                context.read<AccidentsBloc>().add(
                                  AccidentsFilterChanged(year: y, month: m),
                                );
                              },
                            ),
                          ),

                          // ======= TABELA =======
                          if (pageItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nenhum acidente encontrado'),
                            )
                          else ...[
                            const DividerText(title: 'Acidentes cadastrados no sistema'),
                            AccidentsTableSection(
                              listData: pageItems,
                              selectedItem: selectedAccident,
                              currentPage: state.currentPage,
                              totalPages: state.totalPages,
                              onPageChange: (p) async => context.read<AccidentsBloc>().add(AccidentsPageRequested(p)),
                              onTapItem: (item) {
                                final idx = pageItems.indexOf(item);
                                if (idx != -1) {
                                  _fillFields(item);
                                  setState(() {});
                                }
                              },
                              onDelete: (id) async {
                                final toDelete = state.view.firstWhere(
                                      (e) => e.id == id,
                                  orElse: () => AccidentsData(id: id),
                                );
                                final ok = await _confirm(context, 'Deseja apagar este acidente?');
                                if (ok) await _delete(id, yearHint: toDelete.date?.year);
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
              if (isSaving)
                Stack(
                  children: [
                    ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget auxiliar para medir o tamanho do filho após o layout
class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.child, required this.onSize});
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
